# frozen_string_literal: true

require_relative "command/setup"
require_relative "command/dev"
require_relative "command/pack"
require_relative "command/rebuild"

module RubyWasmUi
  module Cli
    class Command
      COMMANDS = {
        "setup" => Command::Setup,
        "dev" => Command::Dev,
        "pack" => Command::Pack,
        "rebuild" => Command::Rebuild
      }.freeze

      def self.run(argv)
        command_name = argv[0]

        if command_name.nil?
          show_usage
          raise SystemExit.new(1)
        end

        command_class = COMMANDS[command_name]
        if command_class.nil?
          puts "Unknown command: #{command_name}"
          puts ""
          show_usage
          raise SystemExit.new(1)
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
