# frozen_string_literal: true

require "fileutils"
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
          ensure_dist_directory

          # Pack WASM file
          pack

          # Copy non-Ruby files from src to dist
          copy_non_ruby_files
        end

        private

        def ensure_dist_directory
          unless Dir.exist?("dist")
            Dir.mkdir("dist")
            log_info("Created dist directory")
          end
        end

        def pack
          command = "bundle exec rbwasm pack ruby.wasm --dir ./src::./src -o dist/src.wasm"
          log_info("Packing: #{command}")

          run_command(command)
          log_success("✓ Pack completed")
        end

        def copy_non_ruby_files
          log_info("Copying non-Ruby files from src to dist...")

          copied_files = []
          Dir.glob("src/**/*").each do |src_path|
            next if File.directory?(src_path)
            next if src_path.end_with?(".rb")

            # Get relative path from src directory
            relative_path = src_path.sub(/^src\//, "")
            dest_path = File.join("dist", relative_path)

            # Create destination directory if needed
            dest_dir = File.dirname(dest_path)
            FileUtils.mkdir_p(dest_dir) unless Dir.exist?(dest_dir)

            # Copy file
            FileUtils.cp(src_path, dest_path)
            copied_files << relative_path
          end

          if copied_files.any?
            log_success("✓ Copied #{copied_files.size} file(s): #{copied_files.join(', ')}")
          else
            log_info("No non-Ruby files to copy")
          end
        end
      end
    end
  end
end
