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
          log_info("Step 3/4: Updating .gitignore...")
          update_gitignore(["*.wasm", "/rubies", "/build"])
          log_success("✓ .gitignore updated")

          # Create initial files
          puts ""
          log_info("Step 4/4: Creating initial files...")
          create_initial_files

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

        def create_initial_files
          # Skip if src directory exists
          if Dir.exist?("src")
            log_info("src directory already exists, skipping initial file creation")
            return
          end

          # Skip if files already exist
          if File.exist?("src/index.html")
            log_info("src/index.html already exists, skipping initial file creation")
            return
          end

          if File.exist?("src/index.rb")
            log_info("src/index.rb already exists, skipping initial file creation")
            return
          end

          # Create src directory
          Dir.mkdir("src")

          # Create index.html
          File.write("src/index.html", <<~HTML)
            <!DOCTYPE html>
            <html lang="en">
              <head>
                <meta charset="UTF-8" />
                <title>My App</title>
                <script type="module">
                  import { DefaultRubyVM } from "https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@2.7.2/dist/browser/+esm";
                  const response = await fetch("../src.wasm");
                  const module = await WebAssembly.compileStreaming(response);
                  const { vm } = await DefaultRubyVM(module);
                  vm.evalAsync(`
                    require "ruby_wasm_ui"
                    require_relative './src/index.rb'
                  `);
                </script>
              </head>
              <body>
                <h1>My App</h1>
                <div id="app"></div>
              </body>
            </html>
          HTML

          # Create index.rb
          File.write("src/index.rb", <<~RUBY)
            # Simple Hello World component
            HelloComponent = RubyWasmUi.define_component(
              state: ->(props) {
                { message: props[:message] || "Hello, Ruby WASM UI!" }
              },
              template: ->() {
                RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
                  <div>
                    <h2>{state[:message]}</h2>
                    <button on="{ click: -> { update_message } }">
                      Click me!
                    </button>
                  </div>
                HTML
              },
              methods: {
                update_message: ->() {
                  update_state(message: "You clicked the button!")
                }
              }
            )

            # Create and mount the app
            app = RubyWasmUi::App.create(HelloComponent, message: "Hello, Ruby WASM UI!")
            app_element = JS.global[:document].getElementById("app")
            app.mount(app_element)
          RUBY

          log_success("✓ Initial files created: src/index.html, src/index.rb")
        end
      end
    end
  end
end
