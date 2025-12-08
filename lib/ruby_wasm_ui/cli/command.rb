# frozen_string_literal: true

require_relative "command/setup"
# To add a new command (e.g., dev):
# 1. Create lib/ruby_wasm_ui/cli/command/dev.rb inheriting from Command::Base
# 2. Add require_relative "command/dev" above
# 3. Add "dev" => Command::Dev to COMMANDS hash below

module RubyWasmUi
  module Cli
    class Command
      COMMANDS = {
        "setup" => Command::Setup
        # Add new commands here, e.g.:
        # "dev" => Command::Dev
      }.freeze

      def self.run(argv)
        command_name = argv[0]

        if command_name.nil?
          show_usage
          exit 1
        end

        command_class = COMMANDS[command_name]
        if command_class.nil?
          puts "Unknown command: #{command_name}"
          puts ""
          show_usage
          exit 1
        end

        command_class.new.run(argv[1..-1])
      end

      def self.show_usage
        puts "Usage: ruby-wasm-ui <command>"
        puts ""
        puts "Commands:"
        COMMANDS.each do |name, klass|
          description = klass.description || ""
          puts "  #{name.ljust(12)}#{description}"
        end
      end
    end
  end
end
