# frozen_string_literal: true

require_relative "base"
require "listen"
require "rack"
require "thread"
require "rbconfig"

module RubyWasmUi
  module Cli
    class Command
      class Dev < Base
        def self.description
          "Start development server with file watching and auto-build"
        end

        def run(_argv)
          log_info("Starting development server...")
          puts ""

          ensure_src_directory

          # Initial build
          log_info("Performing initial build...")
          build
          log_success("✓ Initial build completed")
          puts ""

          # Start file watcher in a separate thread
          @build_lock = Mutex.new
          @build_queue = Queue.new
          @listener = nil
          @watcher_thread = nil

          @watcher_thread = Thread.new do
            start_file_watcher
          end

          # Register cleanup hook to ensure cleanup runs on exit
          @cleanup_done = false
          at_exit do
            cleanup unless @cleanup_done
          end

          # Start development server
          begin
            start_server
          ensure
            cleanup
          end
        end

        private

        def open_browser(url)
          case RbConfig::CONFIG["host_os"]
          when /darwin/
            system("open", url)
          when /linux/
            system("xdg-open", url)
          when /mswin|mingw|cygwin/
            system("start", url)
          else
            log_info("Please open #{url} in your browser")
          end
        rescue => e
          log_info("Could not open browser automatically: #{e.message}")
          log_info("Please open #{url} in your browser")
        end

        def cleanup
          return if @cleanup_done
          @cleanup_done = true
          @listener&.stop
          @watcher_thread&.kill
        end

        def build
          ensure_dist_directory

          success = pack_wasm(exit_on_error: false, log_prefix: "Building")
          if success
            copy_non_ruby_files
            log_success("✓ Build completed")
          else
            log_error("Build failed")
          end
          success
        end

        def start_file_watcher
          @listener = Listen.to("src") do |modified, added, removed|
            files_changed = (modified + added + removed).reject do |file|
              # Ignore temporary files and common build artifacts
              file.end_with?(".swp", ".tmp", "~", ".wasm")
            end

            if files_changed.any?
              log_info("Files changed: #{files_changed.join(', ')}")

              # Debounce: add to queue
              @build_queue << :build

              # Process queue with debouncing
              Thread.new do
                sleep 0.5 # Debounce delay
                begin
                  if @build_queue.pop(true)
                    @build_queue.clear
                    @build_lock.synchronize do
                      build
                    end
                  end
                rescue ThreadError
                  # Queue is empty, ignore
                end
              end
            end
          end

          @listener.start
        rescue => e
          log_error("File watcher error: #{e.message}")
        end

        def start_server
          port = 8080
          log_info("Starting development server on http://localhost:#{port}")
          log_info("Press Ctrl+C to stop")
          puts ""

          # Static file server application
          static_app = lambda do |env|
            path = env["PATH_INFO"]
            # Remove leading slash and handle root path
            relative_path = path == "/" ? "index.html" : path.sub(/^\//, "")

            # Serve files from dist directory
            file_path = File.join(Dir.pwd, "dist", relative_path)

            if File.exist?(file_path) && File.file?(file_path)
              content_type = Rack::Mime.mime_type(File.extname(file_path), "text/html")
              [200, { "Content-Type" => content_type }, [File.read(file_path)]]
            else
              [404, { "Content-Type" => "text/plain" }, ["File not found: #{path}"]]
            end
          end

          # CORS middleware
          cors_middleware = lambda do |env|
            if env["REQUEST_METHOD"] == "OPTIONS"
              [
                200,
                {
                  "Access-Control-Allow-Origin" => "*",
                  "Access-Control-Allow-Methods" => "GET, POST, OPTIONS",
                  "Access-Control-Allow-Headers" => "Content-Type"
                },
                []
              ]
            else
              status, headers, body = static_app.call(env)
              headers["Access-Control-Allow-Origin"] = "*"
              headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
              headers["Access-Control-Allow-Headers"] = "Content-Type"
              [status, headers, body]
            end
          end

          # Create Rack application
          app = Rack::Builder.new do
            run cors_middleware
          end

          # Handle shutdown
          trap("INT") do
            log_info("\nShutting down server...")
            cleanup
            raise SystemExit.new(0)
          end

          # Use Puma handler (Rack 3.0 compatible)
          begin
            require "rack/handler/puma"
            log_info("Using handler: puma")

            # Open browser after a short delay to ensure server is ready
            Thread.new do
              sleep 1
              open_browser("http://localhost:#{port}/index.html")
            end

            Rack::Handler::Puma.run(app, Port: port, Host: "0.0.0.0")
          rescue LoadError => e
            log_error("Puma handler not available: #{e.message}")
            log_error("Please ensure puma gem is installed: gem install puma")
            raise SystemExit.new(1)
          end
        rescue => e
          log_error("Server error: #{e.message}")
          raise SystemExit.new(1)
        end
      end
    end
  end
end
