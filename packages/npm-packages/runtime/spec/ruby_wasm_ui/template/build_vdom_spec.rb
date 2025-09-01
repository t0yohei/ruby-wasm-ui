# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyWasmUi::Template::BuildVdom do
  let(:mock_elements) { double('elements') }
  let(:mock_element_node) { double('element_node') }
  let(:mock_template_node) { double('template_node') }
  let(:mock_attributes) { double('attributes') }
  let(:mock_node_constants) { double('Node') }

  before do
    # Mock JS.global[:Node] constants
    js_mock = double('JS')
    allow(js_mock).to receive(:global).and_return({ Node: mock_node_constants })
    stub_const('JS', js_mock)
    allow(mock_node_constants).to receive(:[]).with(:TEXT_NODE).and_return(3)
    allow(mock_node_constants).to receive(:[]).with(:ELEMENT_NODE).and_return(1)
  end

  describe '.build' do
    context 'when processing text nodes' do
      let(:mock_text_node) { double('text_node') }

      before do
        allow(mock_elements).to receive(:[]).with(:length).and_return(1)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_text_node)
        allow(mock_text_node).to receive(:[]).with(:nodeType).and_return(3)
        allow(mock_text_node).to receive(:[]).with(:nodeValue).and_return('Hello World')
      end

      it 'parses text nodes correctly' do
        result = described_class.build(mock_elements)
        expect(result).to eq('"Hello World"')
      end
    end

    context 'when processing text nodes with embedded scripts' do
      let(:mock_text_node) { double('text_node') }

      before do
        allow(mock_elements).to receive(:[]).with(:length).and_return(1)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_text_node)
        allow(mock_text_node).to receive(:[]).with(:nodeType).and_return(3)
        allow(mock_text_node).to receive(:[]).with(:nodeValue).and_return('Count: {state[:count]}')
      end

      it 'converts embedded scripts to Ruby interpolation' do
        result = described_class.build(mock_elements)
        expect(result).to eq('"Count: #{state[:count]}"')
      end
    end

    context 'when processing empty text nodes' do
      let(:mock_text_node) { double('text_node') }

      before do
        allow(mock_elements).to receive(:[]).with(:length).and_return(1)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_text_node)
        allow(mock_text_node).to receive(:[]).with(:nodeType).and_return(3)
        allow(mock_text_node).to receive(:[]).with(:nodeValue).and_return('   ')
      end

      it 'ignores empty or whitespace-only text nodes' do
        result = described_class.build(mock_elements)
        expect(result).to eq('')
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
        allow(RubyWasmUi::Template::BuildConditionalGroup).to receive(:has_conditional_attribute?).with(mock_element_node).and_return(false)
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
        allow(RubyWasmUi::Template::BuildConditionalGroup).to receive(:has_conditional_attribute?).with(mock_template_node).and_return(false)
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

        # Mock has_conditional_attribute? to return false
        allow(RubyWasmUi::Template::BuildConditionalGroup).to receive(:has_conditional_attribute?).with(mock_div_template_node).and_return(false)
      end

      it 'builds VDOM for div elements with data-template attribute as fragments' do
        result = described_class.build(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h_fragment([])")
      end

      it 'uses childNodes directly for div elements with data-template' do
        described_class.build(mock_elements)
        expect(mock_div_template_node).to have_received(:[]).with(:childNodes)
      end
    end

    context 'when processing components' do
      let(:mock_component_element) { double('component_element') }
      let(:mock_component_attributes) { double('component_attributes') }
      let(:mock_component_children) { double('component_children') }

      before do
        allow(mock_elements).to receive(:[]).with(:length).and_return(1)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_component_element)
        allow(mock_component_element).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_component_element).to receive(:[]).with(:tagName).and_return('CUSTOM-COMPONENT')
        allow(mock_component_element).to receive(:[]).with(:attributes).and_return(mock_component_attributes)
        allow(mock_component_element).to receive(:[]).with(:childNodes).and_return(mock_component_children)

        # Mock attributes and children
        allow(mock_component_attributes).to receive(:to_a).and_return([])
        allow(mock_component_children).to receive(:[]).with(:length).and_return(0)

        # Mock has_conditional_attribute? to return false
        allow(RubyWasmUi::Template::BuildConditionalGroup).to receive(:has_conditional_attribute?).with(mock_component_element).and_return(false)
      end

      it 'builds VDOM for components with PascalCase names' do
        result = described_class.build(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h(CustomComponent, {}, [])")
      end
    end

    context 'when processing components with conditional attributes' do
      let(:mock_component_elements) { double('component_elements') }
      let(:mock_component_element) { double('component_element') }
      let(:mock_component_attributes) { double('component_attributes') }
      let(:mock_conditional_attribute) { double('conditional_attribute') }

      before do
        allow(mock_component_elements).to receive(:[]).with(:length).and_return(1)
        allow(mock_component_elements).to receive(:[]).with(0).and_return(mock_component_element)
        allow(mock_component_element).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_component_element).to receive(:[]).with(:tagName).and_return('CUSTOM-COMPONENT')
        allow(mock_component_element).to receive(:[]).with(:attributes).and_return(mock_component_attributes)

        # Mock has_conditional_attribute? to return true
        allow(RubyWasmUi::Template::BuildConditionalGroup).to receive(:has_conditional_attribute?).with(mock_component_element).and_return(true)

        # Mock conditional attribute
        allow(mock_component_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_component_attributes).to receive(:[]).with(0).and_return(mock_conditional_attribute)
        allow(mock_conditional_attribute).to receive(:[]).with(:name).and_return('r-if')
        allow(mock_conditional_attribute).to receive(:[]).with(:value).and_return('condition')

        # Mock build_conditional_group method
        allow(RubyWasmUi::Template::BuildConditionalGroup).to receive(:build_conditional_group)
          .with(mock_component_elements, 0)
          .and_return(['conditional_code', 1])
      end

      it 'processes conditional attributes on components' do
        result = described_class.build(mock_component_elements)
        expect(result).to eq("conditional_code")
        expect(RubyWasmUi::Template::BuildConditionalGroup).to have_received(:build_conditional_group)
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

    context 'when element has no data-template attribute' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('class')
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
  end

  describe '.parse_text_node' do
    let(:mock_text_node) { double('text_node') }

    context 'when text contains embedded script' do
      before do
        allow(mock_text_node).to receive(:[]).with(:nodeValue).and_return('Hello {name}!')
      end

      it 'converts to Ruby string interpolation' do
        result = described_class.parse_text_node(mock_text_node)
        expect(result).to eq('"Hello #{name}!"')
      end
    end

    context 'when text contains multiple embedded scripts' do
      before do
        allow(mock_text_node).to receive(:[]).with(:nodeValue).and_return('{greeting} {name}!')
      end

      it 'converts all embedded scripts to Ruby interpolation' do
        result = described_class.parse_text_node(mock_text_node)
        expect(result).to eq('"#{greeting} #{name}!"')
      end
    end

    context 'when text has no embedded script' do
      before do
        allow(mock_text_node).to receive(:[]).with(:nodeValue).and_return('Plain text')
      end

      it 'returns quoted string' do
        result = described_class.parse_text_node(mock_text_node)
        expect(result).to eq('"Plain text"')
      end
    end

    context 'when text is empty or whitespace only' do
      before do
        allow(mock_text_node).to receive(:[]).with(:nodeValue).and_return('   ')
      end

      it 'returns nil' do
        result = described_class.parse_text_node(mock_text_node)
        expect(result).to be_nil
      end
    end
  end

  describe '.parse_attributes' do
    let(:mock_attribute1) { double('attribute1') }
    let(:mock_attribute2) { double('attribute2') }
    let(:attributes) { [mock_attribute1, mock_attribute2] }

    context 'when attributes contain embedded scripts' do
      before do
        allow(mock_attribute1).to receive(:[]).with(:name).and_return('class')
        allow(mock_attribute1).to receive(:[]).with(:value).and_return('btn {btnClass}')
        allow(mock_attribute2).to receive(:[]).with(:name).and_return('id')
        allow(mock_attribute2).to receive(:[]).with(:value).and_return('button-1')
      end

      it 'processes embedded scripts correctly' do
        result = described_class.parse_attributes(attributes)
        expect(result).to eq(":class => btn btnClass, :id => 'button-1'")
      end
    end

    context 'when attribute is "on" with hash value' do
      let(:mock_on_attribute) { double('on_attribute') }
      let(:attributes) { [mock_on_attribute] }

      before do
        allow(mock_on_attribute).to receive(:[]).with(:name).and_return('on')
        allow(mock_on_attribute).to receive(:[]).with(:value).and_return('{ click: handleClick }')
      end

      it 'preserves hash structure for "on" attribute' do
        result = described_class.parse_attributes(attributes)
        expect(result).to eq(":on => { click: handleClick }")
      end
    end

    context 'when attributes have no embedded scripts' do
      before do
        allow(mock_attribute1).to receive(:[]).with(:name).and_return('class')
        allow(mock_attribute1).to receive(:[]).with(:value).and_return('btn')
        allow(mock_attribute2).to receive(:[]).with(:name).and_return('id')
        allow(mock_attribute2).to receive(:[]).with(:value).and_return('button-1')
      end

      it 'returns quoted string values' do
        result = described_class.parse_attributes(attributes)
        expect(result).to eq(":class => 'btn', :id => 'button-1'")
      end
    end
  end

  describe '.is_component?' do
    it 'returns true for kebab-case component names' do
      expect(described_class.is_component?('my-component')).to be true
    end

    it 'returns true for single word component names' do
      expect(described_class.is_component?('mycomponent')).to be true
    end

    it 'returns false for standard HTML elements' do
      expect(described_class.is_component?('div')).to be false
      expect(described_class.is_component?('span')).to be false
      expect(described_class.is_component?('button')).to be false
    end

    it 'returns false for template element' do
      expect(described_class.is_component?('template')).to be false
    end
  end

  describe '.embed_script?' do
    it 'returns true for strings with curly braces' do
      expect(described_class.embed_script?('{variable}')).to be true
      expect(described_class.embed_script?('text {variable} more')).to be true
    end

    it 'returns false for strings without curly braces' do
      expect(described_class.embed_script?('plain text')).to be false
      expect(described_class.embed_script?('no braces here')).to be false
    end
  end

  describe '.get_embed_script' do
    it 'extracts content from curly braces' do
      expect(described_class.get_embed_script('{variable}')).to eq('variable')
      expect(described_class.get_embed_script('{state[:count]}')).to eq('state[:count]')
    end

    it 'extracts first occurrence when multiple braces' do
      expect(described_class.get_embed_script('{first} {second}')).to eq('first} {second')
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
