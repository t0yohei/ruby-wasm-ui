# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyWasmUi::NodesEqual do
  describe '.equal?' do
    context 'Nodes with different types' do
      it 'returns false for nodes with different types' do
        text_node = RubyWasmUi::Vdom.h_string('Hello')
        element_node = RubyWasmUi::Vdom.h('div')

        result = described_class.equal?(text_node, element_node)
        expect(result).to be false
      end

      it 'returns false for TEXT and ELEMENT type nodes' do
        text_node = RubyWasmUi::Vdom.h_string('Hello')
        element_node = RubyWasmUi::Vdom.h('span')

        result = described_class.equal?(text_node, element_node)
        expect(result).to be false
      end

      it 'returns false for ELEMENT and FRAGMENT type nodes' do
        element_node = RubyWasmUi::Vdom.h('div')
        fragment_node = RubyWasmUi::Vdom.h_fragment([])

        result = described_class.equal?(element_node, fragment_node)
        expect(result).to be false
      end
    end

    context 'ELEMENT type nodes' do
      it 'returns true for ELEMENT nodes with the same tag name' do
        node_one = RubyWasmUi::Vdom.h('div')
        node_two = RubyWasmUi::Vdom.h('div')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end

      it 'returns false for ELEMENT nodes with different tag names' do
        node_one = RubyWasmUi::Vdom.h('div')
        node_two = RubyWasmUi::Vdom.h('span')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be false
      end

      it 'returns false for ELEMENT nodes with different cases in tag names' do
        node_one = RubyWasmUi::Vdom.h('DIV')
        node_two = RubyWasmUi::Vdom.h('div')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be false
      end

      it 'returns true for ELEMENT nodes with complex tag names' do
        node_one = RubyWasmUi::Vdom.h('custom-element')
        node_two = RubyWasmUi::Vdom.h('custom-element')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end
    end

    context 'TEXT type nodes' do
      it 'returns true for TEXT nodes with the same value' do
        node_one = RubyWasmUi::Vdom.h_string('Hello')
        node_two = RubyWasmUi::Vdom.h_string('Hello')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end

      it 'returns false for TEXT nodes with different values' do
        node_one = RubyWasmUi::Vdom.h_string('Hello')
        node_two = RubyWasmUi::Vdom.h_string('World')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be false
      end
    end

    context 'FRAGMENT type nodes' do
      it 'returns true for FRAGMENT nodes' do
        node_one = RubyWasmUi::Vdom.h_fragment([])
        node_two = RubyWasmUi::Vdom.h_fragment([])

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end
    end

    context 'Edge cases' do
      it 'returns true for ELEMENT nodes with empty string tag names' do
        node_one = RubyWasmUi::Vdom.h('')
        node_two = RubyWasmUi::Vdom.h('')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end

      it 'returns false for ELEMENT nodes with empty and non-empty tag names' do
        node_one = RubyWasmUi::Vdom.h('')
        node_two = RubyWasmUi::Vdom.h('div')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be false
      end
    end
  end
end
