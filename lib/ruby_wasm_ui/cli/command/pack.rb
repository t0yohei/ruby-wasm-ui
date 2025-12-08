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

          ensure_src_directory
          ensure_ruby_wasm

          # Pack WASM file
          pack
        end

        private

        def pack
          command = "bundle exec rbwasm pack ruby.wasm --dir ./src::./src -o src.wasm"
          log_info("Packing: #{command}")

          run_command(command)
          log_success("✓ Pack completed")
        end
      end
    end
  end
end
