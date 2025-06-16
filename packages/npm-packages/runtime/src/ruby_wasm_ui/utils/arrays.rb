# frozen_string_literal: true

module RubyWasmUi
  module Utils
    module Arrays
      def self.without_nulls(arr)
        arr.reject { |item| item.nil? }
      end
    end
  end
end
