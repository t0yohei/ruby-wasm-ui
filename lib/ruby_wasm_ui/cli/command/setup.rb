# frozen_string_literal: true

require_relative "base"

module RubyWasmUi
  module Cli
    class Command
      class Setup < Base
        def self.description
          "Set up the project for ruby-wasm-ui"
        end

        def run(_argv)
          log_info("Setting up ruby-wasm-ui project...")
          puts ""

          # Check Ruby version
          ruby_version = RUBY_VERSION.split('.').map(&:to_i)
          major, minor = ruby_version[0], ruby_version[1]

          if major < 3 || (major == 3 && minor < 2)
            log_error("Ruby WASM requires Ruby 3.2 or higher. Current version: #{RUBY_VERSION}")
            exit 1
          end

          ruby_version_str = "#{major}.#{minor}"

          # Build Ruby WASM
          log_info("Step 1/2: Building Ruby WASM...")
          log_info("Running: bundle exec rbwasm build --ruby-version #{ruby_version_str} -o ruby.wasm")
          run_command("bundle exec rbwasm build --ruby-version #{ruby_version_str} -o ruby.wasm")
          log_success("✓ Ruby WASM build completed")

          # Update .gitignore
          puts ""
          log_info("Step 2/2: Updating .gitignore...")
          update_gitignore(["*.wasm", "/rubies", "/build"])

          puts ""
          log_success("Setup completed successfully!")
        end
      end
    end
  end
end
