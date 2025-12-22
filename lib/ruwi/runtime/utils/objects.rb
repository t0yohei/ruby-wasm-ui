# frozen_string_literal: true

module Ruwi
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

      # Check if an object has its own property (not inherited)
      # @param obj [Hash, Object] The object to check
      # @param prop [Symbol, String] The property name to check
      # @return [Boolean] true if the object has the property
      def has_own_property(obj, prop)
        case obj
        when Hash
          obj.key?(prop)
        else
          # For other objects, check if it's an instance variable
          obj.instance_variable_defined?("@#{prop}")
        end
      end
    end
  end
end
