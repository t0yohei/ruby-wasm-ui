# frozen_string_literal: true

require "bundler/setup"
require "ruby_wasm"
require "ruby_wasm/cli"
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

          # Configure excluded gems for WASM build
          log_info("Step 1/3: Configuring excluded gems...")
          configure_excluded_gems
          log_success("✓ Excluded gems configured")

          # Build Ruby WASM
          puts ""
          log_info("Step 2/3: Building Ruby WASM...")
          log_info("Running: rbwasm build --ruby-version #{ruby_version_str} -o ruby.wasm")
          build_ruby_wasm(ruby_version_str)
          log_success("✓ Ruby WASM build completed")

          # Update .gitignore
          puts ""
          log_info("Step 3/3: Updating .gitignore...")
          update_gitignore(["*.wasm", "/rubies", "/build"])

          puts ""
          log_success("Setup completed successfully!")
        end

        private

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
      end
    end
  end
end
