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
end
