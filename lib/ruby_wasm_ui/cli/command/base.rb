# frozen_string_literal: true

require "fileutils"
require "open3"
require "bundler/setup"
require "ruby_wasm"
require "ruby_wasm/cli"

module RubyWasmUi
  module Cli
    class Command
      class Base
        def self.description
          nil
        end

        def run(_argv)
          raise NotImplementedError, "Subclasses must implement #run"
        end

        protected

        def run_command(command, exit_on_error: true)
          log_debug("Executing command: #{command}")

          Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
            stdin.close

            # Read stdout and stderr in separate threads for real-time output
            stdout_thread = Thread.new do
              stdout.each_line do |line|
                print line
                $stdout.flush
              end
            end

            stderr_thread = Thread.new do
              stderr.each_line do |line|
                $stderr.print line
                $stderr.flush
              end
            end

            # Wait for both threads to finish reading
            stdout_thread.join
            stderr_thread.join

            # Wait for the process to finish
            exit_status = wait_thr.value

            unless exit_status.success?
              log_error("Command failed: #{command}")
              if exit_on_error
                raise SystemExit.new(exit_status.exitstatus)
              else
                return false
              end
            end

            true
          end
        end

        def ensure_src_directory
          unless Dir.exist?("src")
            log_error("src directory not found. Please run 'ruby-wasm-ui setup' first.")
            raise SystemExit.new(1)
          end
        end

        def ensure_ruby_wasm
          unless File.exist?("ruby.wasm")
            log_error("ruby.wasm not found. Please run 'ruby-wasm-ui setup' first.")
            raise SystemExit.new(1)
          end
        end

        protected

        def log_info(message)
          puts "[INFO] #{message}"
        end

        def log_success(message)
          puts "[SUCCESS] #{message}"
        end

        def log_error(message)
          puts "[ERROR] #{message}"
        end

        def log_debug(message)
          puts "[DEBUG] #{message}"
        end

        def check_ruby_version
          ruby_version = RUBY_VERSION.split('.').map(&:to_i)
          major, minor = ruby_version[0], ruby_version[1]

          if major < 3 || (major == 3 && minor < 2)
            log_error("Ruby WASM requires Ruby 3.2 or higher. Current version: #{RUBY_VERSION}")
            raise SystemExit.new(1)
          end

          "#{major}.#{minor}"
        end

        def configure_excluded_gems
          # Get all gems from Bundler definition including all dependencies
          definition = Bundler.definition
          resolved = definition.resolve

          # Get all resolved specs (including transitive dependencies)
          all_specs = resolved.materialize(definition.requested_dependencies)
          gem_names = all_specs.map(&:name).uniq

          # Always exclude gems that cause WASM build errors
          # These gems have native extensions that don't work in WASM environment
          always_excluded = %w[nio4r puma rack listen ffi]

          # Exclude gems that cause build errors or are unnecessary for WASM
          # Keep essential gems like 'js' for WASM
          excluded_gems = gem_names.select do |gem_name|
            # Exclude gems that cause WASM build errors
            always_excluded.include?(gem_name) ||
              # Exclude development/test gems
              gem_name.start_with?("rspec", "rubocop", "rake")
          end

          # Always add always_excluded gems to ensure they're excluded even if not in dependencies
          excluded_gems.concat(always_excluded)
          excluded_gems.uniq!

          # Add to EXCLUDED_GEMS
          RubyWasm::Packager::EXCLUDED_GEMS.concat(excluded_gems)
        end

        def build_ruby_wasm(ruby_version_str)
          command = ["build", "--ruby-version", ruby_version_str, "-o", "ruby.wasm"]
          cli = RubyWasm::CLI.new(stdout: $stdout, stderr: $stderr)
          cli.run(command)
        end

        def ensure_dist_directory
          unless Dir.exist?("dist")
            Dir.mkdir("dist")
            log_info("Created dist directory")
          end
        end

        def copy_non_ruby_files
          log_info("Copying non-Ruby files from src to dist...")

          copied_files = []
          Dir.glob("src/**/*").each do |src_path|
            next if File.directory?(src_path)
            next if src_path.end_with?(".rb")

            # Get relative path from src directory
            relative_path = src_path.sub(/^src\//, "")
            dest_path = File.join("dist", relative_path)

            # Create destination directory if needed
            dest_dir = File.dirname(dest_path)
            FileUtils.mkdir_p(dest_dir) unless Dir.exist?(dest_dir)

            # Copy file
            FileUtils.cp(src_path, dest_path)
            copied_files << relative_path
          end

          if copied_files.any?
            log_success("✓ Copied #{copied_files.size} file(s): #{copied_files.join(', ')}")
          else
            log_info("No non-Ruby files to copy")
          end
        end

        def pack_wasm(exit_on_error: true, log_prefix: "Packing")
          command = "bundle exec rbwasm pack ruby.wasm --dir ./src::./src -o dist/src.wasm"
          log_info("#{log_prefix}: #{command}")

          success = run_command(command, exit_on_error: exit_on_error)
          if success
            log_success("✓ Pack completed")
          end
          success
        end
      end
    end
  end
end
