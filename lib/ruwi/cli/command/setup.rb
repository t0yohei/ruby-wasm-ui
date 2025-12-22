# frozen_string_literal: true

require_relative "base"

module Ruwi
  module Cli
    class Command
      class Setup < Base
        def self.description
          "Set up the project for ruwi"
        end

        def run(_argv)
          log_info("Setting up ruwi project...")
          puts ""

          # Check Ruby version
          ruby_version_str = check_ruby_version

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
          update_gitignore(["ruby.wasm", "/rubies", "/build", "/dist"])
          log_success("✓ .gitignore updated")

          # Create initial files
          puts ""
          log_info("Step 4/4: Creating initial files...")
          create_initial_files

          puts ""
          log_success("Setup completed successfully!")
        end

        private

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
                  const response = await fetch("./src.wasm");
                  const module = await WebAssembly.compileStreaming(response);
                  const { vm } = await DefaultRubyVM(module);
                  vm.evalAsync(`
                    require "ruwi"
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
            HelloComponent = Ruwi.define_component(
              state: ->(props) {
                { message: props[:message] || "Hello, Ruby WASM UI!" }
              },
              template: ->() {
                Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
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
            app = Ruwi::App.create(HelloComponent, message: "Hello, Ruby WASM UI!")
            app_element = JS.global[:document].getElementById("app")
            app.mount(app_element)
          RUBY

          log_success("✓ Initial files created: src/index.html, src/index.rb")
        end
      end
    end
  end
end
