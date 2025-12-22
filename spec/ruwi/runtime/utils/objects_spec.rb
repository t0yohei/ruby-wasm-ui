# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruwi::Utils::Objects do
  describe '.diff' do
    context 'Basic diff calculation' do
      it 'correctly detects added keys' do
        old_obj = { a: 1, b: 2 }
        new_obj = { a: 1, b: 2, c: 3 }

        result = described_class.diff(old_obj, new_obj)

        expect(result[:added]).to eq([:c])
        expect(result[:removed]).to be_empty
        expect(result[:updated]).to be_empty
      end

      it 'correctly detects removed keys' do
        old_obj = { a: 1, b: 2, c: 3 }
        new_obj = { a: 1, b: 2 }

        result = described_class.diff(old_obj, new_obj)

        expect(result[:added]).to be_empty
        expect(result[:removed]).to eq([:c])
        expect(result[:updated]).to be_empty
      end

      it 'correctly detects updated keys' do
        old_obj = { a: 1, b: 2, c: 3 }
        new_obj = { a: 1, b: 3, c: 3 }

        result = described_class.diff(old_obj, new_obj)

        expect(result[:added]).to be_empty
        expect(result[:removed]).to be_empty
        expect(result[:updated]).to eq([:b])
      end
    end

    context 'Edge cases' do
      it 'works correctly with empty objects' do
        old_obj = {}
        new_obj = { a: 1 }

        result = described_class.diff(old_obj, new_obj)

        expect(result[:added]).to eq([:a])
        expect(result[:removed]).to be_empty
        expect(result[:updated]).to be_empty
      end

      it 'works correctly with completely different objects' do
        old_obj = { a: 1, b: 2 }
        new_obj = { c: 3, d: 4 }

        result = described_class.diff(old_obj, new_obj)

        expect(result[:added]).to eq([:c, :d])
        expect(result[:removed]).to eq([:a, :b])
        expect(result[:updated]).to be_empty
      end

      it 'shows no differences when comparing the same object' do
        obj = { a: 1, b: 2 }

        result = described_class.diff(obj, obj)

        expect(result[:added]).to be_empty
        expect(result[:removed]).to be_empty
        expect(result[:updated]).to be_empty
      end
    end
  end

  describe '.has_own_property' do
    context 'with Hash objects' do
      let(:hash_obj) { { name: 'test', age: 25, 'city' => 'Tokyo' } }

      it 'returns true when the key exists (symbol)' do
        expect(described_class.has_own_property(hash_obj, :name)).to be true
      end

      it 'returns true when the key exists (string)' do
        expect(described_class.has_own_property(hash_obj, 'city')).to be true
      end

      it 'returns false when the key does not exist' do
        expect(described_class.has_own_property(hash_obj, :email)).to be false
      end

      it 'returns false when the key does not exist (string)' do
        expect(described_class.has_own_property(hash_obj, 'country')).to be false
      end

      it 'works correctly with empty hash' do
        empty_hash = {}
        expect(described_class.has_own_property(empty_hash, :any_key)).to be false
      end
    end

    context 'with custom objects' do
      let(:custom_object) do
        obj = Object.new
        obj.instance_variable_set(:@name, 'test')
        obj.instance_variable_set(:@age, 25)
        obj
      end

      it 'returns true when the instance variable exists' do
        expect(described_class.has_own_property(custom_object, :name)).to be true
        expect(described_class.has_own_property(custom_object, 'age')).to be true
      end

      it 'returns false when the instance variable does not exist' do
        expect(described_class.has_own_property(custom_object, :email)).to be false
        expect(described_class.has_own_property(custom_object, 'city')).to be false
      end

      it 'works correctly with object without instance variables' do
        empty_object = Object.new
        expect(described_class.has_own_property(empty_object, :any_property)).to be false
      end
    end
  end
end
