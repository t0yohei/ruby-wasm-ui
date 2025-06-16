# frozen_string_literal: true

module RubyWasmUi
  module Utils
    module Arrays
      # @param arr [Array]
      # @return [Array]
      def self.without_nulls(arr)
        arr.reject { |item| item.nil? }
      end

      # @param old_array [Array]
      # @param new_array [Array]
      # @return [Hash] Hash containing added and removed items
      def self.diff(old_array, new_array)
        {
          added: (new_array - old_array).uniq,
          removed: (old_array - new_array).uniq
        }
      end

      class ArrayWithOriginalIndices
        attr_reader :array, :original_indices, :equal_proc

        ARRAY_DIFF_OP = {
          ADD: "add",
          REMOVE: "remove",
          MOVE: "move",
          NOOP: "noop",
        }.freeze

        private_constant :ARRAY_DIFF_OP

        def initialize(array, equal_proc)
          @array = array.dup
          @original_indices = array.each_index.to_a
          @equal_proc = equal_proc
        end

        def is_removal?(index, new_array)
          return false if index >= length

          item = @array[index]
          index_in_new_array = new_array.find_index { |new_item| @equal_proc.call(new_item, item) }

          index_in_new_array.nil?
        end

        def is_noop?(index, new_array)
          return false if index >= length

          item = @array[index]
          new_item = new_array[index]

          @equal_proc.call(item, new_item)
        end

        def is_addition?(item, from_index)
          return find_index_from(item, from_index).nil?
        end

        def remove_item(index)
          operation = {
            op: ARRAY_DIFF_OP[:REMOVE],
            index:,
            item: @array[index]
          }

          @array.delete_at(index)
          @original_indices.delete_at(index)

          operation
        end

        def noop_item(index)
          {
            op: ARRAY_DIFF_OP[:NOOP],
            original_index: original_index_at(index),
            index:,
            item: @array[index]
          }
        end

        def add_item(item, index)
          operation = {
            op: ARRAY_DIFF_OP[:ADD],
            index:,
            item:
          }

          @array.insert(index, item)
          @original_indices.insert(index, -1)

          operation
        end

        def move_item(item, to_index)
          from_index = find_index_from(item, to_index)

          operation = {
            op: ARRAY_DIFF_OP[:MOVE],
            original_index: original_index_at(from_index),
            from: from_index,
            index: to_index,
            item: @array[from_index]
          }

          temp_deleted_item = @array.delete_at(from_index)
          @array.insert(to_index, temp_deleted_item)

          temp_deleted_original_index = @original_indices.delete_at(from_index)
          @original_indices.insert(to_index, temp_deleted_original_index)

          operation
        end

        def remove_item_after(index)
          operations = []

          while index < length
            operations << remove_item(index)
          end

          operations
        end

        private

        def length
          @array.length
        end

        def original_index_at(index)
          @original_indices[index]
        end

        def find_index_from(item, from_index)
          (from_index...length).each do |index|
            return index if @equal_proc.call(@array[index], item)
          end

          nil
        end
      end

      # @param old_array [Array]
      # @param new_array [Array]
      # @param equal_proc [Proc]
      # @return [Array] sequence of operations to transform old_array into new_array
      def self.diff_sequence(old_array, new_array, equal_proc = ->(a, b) { a == b })
        sequence = []
        array = ArrayWithOriginalIndices.new(old_array, equal_proc)

        index = 0
        while index < new_array.length
          if array.is_removal?(index, new_array)
            sequence << array.remove_item(index)
            next
          end

          if array.is_noop?(index, new_array)
            sequence << array.noop_item(index)
            index += 1
            next
          end

          item = new_array[index]

          if array.is_addition?(item, index)
            sequence << array.add_item(item, index)
            index += 1
            next
          end

          sequence << array.move_item(item, index)
          index += 1
        end

        sequence.concat(array.remove_item_after(new_array.length))

        sequence
      end
    end
  end
end
