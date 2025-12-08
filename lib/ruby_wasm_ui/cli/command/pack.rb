# frozen_string_literal: true

require_relative "base"

module RubyWasmUi
  module Cli
    class Command
      class Pack < Base
        def self.description
          "Pack WASM file by packing Ruby source files"
        end

        def run(_argv)
          log_info("Packing WASM file...")
          puts ""

          # Check if src directory exists
          unless Dir.exist?("src")
            log_error("src directory not found. Please run 'ruby-wasm-ui setup' first.")
            exit 1
          end

          # Check if ruby.wasm exists
          unless File.exist?("ruby.wasm")
            log_error("ruby.wasm not found. Please run 'ruby-wasm-ui setup' first.")
            exit 1
          end

          # Pack WASM file
          pack
        end

        private

        def pack
          command = "bundle exec rbwasm pack ruby.wasm --dir ./src::./src -o src.wasm"
          log_info("Packing: #{command}")

          Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
            stdin.close

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

            stdout_thread.join
            stderr_thread.join

            exit_status = wait_thr.value

            unless exit_status.success?
              log_error("Pack failed")
              exit 1
            end

            log_success("✓ Pack completed")
          end
        end
      end
    end
  end
end
