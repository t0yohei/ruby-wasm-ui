# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyWasmUi::Utils::Arrays do
  describe '.without_nulls' do
    context 'Basic functionality' do
      it 'removes nil values from an array containing nils' do
        arr = [1, nil, 2, nil, 3]
        result = described_class.without_nulls(arr)
        expect(result).to eq([1, 2, 3])
      end

      it 'returns the original array when it contains no nil values' do
        arr = [1, 2, 3]
        result = described_class.without_nulls(arr)
        expect(result).to eq([1, 2, 3])
      end
    end

    context 'Edge cases' do
      it 'returns an empty array when given an empty array' do
        arr = []
        result = described_class.without_nulls(arr)
        expect(result).to eq([])
      end

      it 'returns an empty array when all elements are nil' do
        arr = [nil, nil, nil]
        result = described_class.without_nulls(arr)
        expect(result).to eq([])
      end

      it 'preserves falsy values like false, 0, and empty string' do
        arr = [false, 0, '', nil]
        result = described_class.without_nulls(arr)
        expect(result).to eq([false, 0, ''])
      end
    end
  end

  describe '.diff' do
    context 'Basic functionality' do
      it 'correctly detects added and removed elements' do
        old_array = [1, 2, 3]
        new_array = [2, 3, 4]
        result = described_class.diff(old_array, new_array)
        expect(result).to eq({
          added: [4],
          removed: [1]
        })
      end

      it 'returns empty arrays when comparing identical arrays' do
        array = [1, 2, 3]
        result = described_class.diff(array, array)
        expect(result).to eq({
          added: [],
          removed: []
        })
      end
    end

    context 'Edge cases' do
      it 'works correctly when comparing with an empty array' do
        old_array = []
        new_array = [1, 2, 3]
        result = described_class.diff(old_array, new_array)
        expect(result).to eq({
          added: [1, 2, 3],
          removed: []
        })
      end

      it 'handles duplicate elements correctly' do
        old_array = [1, 1, 2, 2]
        new_array = [2, 2, 3, 3]
        result = described_class.diff(old_array, new_array)
        expect(result).to eq({
          added: [3],
          removed: [1]
        })
      end
    end
  end

  describe '.diff_sequence' do
    context 'Basic functionality' do
      it 'returns correct sequence for simple addition' do
        old_array = [1, 2, 3]
        new_array = [1, 2, 3, 4]
        result = described_class.diff_sequence(old_array, new_array)
        expect(result).to eq([
          { op: 'noop', original_index: 0, index: 0, item: 1 },
          { op: 'noop', original_index: 1, index: 1, item: 2 },
          { op: 'noop', original_index: 2, index: 2, item: 3 },
          { op: 'add', index: 3, item: 4 }
        ])
      end

      it 'returns correct sequence for simple removal' do
        old_array = [1, 2, 3, 4]
        new_array = [1, 2, 3]
        result = described_class.diff_sequence(old_array, new_array)
        expect(result).to eq([
          { op: 'noop', original_index: 0, index: 0, item: 1 },
          { op: 'noop', original_index: 1, index: 1, item: 2 },
          { op: 'noop', original_index: 2, index: 2, item: 3 },
          { op: 'remove', index: 3, item: 4 }
        ])
      end

      it 'returns correct sequence for reordering' do
        old_array = [1, 2, 3]
        new_array = [3, 1, 2]
        result = described_class.diff_sequence(old_array, new_array)
        expect(result).to eq([
          { op: 'move', original_index: 2, from: 2, index: 0, item: 3 },
          { op: 'noop', original_index: 0, index: 1, item: 1 },
          { op: 'noop', original_index: 1, index: 2, item: 2 }
        ])
      end
    end

    context 'Complex scenarios' do
      it 'handles multiple operations in sequence' do
        old_array = [1, 2, 3, 4]
        new_array = [5, 2, 1, 6]
        result = described_class.diff_sequence(old_array, new_array)
        expect(result).to eq([
          { op: 'add', index: 0, item: 5 },
          { op: 'move', original_index: 1, from: 2, index: 1, item: 2 },
          { op: 'noop', original_index: 0, index: 2, item: 1 },
          { op: 'remove', index: 3, item: 3 },
          { op: 'remove', index: 3, item: 4 },
          { op: 'add', index: 3, item: 6 }
        ])
      end

      it 'handles empty arrays' do
        old_array = []
        new_array = []
        result = described_class.diff_sequence(old_array, new_array)
        expect(result).to eq([])
      end

      it 'handles complete replacement' do
        old_array = ['X', 'A', 'A', 'B', 'C']
        new_array = ['C', 'K', 'A', 'B']

        result = described_class.diff_sequence(old_array, new_array)
        expect(result).to eq([
          { op: 'remove', index: 0, item: 'X' },
          { op: 'move', original_index: 4, from: 3, index: 0, item: 'C' },
          { op: 'add', index: 1, item: 'K' },
          { op: 'noop', original_index: 1, index: 2, item: 'A' },
          { op: 'move', original_index: 3, from: 4, index: 3, item: 'B' },
          { op: 'remove', index: 4, item: 'A' }
        ])
      end
    end
  end
end
