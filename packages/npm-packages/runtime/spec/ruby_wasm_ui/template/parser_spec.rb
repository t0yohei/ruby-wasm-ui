# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyWasmUi::Template::Parser do
  describe '.embed_script?' do
    context 'when the document contains embedded script' do
      it 'returns true for single variable' do
        result = described_class.embed_script?('{variable}')
        expect(result).to be true
      end

      it 'returns true for complex expression' do
        result = described_class.embed_script?('{state[:current_todo]}')
        expect(result).to be true
      end

      it 'returns true for lambda expression' do
        result = described_class.embed_script?('{->(e) { emit.call("action", e[:target][:value]) }}')
        expect(result).to be true
      end

      it 'returns true for expression with spaces' do
        result = described_class.embed_script?('{ variable_name }')
        expect(result).to be true
      end
    end

    context 'when the document does not contain embedded script' do
      it 'returns false for plain text' do
        result = described_class.embed_script?('Hello World')
        expect(result).to be false
      end

      it 'returns false for empty string' do
        result = described_class.embed_script?('')
        expect(result).to be false
      end

      it 'returns false for single bracket' do
        result = described_class.embed_script?('{incomplete')
        expect(result).to be false
      end

      it 'returns false for empty brackets' do
        result = described_class.embed_script?('{}')
        expect(result).to be false
      end
    end
  end

  describe '.get_embed_script' do
    context 'when extracting embedded script' do
      it 'extracts simple variable' do
        result = described_class.get_embed_script('{variable}')
        expect(result).to eq('variable')
      end

      it 'extracts complex expression' do
        result = described_class.get_embed_script('{state[:current_todo]}')
        expect(result).to eq('state[:current_todo]')
      end

      it 'extracts lambda expression' do
        script = '{->(e) { emit.call("action", e[:target][:value]) }}'
        result = described_class.get_embed_script(script)
        expect(result).to eq('->(e) { emit.call("action", e[:target][:value]) }')
      end

      it 'extracts first occurrence when multiple brackets exist' do
        result = described_class.get_embed_script('{first} and {second}')
        expect(result).to eq('first} and {second')
      end

      it 'handles expressions with spaces' do
        result = described_class.get_embed_script('{ variable_name }')
        expect(result).to eq(' variable_name ')
      end
    end
  end

  describe '.parse_text_node' do
    let(:mock_element) { double('element') }

    context 'when text node contains regular text' do
      before do
        allow(mock_element).to receive(:[]).with(:nodeValue).and_return('Hello World')
      end

      it 'returns quoted string for regular text' do
        result = described_class.parse_text_node(mock_element)
        expect(result).to eq('"Hello World"')
      end
    end

    context 'when text node contains embedded script' do
      it 'handles simple text with embedded script' do
        allow(mock_element).to receive(:[]).with(:nodeValue).and_return('test {state[:count]}')
        result = described_class.parse_text_node(mock_element)
        expect(result).to eq('"test #{state[:count]}"')
      end

      it 'handles embedded script with expression' do
        allow(mock_element).to receive(:[]).with(:nodeValue).and_return('test {state[:count] + 1}')
        result = described_class.parse_text_node(mock_element)
        expect(result).to eq('"test #{state[:count] + 1}"')
      end

      it 'handles text with embedded script and trailing text' do
        allow(mock_element).to receive(:[]).with(:nodeValue).and_return('test {state[:count]} test')
        result = described_class.parse_text_node(mock_element)
        expect(result).to eq('"test #{state[:count]} test"')
      end

      it 'handles multiple embedded scripts' do
        allow(mock_element).to receive(:[]).with(:nodeValue).and_return('test {state[:count]} test {state[:count]} test')
        result = described_class.parse_text_node(mock_element)
        expect(result).to eq('"test #{state[:count]} test #{state[:count]} test"')
      end
    end

    context 'when text node is empty or whitespace only' do
      it 'returns nil for empty string' do
        allow(mock_element).to receive(:[]).with(:nodeValue).and_return('')
        result = described_class.parse_text_node(mock_element)
        expect(result).to be_nil
      end

      it 'returns nil for whitespace only' do
        allow(mock_element).to receive(:[]).with(:nodeValue).and_return("   \n  ")
        result = described_class.parse_text_node(mock_element)
        expect(result).to be_nil
      end
    end
  end

  describe '.parse_attributes' do
    let(:mock_attributes) { double('attributes') }
    let(:mock_attribute1) { double('attribute1') }
    let(:mock_attribute2) { double('attribute2') }

    context 'when parsing simple attributes' do
      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(2)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute1)
        allow(mock_attributes).to receive(:[]).with(1).and_return(mock_attribute2)

        allow(mock_attribute1).to receive(:[]).with(:name).and_return('class')
        allow(mock_attribute1).to receive(:[]).with(:value).and_return('container')

        allow(mock_attribute2).to receive(:[]).with(:name).and_return('id')
        allow(mock_attribute2).to receive(:[]).with(:value).and_return('main')
      end

      it 'returns formatted attribute string' do
        result = described_class.parse_attributes(mock_attributes)
        expect(result).to eq(":class => 'container', :id => 'main'")
      end
    end

    context 'when parsing attributes with embedded scripts' do
      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute1)

        allow(mock_attribute1).to receive(:[]).with(:name).and_return('onclick')
        allow(mock_attribute1).to receive(:[]).with(:value).and_return('{handler}')
      end

      it 'extracts script without quotes' do
        result = described_class.parse_attributes(mock_attributes)
        expect(result).to eq(':onclick => handler')
      end
    end

    context 'when no attributes exist' do
      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(0)
      end

      it 'returns empty string' do
        result = described_class.parse_attributes(mock_attributes)
        expect(result).to eq('')
      end
    end
  end

  describe '.build_vdom' do
    let(:mock_elements) { double('elements') }
    let(:mock_text_node) { double('text_node') }
    let(:mock_element_node) { double('element_node') }
    let(:mock_template_node) { double('template_node') }
    let(:mock_node_constants) { double('Node') }
    let(:mock_attributes) { double('attributes') }

    before do
      # Mock JS.global[:Node] constants
      js_mock = double('JS')
      allow(js_mock).to receive(:global).and_return({ Node: mock_node_constants })
      stub_const('JS', js_mock)
      allow(mock_node_constants).to receive(:[]).with(:TEXT_NODE).and_return(3)
      allow(mock_node_constants).to receive(:[]).with(:ELEMENT_NODE).and_return(1)
    end

    context 'when processing text nodes' do
      before do
        allow(mock_elements).to receive(:forEach).and_yield(mock_text_node)
        allow(mock_text_node).to receive(:[]).with(:nodeType).and_return(3)
        allow(mock_text_node).to receive(:[]).with(:nodeValue).and_return('Hello')
      end

      it 'builds VDOM for text nodes' do
        result = described_class.build_vdom(mock_elements)
        expect(result).to eq('"Hello"')
      end
    end

    context 'when processing element nodes' do
      let(:mock_child_elements) { double('child_elements') }

      before do
        allow(mock_elements).to receive(:forEach).and_yield(mock_element_node)
        allow(mock_element_node).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_element_node).to receive(:[]).with(:tagName).and_return('DIV')
        allow(mock_element_node).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_element_node).to receive(:[]).with(:childNodes).and_return(mock_child_elements)

        # Mock attributes
        allow(mock_attributes).to receive(:[]).with(:length).and_return(0)

        # Mock empty children
        allow(mock_child_elements).to receive(:forEach)
      end

      it 'builds VDOM for element nodes' do
        result = described_class.build_vdom(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h('div', {}, [])")
      end
    end

    context 'when processing template (fragment) nodes' do
      let(:mock_content) { double('content') }
      let(:mock_child_nodes) { double('child_nodes') }

      before do
        allow(mock_elements).to receive(:forEach).and_yield(mock_template_node)
        allow(mock_template_node).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_template_node).to receive(:[]).with(:tagName).and_return('TEMPLATE')
        allow(mock_template_node).to receive(:[]).with(:content).and_return(mock_content)
        allow(mock_content).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)

        # Mock empty children
        allow(mock_child_nodes).to receive(:forEach)
      end

      it 'builds VDOM for fragment nodes' do
        result = described_class.build_vdom(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h_fragment([])")
      end
    end
  end

  describe '.parse' do
    let(:mock_parser) { double('parser') }
    let(:mock_document) { double('document') }
    let(:mock_body) { double('body') }
    let(:mock_child_nodes) { double('child_nodes') }

    before do
      # Mock JS.eval and DOMParser
      js_mock = double('JS')
      allow(js_mock).to receive(:eval).with('return new DOMParser()').and_return(mock_parser)
      allow(js_mock).to receive(:try_convert).with('template_string').and_return('template_string')
      stub_const('JS', js_mock)

      allow(mock_parser).to receive(:call).with(:parseFromString, 'template_string', 'text/html').and_return(mock_document)
      allow(mock_document).to receive(:getElementsByTagName).with('body').and_return([mock_body])
      allow(mock_body).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)

      # Mock empty child nodes
      allow(mock_child_nodes).to receive(:forEach)
    end

    it 'parses HTML template and returns VDOM string' do
      result = described_class.parse('template_string')
      expect(result).to eq('')
    end
  end
end
