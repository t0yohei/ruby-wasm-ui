module RubyWasmUi
  module Utils
    module Strings
      # @param str [String]
      # @return [Boolean]
      def self.is_not_empty_string(str)
        str != ""
      end

      # @param str [String]
      # @return [Boolean]
      def self.is_not_blank_or_empty_string(str)
        is_not_empty_string(str.strip)
      end
    end
  end
end
