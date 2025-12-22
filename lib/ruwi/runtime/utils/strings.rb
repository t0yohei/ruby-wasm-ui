module Ruwi
  module Utils
    module Strings
      module_function

      # @param str [String]
      # @return [Boolean]
      def is_not_empty_string(str)
        str != ""
      end

      # @param str [String]
      # @return [Boolean]
      def is_not_blank_or_empty_string(str)
        is_not_empty_string(str.strip)
      end
    end
  end
end
