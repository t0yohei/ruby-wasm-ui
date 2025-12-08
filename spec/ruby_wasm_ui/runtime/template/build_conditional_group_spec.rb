# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyWasmUi::Template::BuildConditionalGroup do
  let(:mock_node_constants) { double('Node') }

  before do
    # Mock JS.global[:Node] constants
    js_mock = double('JS')
    allow(js_mock).to receive(:global).and_return({ Node: mock_node_constants })
    stub_const('JS', js_mock)

    allow(mock_node_constants).to receive(:[]).with(:ELEMENT_NODE).and_return(1)
    allow(mock_node_constants).to receive(:[]).with(:TEXT_NODE).and_return(3)
  end
  describe '.has_conditional_attribute?' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }

    context 'when element has r-if attribute' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-if')
      end

      let(:mock_attribute) { double('attribute') }

      it 'returns true' do
        result = described_class.has_conditional_attribute?(mock_element)
        expect(result).to be true
      end
    end

    context 'when element has r-elsif attribute' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-elsif')
      end

      let(:mock_attribute) { double('attribute') }

      it 'returns true' do
        result = described_class.has_conditional_attribute?(mock_element)
        expect(result).to be true
      end
    end

    context 'when element has r-else attribute' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-else')
      end

      let(:mock_attribute) { double('attribute') }

      it 'returns true' do
        result = described_class.has_conditional_attribute?(mock_element)
        expect(result).to be true
      end
    end

    context 'when element has no conditional attributes' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('class')
      end

      let(:mock_attribute) { double('attribute') }

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

  describe '.build_conditional_group' do
    let(:mock_elements) { double('elements') }
    let(:mock_element_if) { double('element_if') }
    let(:mock_element_elsif) { double('element_elsif') }
    let(:mock_element_else) { double('element_else') }
    let(:mock_attributes_if) { double('attributes_if') }
    let(:mock_attributes_elsif) { double('attributes_elsif') }
    let(:mock_attributes_else) { double('attributes_else') }
    let(:mock_attribute_if) { double('attribute_if') }
    let(:mock_attribute_elsif) { double('attribute_elsif') }
    let(:mock_attribute_else) { double('attribute_else') }

    context 'with complete conditional chain (r-if, r-elsif, r-else)' do
      before do
        # Mock elements array
        allow(mock_elements).to receive(:[]).with(:length).and_return(3)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_element_if)
        allow(mock_elements).to receive(:[]).with(1).and_return(mock_element_elsif)
        allow(mock_elements).to receive(:[]).with(2).and_return(mock_element_else)

        # Mock element types
        allow(mock_element_if).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_element_elsif).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_element_else).to receive(:[]).with(:nodeType).and_return(1)

        # Mock has_conditional_attribute? responses
        allow(described_class).to receive(:has_conditional_attribute?)
          .with(mock_element_if).and_return(true)
        allow(described_class).to receive(:has_conditional_attribute?)
          .with(mock_element_elsif).and_return(true)
        allow(described_class).to receive(:has_conditional_attribute?)
          .with(mock_element_else).and_return(true)

        # Mock get_conditional_type responses
        allow(described_class).to receive(:get_conditional_type)
          .with(mock_element_if).and_return('r-if')
        allow(described_class).to receive(:get_conditional_type)
          .with(mock_element_elsif).and_return('r-elsif')
        allow(described_class).to receive(:get_conditional_type)
          .with(mock_element_else).and_return('r-else')

        # Mock get_conditional_expression responses
        allow(described_class).to receive(:get_conditional_expression)
          .with(mock_element_if).and_return('condition1')
        allow(described_class).to receive(:get_conditional_expression)
          .with(mock_element_elsif).and_return('condition2')
        allow(described_class).to receive(:get_conditional_expression)
          .with(mock_element_else).and_return('true')

        # Mock build_single_conditional_content responses
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

    context 'with only r-if (no r-else)' do
      before do
        # Mock elements array
        allow(mock_elements).to receive(:[]).with(:length).and_return(1)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_element_if)

        # Mock element type
        allow(mock_element_if).to receive(:[]).with(:nodeType).and_return(1)

        # Mock has_conditional_attribute? response
        allow(described_class).to receive(:has_conditional_attribute?)
          .with(mock_element_if).and_return(true)

        # Mock get_conditional_type response
        allow(described_class).to receive(:get_conditional_type)
          .with(mock_element_if).and_return('r-if')

        # Mock get_conditional_expression response
        allow(described_class).to receive(:get_conditional_expression)
          .with(mock_element_if).and_return('condition')

        # Mock build_single_conditional_content response
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

    context 'with text nodes between elements' do
      let(:mock_text_node) { double('text_node') }

      before do
        # Mock elements array with text node
        allow(mock_elements).to receive(:[]).with(:length).and_return(3)
        allow(mock_elements).to receive(:[]).with(0).and_return(mock_element_if)
        allow(mock_elements).to receive(:[]).with(1).and_return(mock_text_node)
        allow(mock_elements).to receive(:[]).with(2).and_return(mock_element_else)

        # Mock node types
        allow(mock_element_if).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_text_node).to receive(:[]).with(:nodeType).and_return(3)
        allow(mock_element_else).to receive(:[]).with(:nodeType).and_return(1)

        # Mock has_conditional_attribute? responses
        allow(described_class).to receive(:has_conditional_attribute?)
          .with(mock_element_if).and_return(true)
        allow(described_class).to receive(:has_conditional_attribute?)
          .with(mock_element_else).and_return(true)

        # Mock get_conditional_type responses
        allow(described_class).to receive(:get_conditional_type)
          .with(mock_element_if).and_return('r-if')
        allow(described_class).to receive(:get_conditional_type)
          .with(mock_element_else).and_return('r-else')

        # Mock get_conditional_expression response
        allow(described_class).to receive(:get_conditional_expression)
          .with(mock_element_if).and_return('condition')
        allow(described_class).to receive(:get_conditional_expression)
          .with(mock_element_else).and_return('true')

        # Mock build_single_conditional_content responses
        allow(described_class).to receive(:build_single_conditional_content)
          .with(mock_element_if).and_return('content_if')
        allow(described_class).to receive(:build_single_conditional_content)
          .with(mock_element_else).and_return('content_else')
      end

      it 'skips text nodes and processes conditional elements' do
        result, next_index = described_class.build_conditional_group(mock_elements, 0)

        expected = [
          'if condition',
          '  content_if',
          'else',
          '  content_else',
          'end'
        ].join("\n")

        expect(result).to eq(expected)
        expect(next_index).to eq(3)
      end
    end
  end

  describe '.get_conditional_type' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }
    let(:mock_attribute) { double('attribute') }

    before do
      allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
      allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
    end

    context 'when element has r-if attribute' do
      before do
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-if')
      end

      it 'returns r-if' do
        result = described_class.get_conditional_type(mock_element)
        expect(result).to eq('r-if')
      end
    end

    context 'when element has r-elsif attribute' do
      before do
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-elsif')
      end

      it 'returns r-elsif' do
        result = described_class.get_conditional_type(mock_element)
        expect(result).to eq('r-elsif')
      end
    end

    context 'when element has r-else attribute' do
      before do
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-else')
      end

      it 'returns r-else' do
        result = described_class.get_conditional_type(mock_element)
        expect(result).to eq('r-else')
      end
    end

    context 'when element has no conditional attributes' do
      before do
        allow(mock_attribute).to receive(:[]).with(:name).and_return('class')
      end

      it 'returns r-if as fallback' do
        result = described_class.get_conditional_type(mock_element)
        expect(result).to eq('r-if')
      end
    end
  end

  describe '.get_conditional_expression' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }
    let(:mock_attribute) { double('attribute') }

    before do
      allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
      allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
    end

    context 'when element has r-if attribute with embedded script' do
      before do
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-if')
        allow(mock_attribute).to receive(:[]).with(:value).and_return('{state[:visible]}')
        allow(RubyWasmUi::Template::BuildVdom).to receive(:embed_script?).with('{state[:visible]}').and_return(true)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:get_embed_script).with('{state[:visible]}').and_return('state[:visible]')
      end

      it 'returns the extracted script' do
        result = described_class.get_conditional_expression(mock_element)
        expect(result).to eq('state[:visible]')
      end
    end

    context 'when element has r-elsif attribute with plain value' do
      before do
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-elsif')
        allow(mock_attribute).to receive(:[]).with(:value).and_return('condition')
        allow(RubyWasmUi::Template::BuildVdom).to receive(:embed_script?).with('condition').and_return(false)
      end

      it 'returns the plain value' do
        result = described_class.get_conditional_expression(mock_element)
        expect(result).to eq('condition')
      end
    end

    context 'when element has no conditional attributes' do
      before do
        allow(mock_attribute).to receive(:[]).with(:name).and_return('class')
        allow(mock_attribute).to receive(:[]).with(:value).and_return('some-class')
      end

      it 'returns true as fallback' do
        result = described_class.get_conditional_expression(mock_element)
        expect(result).to eq('true')
      end
    end
  end

  describe '.filter_conditional_attributes' do
    let(:mock_attributes) { double('attributes') }
    let(:mock_attribute_1) { double('attribute_1') }
    let(:mock_attribute_2) { double('attribute_2') }
    let(:mock_attribute_3) { double('attribute_3') }
    let(:mock_attribute_4) { double('attribute_4') }

    context 'when attributes contain conditional and data-template attributes' do
      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(4)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute_1)
        allow(mock_attributes).to receive(:[]).with(1).and_return(mock_attribute_2)
        allow(mock_attributes).to receive(:[]).with(2).and_return(mock_attribute_3)
        allow(mock_attributes).to receive(:[]).with(3).and_return(mock_attribute_4)

        allow(mock_attribute_1).to receive(:[]).with(:name).and_return('r-if')
        allow(mock_attribute_2).to receive(:[]).with(:name).and_return('class')
        allow(mock_attribute_3).to receive(:[]).with(:name).and_return('data-template')
        allow(mock_attribute_4).to receive(:[]).with(:name).and_return('id')
      end

      it 'filters out conditional and data-template attributes' do
        result = described_class.filter_conditional_attributes(mock_attributes)
        expect(result).to eq([mock_attribute_2, mock_attribute_4])
      end
    end

    context 'when attributes contain only regular attributes' do
      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(2)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute_1)
        allow(mock_attributes).to receive(:[]).with(1).and_return(mock_attribute_2)

        allow(mock_attribute_1).to receive(:[]).with(:name).and_return('class')
        allow(mock_attribute_2).to receive(:[]).with(:name).and_return('id')
      end

      it 'returns all attributes' do
        result = described_class.filter_conditional_attributes(mock_attributes)
        expect(result).to eq([mock_attribute_1, mock_attribute_2])
      end
    end

    context 'when attributes contain only conditional attributes' do
      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(3)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute_1)
        allow(mock_attributes).to receive(:[]).with(1).and_return(mock_attribute_2)
        allow(mock_attributes).to receive(:[]).with(2).and_return(mock_attribute_3)

        allow(mock_attribute_1).to receive(:[]).with(:name).and_return('r-if')
        allow(mock_attribute_2).to receive(:[]).with(:name).and_return('r-elsif')
        allow(mock_attribute_3).to receive(:[]).with(:name).and_return('r-else')
      end

      it 'returns empty array' do
        result = described_class.filter_conditional_attributes(mock_attributes)
        expect(result).to eq([])
      end
    end
  end

  describe '.build_single_conditional_content' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }
    let(:filtered_attributes) { [] }

    before do
      allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      allow(described_class).to receive(:filter_conditional_attributes).with(mock_attributes).and_return(filtered_attributes)
    end

    context 'when element is a template' do
      before do
        allow(mock_element).to receive(:[]).with(:tagName).and_return('TEMPLATE')
        allow(RubyWasmUi::Template::BuildVdom).to receive(:has_data_template_attribute?).with(mock_element).and_return(false)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:build_fragment).with(mock_element, 'template').and_return('fragment_result')
      end

      it 'builds fragment' do
        result = described_class.build_single_conditional_content(mock_element)
        expect(result).to eq('fragment_result')
      end
    end

    context 'when element is a div with data-template attribute' do
      before do
        allow(mock_element).to receive(:[]).with(:tagName).and_return('DIV')
        allow(RubyWasmUi::Template::BuildVdom).to receive(:has_data_template_attribute?).with(mock_element).and_return(true)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:build_fragment).with(mock_element, 'div').and_return('fragment_result')
      end

      it 'builds fragment' do
        result = described_class.build_single_conditional_content(mock_element)
        expect(result).to eq('fragment_result')
      end
    end

    context 'when element is a component' do
      before do
        allow(mock_element).to receive(:[]).with(:tagName).and_return('CUSTOM-COMPONENT')
        allow(RubyWasmUi::Template::BuildVdom).to receive(:has_data_template_attribute?).with(mock_element).and_return(false)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:is_component?).with('custom-component').and_return(true)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:build_component).with(mock_element, 'custom-component', filtered_attributes).and_return('component_result')
      end

      it 'builds component' do
        result = described_class.build_single_conditional_content(mock_element)
        expect(result).to eq('component_result')
      end
    end

    context 'when element is a regular HTML element' do
      before do
        allow(mock_element).to receive(:[]).with(:tagName).and_return('DIV')
        allow(RubyWasmUi::Template::BuildVdom).to receive(:has_data_template_attribute?).with(mock_element).and_return(false)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:is_component?).with('div').and_return(false)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:build_element).with(mock_element, 'div', filtered_attributes).and_return('element_result')
      end

      it 'builds element' do
        result = described_class.build_single_conditional_content(mock_element)
        expect(result).to eq('element_result')
      end
    end
  end
end
