# frozen_string_literal: true

require_relative "base"

module RubyWasmUi
  module Cli
    class Command
      class Rebuild < Base
        def self.description
          "Rebuild Ruby WASM file (useful when gems are added)"
        end

        def run(_argv)
          log_info("Rebuilding Ruby WASM...")
          puts ""

          # Check Ruby version
          ruby_version_str = check_ruby_version

          # Configure excluded gems for WASM build
          log_info("Step 1/2: Configuring excluded gems...")
          configure_excluded_gems
          log_success("✓ Excluded gems configured")

          # Build Ruby WASM
          puts ""
          log_info("Step 2/2: Building Ruby WASM...")
          log_info("Running: rbwasm build --ruby-version #{ruby_version_str} -o ruby.wasm")
          build_ruby_wasm(ruby_version_str)
          log_success("✓ Ruby WASM build completed")

          puts ""
          log_success("Rebuild completed successfully!")
        end
      end
    end
  end
end
