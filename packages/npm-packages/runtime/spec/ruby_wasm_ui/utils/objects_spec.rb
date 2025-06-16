# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyWasmUi::Utils::Objects do
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
end
