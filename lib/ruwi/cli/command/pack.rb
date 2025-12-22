# frozen_string_literal: true

require_relative "base"

module Ruwi
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
          ensure_dist_directory

          # Pack WASM file
          pack

          # Copy non-Ruby files from src to dist
          copy_non_ruby_files
        end

        private

        def pack
          pack_wasm(exit_on_error: true, log_prefix: 'Packing')
        end
      end
    end
  end
end
