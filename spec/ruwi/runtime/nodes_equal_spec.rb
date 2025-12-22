# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruwi::NodesEqual do
  describe '.equal?' do
    context 'Nodes with different types' do
      it 'returns false for nodes with different types' do
        text_node = Ruwi::Vdom.h_string('Hello')
        element_node = Ruwi::Vdom.h('div')

        result = described_class.equal?(text_node, element_node)
        expect(result).to be false
      end

      it 'returns false for TEXT and ELEMENT type nodes' do
        text_node = Ruwi::Vdom.h_string('Hello')
        element_node = Ruwi::Vdom.h('span')

        result = described_class.equal?(text_node, element_node)
        expect(result).to be false
      end

      it 'returns false for ELEMENT and FRAGMENT type nodes' do
        element_node = Ruwi::Vdom.h('div')
        fragment_node = Ruwi::Vdom.h_fragment([])

        result = described_class.equal?(element_node, fragment_node)
        expect(result).to be false
      end
    end

    context 'ELEMENT type nodes' do
      it 'returns true for ELEMENT nodes with the same tag name' do
        node_one = Ruwi::Vdom.h('div')
        node_two = Ruwi::Vdom.h('div')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end

      it 'returns false for ELEMENT nodes with different tag names' do
        node_one = Ruwi::Vdom.h('div')
        node_two = Ruwi::Vdom.h('span')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be false
      end

      it 'returns false for ELEMENT nodes with different cases in tag names' do
        node_one = Ruwi::Vdom.h('DIV')
        node_two = Ruwi::Vdom.h('div')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be false
      end

      it 'returns true for ELEMENT nodes with complex tag names' do
        node_one = Ruwi::Vdom.h('custom-element')
        node_two = Ruwi::Vdom.h('custom-element')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end

      it 'returns true for ELEMENT nodes with the same tag name and same key' do
        node_one = Ruwi::Vdom.h('div', { key: 'test-key' })
        node_two = Ruwi::Vdom.h('div', { key: 'test-key' })

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end

      it 'returns false for ELEMENT nodes with the same tag name but different keys' do
        node_one = Ruwi::Vdom.h('div', { key: 'key1' })
        node_two = Ruwi::Vdom.h('div', { key: 'key2' })

        result = described_class.equal?(node_one, node_two)
        expect(result).to be false
      end

      it 'returns false for ELEMENT nodes with one having key and other having no key' do
        node_one = Ruwi::Vdom.h('div', { key: 'test-key' })
        node_two = Ruwi::Vdom.h('div')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be false
      end

      it 'returns true for ELEMENT nodes with both having nil keys' do
        node_one = Ruwi::Vdom.h('div', { key: nil })
        node_two = Ruwi::Vdom.h('div', { key: nil })

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end
    end

    context 'COMPONENT type nodes' do
      let(:dummy_component) { Class.new }
      let(:another_component) { Class.new }

      it 'returns true for COMPONENT nodes with the same component class' do
        node_one = Ruwi::Vdom.h(dummy_component)
        node_two = Ruwi::Vdom.h(dummy_component)

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end

      it 'returns false for COMPONENT nodes with different component classes' do
        node_one = Ruwi::Vdom.h(dummy_component)
        node_two = Ruwi::Vdom.h(another_component)

        result = described_class.equal?(node_one, node_two)
        expect(result).to be false
      end

      it 'returns true for COMPONENT nodes with the same component class and same key' do
        node_one = Ruwi::Vdom.h(dummy_component, { key: 'test-key' })
        node_two = Ruwi::Vdom.h(dummy_component, { key: 'test-key' })

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end

      it 'returns false for COMPONENT nodes with the same component class but different keys' do
        node_one = Ruwi::Vdom.h(dummy_component, { key: 'key1' })
        node_two = Ruwi::Vdom.h(dummy_component, { key: 'key2' })

        result = described_class.equal?(node_one, node_two)
        expect(result).to be false
      end

      it 'returns false for COMPONENT nodes with one having key and other having no key' do
        node_one = Ruwi::Vdom.h(dummy_component, { key: 'test-key' })
        node_two = Ruwi::Vdom.h(dummy_component)

        result = described_class.equal?(node_one, node_two)
        expect(result).to be false
      end
    end

    context 'TEXT type nodes' do
      it 'returns true for TEXT nodes with the same value' do
        node_one = Ruwi::Vdom.h_string('Hello')
        node_two = Ruwi::Vdom.h_string('Hello')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end

      it 'returns false for TEXT nodes with different values' do
        node_one = Ruwi::Vdom.h_string('Hello')
        node_two = Ruwi::Vdom.h_string('World')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be false
      end
    end

    context 'FRAGMENT type nodes' do
      it 'returns true for FRAGMENT nodes' do
        node_one = Ruwi::Vdom.h_fragment([])
        node_two = Ruwi::Vdom.h_fragment([])

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end
    end

    context 'Edge cases' do
      it 'returns true for ELEMENT nodes with empty string tag names' do
        node_one = Ruwi::Vdom.h('')
        node_two = Ruwi::Vdom.h('')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be true
      end

      it 'returns false for ELEMENT nodes with empty and non-empty tag names' do
        node_one = Ruwi::Vdom.h('')
        node_two = Ruwi::Vdom.h('div')

        result = described_class.equal?(node_one, node_two)
        expect(result).to be false
      end
    end
  end
end
