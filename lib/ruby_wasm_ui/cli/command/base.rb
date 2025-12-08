# frozen_string_literal: true

require "open3"

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
                exit exit_status.exitstatus
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
            exit 1
          end
        end

        def ensure_ruby_wasm
          unless File.exist?("ruby.wasm")
            log_error("ruby.wasm not found. Please run 'ruby-wasm-ui setup' first.")
            exit 1
          end
        end

        def update_gitignore(entries_to_add)
          gitignore_path = ".gitignore"

          # Read existing .gitignore or create new content
          if File.exist?(gitignore_path)
            content = File.read(gitignore_path)
            lines = content.lines.map(&:chomp)
          else
            lines = []
          end

          # Add entries that don't already exist
          added_entries = []
          entries_to_add.each do |entry|
            unless lines.include?(entry)
              lines << entry
              added_entries << entry
            end
          end

          # Write back to .gitignore
          File.write(gitignore_path, lines.join("\n") + "\n")
          if added_entries.any?
            log_info("Added to .gitignore: #{added_entries.join(', ')}")
          else
            log_info("No new entries added to .gitignore (all entries already exist)")
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
      end
    end
  end
end
