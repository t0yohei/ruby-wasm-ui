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

          # Build Ruby WASM
          log_info("Step 1/2: Building Ruby WASM...")
          log_info("Running: bundle exec rbwasm build --ruby-version 3.4 -o ruby.wasm")
          run_command("bundle exec rbwasm build --ruby-version 3.4 -o ruby.wasm")
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
