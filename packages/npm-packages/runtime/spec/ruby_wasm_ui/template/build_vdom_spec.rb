# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyWasmUi::Template::BuildVdom do
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
    let(:mock_attribute1) { double('attribute1') }
    let(:mock_attribute2) { double('attribute2') }

    context 'when parsing simple attributes' do
      let(:attributes_array) do
        [mock_attribute1, mock_attribute2]
      end

      before do
        allow(mock_attribute1).to receive(:[]).with(:name).and_return('class')
        allow(mock_attribute1).to receive(:[]).with(:value).and_return('container')

        allow(mock_attribute2).to receive(:[]).with(:name).and_return('id')
        allow(mock_attribute2).to receive(:[]).with(:value).and_return('main')
      end

      it 'returns formatted attribute string' do
        result = described_class.parse_attributes(attributes_array)
        expect(result).to eq(":class => 'container', :id => 'main'")
      end
    end

    context 'when parsing attributes with embedded scripts' do
      let(:attributes_array) { [mock_attribute1] }

      before do
        allow(mock_attribute1).to receive(:[]).with(:name).and_return('onclick')
        allow(mock_attribute1).to receive(:[]).with(:value).and_return('{handler}')
      end

      it 'extracts script without quotes' do
        result = described_class.parse_attributes(attributes_array)
        expect(result).to eq(':onclick => handler')
      end
    end

    context 'when parsing "on" attribute with embedded hash' do
      let(:attributes_array) { [mock_attribute1] }

      before do
        allow(mock_attribute1).to receive(:[]).with(:name).and_return('on')
        allow(mock_attribute1).to receive(:[]).with(:value).and_return('{click: ->(e) { handle_click.call(e) }, input: ->(e) { handle_input.call(e) }}')
      end

      it 'preserves hash structure for event handlers' do
        result = described_class.parse_attributes(attributes_array)
        expect(result).to eq(':on => {click: ->(e) { handle_click.call(e) }, input: ->(e) { handle_input.call(e) }}')
      end
    end

    context 'when no attributes exist' do
      let(:attributes_array) { [] }

      it 'returns empty string' do
        result = described_class.parse_attributes(attributes_array)
        expect(result).to eq('')
      end
    end
  end

  describe '.is_component?' do
    context 'when checking standard HTML elements' do
      it 'returns false for standard HTML elements' do
        expect(described_class.is_component?('div')).to be false
        expect(described_class.is_component?('span')).to be false
        expect(described_class.is_component?('p')).to be false
        expect(described_class.is_component?('input')).to be false
      end

      it 'returns false for uppercase standard HTML elements' do
        expect(described_class.is_component?('DIV')).to be false
        expect(described_class.is_component?('SPAN')).to be false
      end
    end

    context 'when checking custom component elements' do
      it 'returns true for kebab-case component names' do
        expect(described_class.is_component?('custom-component')).to be true
        expect(described_class.is_component?('my-button')).to be true
        expect(described_class.is_component?('search-field')).to be true
      end

      it 'returns true for single word component names' do
        expect(described_class.is_component?('customcomponent')).to be true
        expect(described_class.is_component?('mybutton')).to be true
      end
    end

    context 'when checking invalid elements' do
      it 'returns false for elements starting with numbers' do
        expect(described_class.is_component?('1component')).to be false
        expect(described_class.is_component?('2-button')).to be false
      end

      it 'returns false for elements starting with special characters' do
        expect(described_class.is_component?('_component')).to be false
        expect(described_class.is_component?('-button')).to be false
      end
    end
  end

  describe '.build' do
    let(:mock_elements) { double('elements') }
    let(:mock_text_node) { double('text_node') }
    let(:mock_element_node) { double('element_node') }
    let(:mock_template_node) { double('template_node') }
    let(:mock_component_node) { double('component_node') }
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
        allow(mock_elements).to receive(:[]).with(:length).and_return(1)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_text_node)
        allow(mock_text_node).to receive(:[]).with(:nodeType).and_return(3)
        allow(mock_text_node).to receive(:[]).with(:nodeValue).and_return('Hello')
      end

      it 'builds VDOM for text nodes' do
        result = described_class.build(mock_elements)
        expect(result).to eq('"Hello"')
      end
    end

    context 'when processing element nodes' do
      let(:mock_child_elements) { double('child_elements') }

      before do
        allow(mock_elements).to receive(:[]).with(:length).and_return(1)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_element_node)
        allow(mock_element_node).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_element_node).to receive(:[]).with(:tagName).and_return('DIV')
        allow(mock_element_node).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_element_node).to receive(:[]).with(:childNodes).and_return(mock_child_elements)

        # Mock attributes.to_a and :length for has_data_template_attribute?
        allow(mock_attributes).to receive(:to_a).and_return([])
        allow(mock_attributes).to receive(:[]).with(:length).and_return(0)

        # Mock empty children
        allow(mock_child_elements).to receive(:[]).with(:length).and_return(0)

        # Mock has_conditional_attribute? to return false
        allow(described_class).to receive(:has_conditional_attribute?).with(mock_element_node).and_return(false)
      end

      it 'builds VDOM for element nodes' do
        result = described_class.build(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h('div', {}, [])")
      end
    end

    context 'when processing template (fragment) nodes' do
      let(:mock_content) { double('content') }
      let(:mock_child_nodes) { double('child_nodes') }

      before do
        allow(mock_elements).to receive(:[]).with(:length).and_return(1)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_template_node)
        allow(mock_template_node).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_template_node).to receive(:[]).with(:tagName).and_return('TEMPLATE')
        allow(mock_template_node).to receive(:[]).with(:content).and_return(mock_content)
        allow(mock_content).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)

        # Mock empty children
        allow(mock_child_nodes).to receive(:[]).with(:length).and_return(0)

        # Mock has_conditional_attribute? to return false
        allow(described_class).to receive(:has_conditional_attribute?).with(mock_template_node).and_return(false)
      end

      it 'builds VDOM for fragment nodes' do
        result = described_class.build(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h_fragment([])")
      end
    end

    context 'when processing div elements with data-template attribute' do
      let(:mock_div_template_node) { double('div_template_node') }
      let(:mock_child_nodes) { double('child_nodes') }
      let(:mock_attributes) { double('attributes') }
      let(:mock_attribute) { double('attribute') }

      before do
        allow(mock_elements).to receive(:[]).with(:length).and_return(1)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_div_template_node)
        allow(mock_div_template_node).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_div_template_node).to receive(:[]).with(:tagName).and_return('DIV')
        allow(mock_div_template_node).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)
        allow(mock_div_template_node).to receive(:[]).with(:attributes).and_return(mock_attributes)

        # Mock data-template attribute
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('data-template')

        # Mock empty children
        allow(mock_child_nodes).to receive(:[]).with(:length).and_return(0)

        # Mock has_data_template_attribute? method
        allow(described_class).to receive(:has_data_template_attribute?).with(mock_div_template_node).and_return(true)

        # Mock has_conditional_attribute? to return false
        allow(described_class).to receive(:has_conditional_attribute?).with(mock_div_template_node).and_return(false)
      end

      it 'builds VDOM for div elements with data-template attribute as fragments' do
        result = described_class.build(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h_fragment([])")
      end

      it 'uses childNodes directly for div elements with data-template' do
        expect(mock_div_template_node).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)
        expect(mock_div_template_node).not_to receive(:[]).with(:content)
        described_class.build(mock_elements)
      end
    end

    context 'when processing component nodes' do
      let(:mock_child_elements) { double('child_elements') }

      before do
        allow(mock_elements).to receive(:[]).with(:length).and_return(1)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_component_node)
        allow(mock_component_node).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_component_node).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_component_node).to receive(:[]).with(:childNodes).and_return(mock_child_elements)

        # Mock empty children
        allow(mock_child_elements).to receive(:[]).with(:length).and_return(0)

        # Mock attributes.to_a
        allow(mock_attributes).to receive(:to_a).and_return([])

        # Mock has_conditional_attribute? to return false for regular component tests
        allow(mock_attributes).to receive(:[]).with(:length).and_return(0)
      end

      it 'builds VDOM for kebab-case component' do
        allow(mock_component_node).to receive(:[]).with(:tagName).and_return('custom-component')
        result = described_class.build(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h(CustomComponent, {}, [])")
      end

      it 'builds VDOM for multi-word kebab-case component' do
        allow(mock_component_node).to receive(:[]).with(:tagName).and_return('my-custom-button')
        result = described_class.build(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h(MyCustomButton, {}, [])")
      end

      it 'builds VDOM for single word component' do
        allow(mock_component_node).to receive(:[]).with(:tagName).and_return('mycomponent')
        result = described_class.build(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h(Mycomponent, {}, [])")
      end
    end

    context 'when processing components with conditional attributes' do
      let(:mock_component_elements) { double('component_elements') }
      let(:mock_component_with_conditional) { double('component_with_conditional') }
      let(:mock_component_attributes) { double('component_attributes') }
      let(:mock_conditional_attribute) { double('conditional_attribute') }

      before do
        allow(mock_component_elements).to receive(:[]).with(:length).and_return(1)
        allow(mock_component_elements).to receive(:[]).with(0).and_return(mock_component_with_conditional)
        allow(mock_component_with_conditional).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_component_with_conditional).to receive(:[]).with(:tagName).and_return('custom-component')
        allow(mock_component_with_conditional).to receive(:[]).with(:attributes).and_return(mock_component_attributes)

        # Mock conditional attribute
        allow(mock_component_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_component_attributes).to receive(:[]).with(0).and_return(mock_conditional_attribute)
        allow(mock_conditional_attribute).to receive(:[]).with(:name).and_return('r-if')
        allow(mock_conditional_attribute).to receive(:[]).with(:value).and_return('condition')

        # Mock build_conditional_group method
        allow(described_class).to receive(:build_conditional_group)
          .with(mock_component_elements, 0)
          .and_return(['conditional_code', 1])
      end

      it 'processes conditional attributes on components' do
        result = described_class.build(mock_component_elements)
        expect(result).to eq("conditional_code")
        expect(described_class).to have_received(:build_conditional_group)
      end
    end
  end

  describe '.has_data_template_attribute?' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }
    let(:mock_attribute) { double('attribute') }

    context 'when element has data-template attribute' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('data-template')
      end

      it 'returns true' do
        result = described_class.has_data_template_attribute?(mock_element)
        expect(result).to be true
      end
    end

    context 'when element has other attributes but not data-template' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(2)

        mock_attribute1 = double('attribute1')
        mock_attribute2 = double('attribute2')
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute1)
        allow(mock_attributes).to receive(:[]).with(1).and_return(mock_attribute2)
        allow(mock_attribute1).to receive(:[]).with(:name).and_return('class')
        allow(mock_attribute2).to receive(:[]).with(:name).and_return('id')
      end

      it 'returns false' do
        result = described_class.has_data_template_attribute?(mock_element)
        expect(result).to be false
      end
    end

    context 'when element has no attributes' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(nil)
      end

      it 'returns false' do
        result = described_class.has_data_template_attribute?(mock_element)
        expect(result).to be false
      end
    end

    context 'when element has empty attributes' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(0)
      end

      it 'returns false' do
        result = described_class.has_data_template_attribute?(mock_element)
        expect(result).to be false
      end
    end

    context 'when element has data-template among multiple attributes' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(3)

        mock_attribute1 = double('attribute1')
        mock_attribute2 = double('attribute2')
        mock_attribute3 = double('attribute3')
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute1)
        allow(mock_attributes).to receive(:[]).with(1).and_return(mock_attribute2)
        allow(mock_attributes).to receive(:[]).with(2).and_return(mock_attribute3)
        allow(mock_attribute1).to receive(:[]).with(:name).and_return('class')
        allow(mock_attribute2).to receive(:[]).with(:name).and_return('data-template')
        allow(mock_attribute3).to receive(:[]).with(:name).and_return('id')
      end

      it 'returns true' do
        result = described_class.has_data_template_attribute?(mock_element)
        expect(result).to be true
      end
    end
  end

  describe '.has_conditional_attribute?' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }

    context 'when element has r-if attribute' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        mock_attribute = double('attribute')
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-if')
      end

      it 'returns true' do
        result = described_class.has_conditional_attribute?(mock_element)
        expect(result).to be true
      end
    end

    context 'when element has r-elsif attribute' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        mock_attribute = double('attribute')
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-elsif')
      end

      it 'returns true' do
        result = described_class.has_conditional_attribute?(mock_element)
        expect(result).to be true
      end
    end

    context 'when element has r-else attribute' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        mock_attribute = double('attribute')
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-else')
      end

      it 'returns true' do
        result = described_class.has_conditional_attribute?(mock_element)
        expect(result).to be true
      end
    end

    context 'when element has no conditional attributes' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        mock_attribute = double('attribute')
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('class')
      end

      it 'returns false' do
        result = described_class.has_conditional_attribute?(mock_element)
        expect(result).to be false
      end
    end

    context 'when element has no attributes' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(nil)
      end

      it 'returns false' do
        result = described_class.has_conditional_attribute?(mock_element)
        expect(result).to be false
      end
    end
  end

  describe '.get_conditional_type' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }

    it 'returns r-if for r-if attribute' do
      allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
      mock_attribute = double('attribute')
      allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
      allow(mock_attribute).to receive(:[]).with(:name).and_return('r-if')

      result = described_class.get_conditional_type(mock_element)
      expect(result).to eq('r-if')
    end

    it 'returns r-elsif for r-elsif attribute' do
      allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
      mock_attribute = double('attribute')
      allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
      allow(mock_attribute).to receive(:[]).with(:name).and_return('r-elsif')

      result = described_class.get_conditional_type(mock_element)
      expect(result).to eq('r-elsif')
    end

    it 'returns r-else for r-else attribute' do
      allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
      mock_attribute = double('attribute')
      allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
      allow(mock_attribute).to receive(:[]).with(:name).and_return('r-else')

      result = described_class.get_conditional_type(mock_element)
      expect(result).to eq('r-else')
    end
  end

  describe '.get_conditional_expression' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }

    it 'extracts expression from r-if attribute' do
      allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
      mock_attribute = double('attribute')
      allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
      allow(mock_attribute).to receive(:[]).with(:name).and_return('r-if')
      allow(mock_attribute).to receive(:[]).with(:value).and_return('{condition}')

      result = described_class.get_conditional_expression(mock_element)
      expect(result).to eq('condition')
    end

    it 'extracts expression from r-elsif attribute' do
      allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
      mock_attribute = double('attribute')
      allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
      allow(mock_attribute).to receive(:[]).with(:name).and_return('r-elsif')
      allow(mock_attribute).to receive(:[]).with(:value).and_return('{another_condition}')

      result = described_class.get_conditional_expression(mock_element)
      expect(result).to eq('another_condition')
    end

    it 'returns true for r-else attribute' do
      allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
      mock_attribute = double('attribute')
      allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
      allow(mock_attribute).to receive(:[]).with(:name).and_return('r-else')
      allow(mock_attribute).to receive(:[]).with(:value).and_return('')

      result = described_class.get_conditional_expression(mock_element)
      expect(result).to eq('true')
    end
  end

  describe '.filter_conditional_attributes' do
    let(:mock_attributes) { double('attributes') }

    it 'filters out conditional attributes' do
      mock_attr1 = double('attr1')
      mock_attr2 = double('attr2')
      mock_attr3 = double('attr3')

      allow(mock_attributes).to receive(:[]).with(:length).and_return(3)
      allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attr1)
      allow(mock_attributes).to receive(:[]).with(1).and_return(mock_attr2)
      allow(mock_attributes).to receive(:[]).with(2).and_return(mock_attr3)

      allow(mock_attr1).to receive(:[]).with(:name).and_return('class')
      allow(mock_attr2).to receive(:[]).with(:name).and_return('r-if')
      allow(mock_attr3).to receive(:[]).with(:name).and_return('id')

      result = described_class.filter_conditional_attributes(mock_attributes)
      expect(result).to eq([mock_attr1, mock_attr3])
    end

    it 'filters out data-template attribute' do
      mock_attr1 = double('attr1')
      mock_attr2 = double('attr2')

      allow(mock_attributes).to receive(:[]).with(:length).and_return(2)
      allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attr1)
      allow(mock_attributes).to receive(:[]).with(1).and_return(mock_attr2)

      allow(mock_attr1).to receive(:[]).with(:name).and_return('class')
      allow(mock_attr2).to receive(:[]).with(:name).and_return('data-template')

      result = described_class.filter_conditional_attributes(mock_attributes)
      expect(result).to eq([mock_attr1])
    end
  end

  describe '.build_single_conditional_content' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }
    let(:mock_child_nodes) { double('child_nodes') }

    before do
      allow(mock_element).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)
      allow(mock_child_nodes).to receive(:[]).with(:length).and_return(0)
      allow(described_class).to receive(:filter_conditional_attributes).with(mock_attributes).and_return([])
      allow(described_class).to receive(:parse_attributes).with([]).and_return('')
      # Mock for has_data_template_attribute? method
      allow(mock_attributes).to receive(:[]).with(:length).and_return(0)
    end

    context 'when element is a regular HTML element' do
      before do
        allow(mock_element).to receive(:[]).with(:tagName).and_return('DIV')
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      end

      it 'builds VDOM for regular element' do
        result = described_class.build_single_conditional_content(mock_element)
        expect(result).to eq("RubyWasmUi::Vdom.h('div', {}, [])")
      end
    end

    context 'when element is a component' do
      before do
        allow(mock_element).to receive(:[]).with(:tagName).and_return('CUSTOM-COMPONENT')
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      end

      it 'builds VDOM for component with PascalCase name' do
        result = described_class.build_single_conditional_content(mock_element)
        expect(result).to eq("RubyWasmUi::Vdom.h(CustomComponent, {}, [])")
      end
    end

    context 'when element is a multi-word component' do
      before do
        allow(mock_element).to receive(:[]).with(:tagName).and_return('MY-CUSTOM-BUTTON')
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      end

      it 'builds VDOM for multi-word component with PascalCase name' do
        result = described_class.build_single_conditional_content(mock_element)
        expect(result).to eq("RubyWasmUi::Vdom.h(MyCustomButton, {}, [])")
      end
    end

    context 'when element is a template' do
      let(:mock_content) { double('content') }
      let(:mock_content_child_nodes) { double('content_child_nodes') }

      before do
        allow(mock_element).to receive(:[]).with(:tagName).and_return('TEMPLATE')
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_element).to receive(:[]).with(:content).and_return(mock_content)
        allow(mock_content).to receive(:[]).with(:childNodes).and_return(mock_content_child_nodes)
        allow(mock_content_child_nodes).to receive(:[]).with(:length).and_return(0)
      end

      it 'builds VDOM fragment for template element' do
        result = described_class.build_single_conditional_content(mock_element)
        expect(result).to eq("RubyWasmUi::Vdom.h_fragment([])")
      end
    end
  end

  describe '.build_conditional_group' do
    let(:mock_elements) { double('elements') }
    let(:mock_element_if) { double('element_if') }
    let(:mock_element_elsif) { double('element_elsif') }
    let(:mock_element_else) { double('element_else') }
    let(:mock_attributes_if) { double('attributes_if') }
    let(:mock_attributes_elsif) { double('attributes_elsif') }
    let(:mock_attributes_else) { double('attributes_else') }
    let(:mock_node_constants) { double('Node') }

    before do
      # Mock JS.global[:Node] constants
      js_mock = double('JS')
      allow(js_mock).to receive(:global).and_return({ Node: mock_node_constants })
      stub_const('JS', js_mock)
      allow(mock_node_constants).to receive(:[]).with(:TEXT_NODE).and_return(3)
      allow(mock_node_constants).to receive(:[]).with(:ELEMENT_NODE).and_return(1)
    end

    context 'when processing r-if, r-elsif, r-else chain' do
      before do
        allow(mock_elements).to receive(:[]).with(:length).and_return(3)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_element_if)
        allow(mock_elements).to receive(:[]).with(1).and_return(mock_element_elsif)
        allow(mock_elements).to receive(:[]).with(2).and_return(mock_element_else)

        # Mock r-if element
        allow(mock_element_if).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_element_if).to receive(:[]).with(:attributes).and_return(mock_attributes_if)
        allow(mock_attributes_if).to receive(:[]).with(:length).and_return(1)
        mock_attr_if = double('attr_if')
        allow(mock_attributes_if).to receive(:[]).with(0).and_return(mock_attr_if)
        allow(mock_attr_if).to receive(:[]).with(:name).and_return('r-if')
        allow(mock_attr_if).to receive(:[]).with(:value).and_return('condition1')

        # Mock r-elsif element
        allow(mock_element_elsif).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_element_elsif).to receive(:[]).with(:attributes).and_return(mock_attributes_elsif)
        allow(mock_attributes_elsif).to receive(:[]).with(:length).and_return(1)
        mock_attr_elsif = double('attr_elsif')
        allow(mock_attributes_elsif).to receive(:[]).with(0).and_return(mock_attr_elsif)
        allow(mock_attr_elsif).to receive(:[]).with(:name).and_return('r-elsif')
        allow(mock_attr_elsif).to receive(:[]).with(:value).and_return('condition2')

        # Mock r-else element
        allow(mock_element_else).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_element_else).to receive(:[]).with(:attributes).and_return(mock_attributes_else)
        allow(mock_attributes_else).to receive(:[]).with(:length).and_return(1)
        mock_attr_else = double('attr_else')
        allow(mock_attributes_else).to receive(:[]).with(0).and_return(mock_attr_else)
        allow(mock_attr_else).to receive(:[]).with(:name).and_return('r-else')
        allow(mock_attr_else).to receive(:[]).with(:value).and_return('')

        # Mock build_single_conditional_content
        allow(described_class).to receive(:build_single_conditional_content)
          .with(mock_element_if).and_return('content_if')
        allow(described_class).to receive(:build_single_conditional_content)
          .with(mock_element_elsif).and_return('content_elsif')
        allow(described_class).to receive(:build_single_conditional_content)
          .with(mock_element_else).and_return('content_else')
      end

      it 'builds complete conditional chain' do
        result, next_index = described_class.build_conditional_group(mock_elements, 0)

        expected = [
          'if condition1',
          '  content_if',
          'elsif condition2',
          '  content_elsif',
          'else',
          '  content_else',
          'end'
        ].join("\n")

        expect(result).to eq(expected)
        expect(next_index).to eq(3)
      end
    end

    context 'when processing only r-if without else' do
      before do
        allow(mock_elements).to receive(:[]).with(:length).and_return(1)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_element_if)

        # Mock r-if element
        allow(mock_element_if).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_element_if).to receive(:[]).with(:attributes).and_return(mock_attributes_if)
        allow(mock_attributes_if).to receive(:[]).with(:length).and_return(1)
        mock_attr_if = double('attr_if')
        allow(mock_attributes_if).to receive(:[]).with(0).and_return(mock_attr_if)
        allow(mock_attr_if).to receive(:[]).with(:name).and_return('r-if')
        allow(mock_attr_if).to receive(:[]).with(:value).and_return('condition')

        # Mock build_single_conditional_content
        allow(described_class).to receive(:build_single_conditional_content)
          .with(mock_element_if).and_return('content')
      end

      it 'builds conditional with default else clause' do
        result, next_index = described_class.build_conditional_group(mock_elements, 0)

        expected = [
          'if condition',
          '  content',
          'else',
          '  RubyWasmUi::Vdom.h_fragment([])',
          'end'
        ].join("\n")

        expect(result).to eq(expected)
        expect(next_index).to eq(1)
      end
    end
  end

  describe '.build_fragment' do
    let(:mock_element) { double('element') }
    let(:mock_content) { double('content') }
    let(:mock_child_nodes) { double('child_nodes') }

    context 'when element is a template with content property' do
      before do
        allow(mock_element).to receive(:[]).with(:content).and_return(mock_content)
        allow(mock_content).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)
        allow(mock_child_nodes).to receive(:[]).with(:length).and_return(0)
      end

      it 'builds fragment using content childNodes' do
        result = described_class.build_fragment(mock_element, 'template')
        expect(result).to eq("RubyWasmUi::Vdom.h_fragment([])")
      end
    end

    context 'when element is a div with data-template' do
      before do
        allow(mock_element).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)
        allow(mock_child_nodes).to receive(:[]).with(:length).and_return(0)
      end

      it 'builds fragment using direct childNodes' do
        result = described_class.build_fragment(mock_element, 'div')
        expect(result).to eq("RubyWasmUi::Vdom.h_fragment([])")
      end
    end
  end

  describe '.build_component' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }
    let(:mock_child_nodes) { double('child_nodes') }

    before do
      allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      allow(mock_element).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)
      allow(mock_attributes).to receive(:to_a).and_return([])
      allow(mock_child_nodes).to receive(:[]).with(:length).and_return(0)
      allow(described_class).to receive(:parse_attributes).with([]).and_return('')
    end

    it 'builds component with PascalCase name conversion' do
      result = described_class.build_component(mock_element, 'custom-component')
      expect(result).to eq("RubyWasmUi::Vdom.h(CustomComponent, {}, [])")
    end

    it 'builds multi-word component with PascalCase name conversion' do
      result = described_class.build_component(mock_element, 'my-custom-button')
      expect(result).to eq("RubyWasmUi::Vdom.h(MyCustomButton, {}, [])")
    end

    it 'builds single word component' do
      result = described_class.build_component(mock_element, 'mycomponent')
      expect(result).to eq("RubyWasmUi::Vdom.h(Mycomponent, {}, [])")
    end
  end

  describe '.build_element' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }
    let(:mock_child_nodes) { double('child_nodes') }

    before do
      allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      allow(mock_element).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)
      allow(mock_attributes).to receive(:to_a).and_return([])
      allow(mock_child_nodes).to receive(:[]).with(:length).and_return(0)
      allow(described_class).to receive(:parse_attributes).with([]).and_return('')
    end

    it 'builds regular HTML element' do
      result = described_class.build_element(mock_element, 'div')
      expect(result).to eq("RubyWasmUi::Vdom.h('div', {}, [])")
    end

    it 'builds HTML element with lowercase tag name' do
      result = described_class.build_element(mock_element, 'span')
      expect(result).to eq("RubyWasmUi::Vdom.h('span', {}, [])")
    end
  end
end
