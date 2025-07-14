# frozen_string_literal: true

module RubyWasmUi
  module Utils
    module Objects
      module_function

      # @param old_obj [Hash]
      # @param new_obj [Hash]
      # @return [Hash]
      def diff(old_obj, new_obj)
        old_keys = old_obj.keys
        new_keys = new_obj.keys

        {
          added: new_keys.select { |key| !old_obj.key?(key) },
          removed: old_keys.select { |key| !new_obj.key?(key) },
          updated: new_keys.select { |key| old_obj.key?(key) && old_obj[key] != new_obj[key] }
        }
      end
    end
  end
end
