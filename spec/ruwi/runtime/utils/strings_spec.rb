# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruwi::Utils::Strings do
  describe '.is_not_empty_string' do
    context 'Basic functionality' do
      it 'returns true for non-empty strings' do
        result = described_class.is_not_empty_string('hello')
        expect(result).to be true
      end

      it 'returns false for empty strings' do
        result = described_class.is_not_empty_string('')
        expect(result).to be false
      end

      it 'returns true for strings with only spaces' do
        result = described_class.is_not_empty_string('   ')
        expect(result).to be true
      end

      it 'returns true for strings with special characters' do
        result = described_class.is_not_empty_string('!@#$%')
        expect(result).to be true
      end
    end

    context 'Edge cases' do
      it 'returns true for single character strings' do
        result = described_class.is_not_empty_string('a')
        expect(result).to be true
      end

      it 'returns true for strings with newlines' do
        result = described_class.is_not_empty_string("\n")
        expect(result).to be true
      end

      it 'returns true for strings with tabs' do
        result = described_class.is_not_empty_string("\t")
        expect(result).to be true
      end
    end
  end

  describe '.is_not_blank_or_empty_string' do
    context 'Basic functionality' do
      it 'returns true for non-empty strings' do
        result = described_class.is_not_blank_or_empty_string('hello')
        expect(result).to be true
      end

      it 'returns false for empty strings' do
        result = described_class.is_not_blank_or_empty_string('')
        expect(result).to be false
      end

      it 'returns false for strings with only spaces' do
        result = described_class.is_not_blank_or_empty_string('   ')
        expect(result).to be false
      end

      it 'returns true for strings with content and leading/trailing spaces' do
        result = described_class.is_not_blank_or_empty_string('  hello  ')
        expect(result).to be true
      end

      it 'returns true for strings with special characters' do
        result = described_class.is_not_blank_or_empty_string('!@#$%')
        expect(result).to be true
      end
    end

    context 'Edge cases' do
      it 'returns false for strings with only newlines' do
        result = described_class.is_not_blank_or_empty_string("\n\n")
        expect(result).to be false
      end

      it 'returns false for strings with only tabs' do
        result = described_class.is_not_blank_or_empty_string("\t\t")
        expect(result).to be false
      end

      it 'returns false for strings with mixed whitespace characters' do
        result = described_class.is_not_blank_or_empty_string(" \t\n ")
        expect(result).to be false
      end

      it 'returns true for single non-whitespace character' do
        result = described_class.is_not_blank_or_empty_string('a')
        expect(result).to be true
      end

      it 'returns true for strings with content surrounded by mixed whitespace' do
        result = described_class.is_not_blank_or_empty_string(" \t hello \n ")
        expect(result).to be true
      end

      it 'returns true for Unicode whitespace (strip does not remove Unicode whitespace)' do
        result = described_class.is_not_blank_or_empty_string("\u00A0\u2000\u2001")
        expect(result).to be true
      end
    end
  end
end
