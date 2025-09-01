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

  describe '.build_vdom' do
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
        result = described_class.build_vdom(mock_elements)
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
        result = described_class.build_vdom(mock_elements)
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
        result = described_class.build_vdom(mock_elements)
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
        result = described_class.build_vdom(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h_fragment([])")
      end

      it 'uses childNodes directly for div elements with data-template' do
        expect(mock_div_template_node).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)
        expect(mock_div_template_node).not_to receive(:[]).with(:content)
        described_class.build_vdom(mock_elements)
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
      end

      it 'builds VDOM for kebab-case component' do
        allow(mock_component_node).to receive(:[]).with(:tagName).and_return('custom-component')
        result = described_class.build_vdom(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h(CustomComponent, {}, [])")
      end

      it 'builds VDOM for multi-word kebab-case component' do
        allow(mock_component_node).to receive(:[]).with(:tagName).and_return('my-custom-button')
        result = described_class.build_vdom(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h(MyCustomButton, {}, [])")
      end

      it 'builds VDOM for single word component' do
        allow(mock_component_node).to receive(:[]).with(:tagName).and_return('mycomponent')
        result = described_class.build_vdom(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h(Mycomponent, {}, [])")
      end
    end
  end

  describe '.preprocess_self_closing_tags' do
    context 'when processing custom elements with self-closing tags' do
      it 'converts simple custom element self-closing tag' do
        input = '<search-field value="test" />'
        expected = '<search-field value="test" ></search-field>'
        result = described_class.preprocess_self_closing_tags(input)
        expect(result).to eq(expected)
      end

      it 'converts custom element with multiple attributes' do
        input = '<my-component id="1" class="test" data-value="123" />'
        expected = '<my-component id="1" class="test" data-value="123" ></my-component>'
        result = described_class.preprocess_self_closing_tags(input)
        expect(result).to eq(expected)
      end

      it 'converts multiple custom elements' do
        input = '<first-component /><second-component attr="value" />'
        expected = '<first-component ></first-component><second-component attr="value" ></second-component>'
        result = described_class.preprocess_self_closing_tags(input)
        expect(result).to eq(expected)
      end

      it 'handles custom elements with complex attributes including lambdas' do
        input = '<search-field value="{component.state[:search_term]}" on="{ search: ->(term) { update(term) } }" />'
        expected = '<search-field value="{component.state[:search_term]}" on="{ search: ->(term) { update(term) } }" ></search-field>'
        result = described_class.preprocess_self_closing_tags(input)
        expect(result).to eq(expected)
      end

      it 'handles nested quotes in attributes' do
        input = '<my-component data-json=\'{"key": "value"}\' />'
        expected = '<my-component data-json=\'{"key": "value"}\' ></my-component>'
        result = described_class.preprocess_self_closing_tags(input)
        expect(result).to eq(expected)
      end
    end

    context 'when processing standard HTML elements' do
      it 'does not convert standard HTML void elements' do
        input = '<input type="text" />'
        expected = '<input type="text" />'
        result = described_class.preprocess_self_closing_tags(input)
        expect(result).to eq(expected)
      end

      it 'does not convert single word tags' do
        input = '<div /><span />'
        expected = '<div /><span />'
        result = described_class.preprocess_self_closing_tags(input)
        expect(result).to eq(expected)
      end

      it 'does not convert already closed custom elements' do
        input = '<my-component></my-component>'
        expected = '<my-component></my-component>'
        result = described_class.preprocess_self_closing_tags(input)
        expect(result).to eq(expected)
      end
    end

    context 'when processing mixed content' do
      it 'converts only custom elements in mixed HTML' do
        input = '<div><input type="text" /><my-component /></div>'
        expected = '<div><input type="text" /><my-component ></my-component></div>'
        result = described_class.preprocess_self_closing_tags(input)
        expect(result).to eq(expected)
      end

      it 'handles multiple custom elements with different naming patterns' do
        input = '<search-field /><todo-list-item /><app-header-nav />'
        expected = '<search-field ></search-field><todo-list-item ></todo-list-item><app-header-nav ></app-header-nav>'
        result = described_class.preprocess_self_closing_tags(input)
        expect(result).to eq(expected)
      end
    end
  end

  describe '.parse' do
    let(:mock_parser) { double('parser') }
    let(:mock_document) { double('document') }
    let(:mock_body) { double('body') }
    let(:mock_child_nodes) { double('child_nodes') }

    before do
      # Mock preprocess_self_closing_tags to return processed template
      allow(described_class).to receive(:preprocess_self_closing_tags).with('template_string').and_return('processed_template')

      # Mock JS.eval and DOMParser
      js_mock = double('JS')
      allow(js_mock).to receive(:eval).with('return new DOMParser()').and_return(mock_parser)
      allow(js_mock).to receive(:try_convert).with('processed_template').and_return('processed_template')
      stub_const('JS', js_mock)

      allow(mock_parser).to receive(:call).with(:parseFromString, 'processed_template', 'text/html').and_return(mock_document)
      allow(mock_document).to receive(:getElementsByTagName).with('body').and_return([mock_body])
      allow(mock_body).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)

      # Mock empty child nodes
      allow(mock_child_nodes).to receive(:[]).with(:length).and_return(0)
    end

    it 'preprocesses self-closing tags before parsing' do
      expect(described_class).to receive(:preprocess_self_closing_tags).with('template_string')
      described_class.parse('template_string')
    end

    it 'parses HTML template and returns VDOM string' do
      result = described_class.parse('template_string')
      expect(result).to eq('')
    end

    context 'when processing template tags' do
      it 'replaces <template> with <div data-template>' do
        template = '<template><div>content</div></template>'
        expected_replacement = '<div data-template><div>content</div></div>'

        # Mock the replacement processing
        allow(described_class).to receive(:preprocess_self_closing_tags).with(template).and_return(template)

        # Verify the template replacement happens
        expect(described_class).to receive(:preprocess_self_closing_tags).with(template).and_return(template)

        # Mock JS components to avoid actual parsing
        js_mock = double('JS')
        allow(js_mock).to receive(:eval).and_return(mock_parser)
        allow(js_mock).to receive(:try_convert).with(expected_replacement).and_return(expected_replacement)
        stub_const('JS', js_mock)

        allow(mock_parser).to receive(:call).and_return(mock_document)
        allow(mock_document).to receive(:getElementsByTagName).and_return([mock_body])
        allow(mock_body).to receive(:[]).and_return(mock_child_nodes)
        allow(mock_child_nodes).to receive(:[]).with(:length).and_return(0)

        described_class.parse(template)

        # Verify that JS.try_convert was called with the replaced template
        expect(js_mock).to have_received(:try_convert).with(expected_replacement)
      end

      it 'replaces <template attr="value"> with <div data-template attr="value">' do
        template = '<template class="container"><div>content</div></template>'
        expected_replacement = '<div data-template class="container"><div>content</div></div>'

        # Mock the replacement processing
        allow(described_class).to receive(:preprocess_self_closing_tags).with(template).and_return(template)

        # Mock JS components to avoid actual parsing
        js_mock = double('JS')
        allow(js_mock).to receive(:eval).and_return(mock_parser)
        allow(js_mock).to receive(:try_convert).with(expected_replacement).and_return(expected_replacement)
        stub_const('JS', js_mock)

        allow(mock_parser).to receive(:call).and_return(mock_document)
        allow(mock_document).to receive(:getElementsByTagName).and_return([mock_body])
        allow(mock_body).to receive(:[]).and_return(mock_child_nodes)
        allow(mock_child_nodes).to receive(:[]).with(:length).and_return(0)

        described_class.parse(template)

        # Verify that JS.try_convert was called with the replaced template
        expect(js_mock).to have_received(:try_convert).with(expected_replacement)
      end
    end
  end

  describe '.parse_and_eval' do
    let(:mock_parser) { double('parser') }
    let(:mock_document) { double('document') }
    let(:mock_body) { double('body') }
    let(:mock_child_nodes) { double('child_nodes') }
    let(:mock_element) { double('element') }
    let(:mock_vdom) { double('vdom') }

    before do
      # Mock preprocess_self_closing_tags
      allow(described_class).to receive(:preprocess_self_closing_tags).with(anything).and_return('processed_template')

      # Mock JS.eval, DOMParser, and JS.global
      js_mock = double('JS')
      allow(js_mock).to receive(:eval).with('return new DOMParser()').and_return(mock_parser)
      allow(js_mock).to receive(:try_convert).with('processed_template').and_return('processed_template')
      allow(js_mock).to receive(:global).and_return({ Node: { TEXT_NODE: 3, ELEMENT_NODE: 1 } })
      stub_const('JS', js_mock)

      allow(mock_parser).to receive(:call).with(:parseFromString, 'processed_template', 'text/html').and_return(mock_document)
      allow(mock_document).to receive(:getElementsByTagName).with('body').and_return([mock_body])
      allow(mock_body).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)

      # Mock element node
      allow(mock_element).to receive(:[]).with(:nodeType).and_return(1) # ELEMENT_NODE
      allow(mock_element).to receive(:[]).with(:tagName).and_return('DIV')
      allow(mock_element).to receive(:[]).with(:attributes).and_return({ length: 0 })
      allow(mock_element).to receive(:[]).with(:childNodes).and_return([])

      # Mock child nodes as a JavaScript-like array with length and indexing
      mock_child_nodes_array = double('child_nodes_array')
      allow(mock_child_nodes_array).to receive(:[]).with(:length).and_return(1)
      allow(mock_child_nodes_array).to receive(:[]).with(0).and_return(mock_element)
      allow(mock_body).to receive(:[]).with(:childNodes).and_return(mock_child_nodes_array)

      # Mock empty child nodes for element
      mock_empty_nodes = double('empty_nodes')
      allow(mock_empty_nodes).to receive(:[]).with(:length).and_return(0)
      allow(mock_element).to receive(:[]).with(:childNodes).and_return(mock_empty_nodes)
    end

    context 'when evaluating a template with variables' do
      it 'returns a VDOM object with evaluated variables' do
        template = '<div>{count}</div>'
        count = 42 # Used in template evaluation
        test_binding = binding()

        # Mock element node
        allow(mock_element).to receive(:[]).with(:nodeType).and_return(1) # ELEMENT_NODE
        allow(mock_element).to receive(:[]).with(:tagName).and_return('DIV')
        mock_element_attributes = double('element_attributes')
        allow(mock_element_attributes).to receive(:to_a).and_return([])
        allow(mock_element_attributes).to receive(:[]).with(:length).and_return(0)
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_element_attributes)

        # Mock has_conditional_attribute? to return false
        allow(described_class).to receive(:has_conditional_attribute?).with(mock_element).and_return(false)

        # Mock text node for count
        mock_text_node = double('text_node')
        allow(mock_text_node).to receive(:[]).with(:nodeType).and_return(3) # TEXT_NODE
        allow(mock_text_node).to receive(:[]).with(:nodeValue).and_return('{count}')
        mock_child_nodes = double('child_nodes')
        allow(mock_child_nodes).to receive(:[]).with(:length).and_return(1)
        allow(mock_child_nodes).to receive(:[]).with(0).and_return(mock_text_node)
        allow(mock_element).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)

        # Mock RubyWasmUi::Vdom
        stub_const('RubyWasmUi::Vdom', mock_vdom)
        allow(mock_vdom).to receive(:h).with('div', {}, ["42"]).and_return(mock_vdom)
        allow(mock_vdom).to receive(:h_fragment).with([mock_vdom]).and_return(mock_vdom)

        result = described_class.parse_and_eval(template, test_binding)
        expect(result).to eq(mock_vdom)
      end
    end

    context 'when evaluating a template with event handlers' do
      it 'returns a VDOM object with event handlers' do
        template = '<div on="{click: ->(e) { handle_click.call(e) }}"></div>'
        handle_click = -> { 'clicked' } # Used in template evaluation
        test_binding = binding()

        # Mock element node with attributes
        allow(mock_element).to receive(:[]).with(:nodeType).and_return(1) # ELEMENT_NODE
        allow(mock_element).to receive(:[]).with(:tagName).and_return('DIV')
        mock_attributes = double('attributes')
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        mock_attribute = double('attribute')
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('on')
        allow(mock_attribute).to receive(:[]).with(:value).and_return('{click: ->(e) { handle_click.call(e) }}')
        allow(mock_attributes).to receive(:to_a).and_return([mock_attribute])
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)

        # Mock has_conditional_attribute? to return false
        allow(described_class).to receive(:has_conditional_attribute?).with(mock_element).and_return(false)

        # Mock RubyWasmUi::Vdom
        stub_const('RubyWasmUi::Vdom', mock_vdom)
        allow(mock_vdom).to receive(:h).with('div', { on: { click: kind_of(Proc) } }, []).and_return(mock_vdom)
        allow(mock_vdom).to receive(:h_fragment).with([mock_vdom]).and_return(mock_vdom)

        result = described_class.parse_and_eval(template, test_binding)
        expect(result).to eq(mock_vdom)
      end
    end

    context 'when evaluating a template with components' do
      let(:mock_component) { double('component') }

      it 'returns a VDOM object with components' do
        template = '<custom-component>{count}</custom-component>'
        count = 42 # Used in template evaluation
        test_binding = binding()

        # Mock component node
        allow(mock_element).to receive(:[]).with(:nodeType).and_return(1) # ELEMENT_NODE
        allow(mock_element).to receive(:[]).with(:tagName).and_return('CUSTOM-COMPONENT')
        mock_component_attributes = double('component_attributes')
        allow(mock_component_attributes).to receive(:to_a).and_return([])
        allow(mock_component_attributes).to receive(:[]).with(:length).and_return(0)
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_component_attributes)

        # Mock text node for count
        mock_text_node = double('text_node')
        allow(mock_text_node).to receive(:[]).with(:nodeType).and_return(3) # TEXT_NODE
        allow(mock_text_node).to receive(:[]).with(:nodeValue).and_return('{count}')
        mock_child_nodes = double('child_nodes')
        allow(mock_child_nodes).to receive(:[]).with(:length).and_return(1)
        allow(mock_child_nodes).to receive(:[]).with(0).and_return(mock_text_node)
        allow(mock_element).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)

        # Mock component class
        stub_const('CustomComponent', mock_component)

        # Mock RubyWasmUi::Vdom
        stub_const('RubyWasmUi::Vdom', mock_vdom)
        allow(mock_vdom).to receive(:h).with(mock_component, {}, ["42"]).and_return(mock_vdom)
        allow(mock_vdom).to receive(:h_fragment).with([mock_vdom]).and_return(mock_vdom)

        result = described_class.parse_and_eval(template, test_binding)
        expect(result).to eq(mock_vdom)
      end
    end

    context 'when evaluating multiple top-level expressions' do
      it 'wraps multiple expressions in a fragment' do
        # Mock parse to return multiple expressions
        allow(described_class).to receive(:parse).and_return('expr1,expr2')

        # Mock eval to return the fragment
        mock_fragment = double('fragment')
        allow(described_class).to receive(:eval).with('RubyWasmUi::Vdom.h_fragment([expr1,expr2])', anything).and_return(mock_fragment)

        result = described_class.parse_and_eval('<div>1</div><div>2</div>', binding)
        expect(result).to eq(mock_fragment)
      end

      it 'wraps expressions containing end, in a fragment' do
        # Mock parse to return expressions with 'end,'
        allow(described_class).to receive(:parse).and_return('if condition then expr1 end,expr2')

        # Mock eval to return the fragment
        mock_fragment = double('fragment')
        allow(described_class).to receive(:eval).with('RubyWasmUi::Vdom.h_fragment([if condition then expr1 end,expr2])', anything).and_return(mock_fragment)

        result = described_class.parse_and_eval('<div r-if="{true}">content</div><div>other</div>', binding)
        expect(result).to eq(mock_fragment)
      end

      it 'does not wrap single expression' do
        # Mock parse to return single expression
        allow(described_class).to receive(:parse).and_return('single_expr')

        # Mock eval to return the expression directly
        mock_result = double('result')
        allow(described_class).to receive(:eval).with('single_expr', anything).and_return(mock_result)

        result = described_class.parse_and_eval('<div>single</div>', binding)
        expect(result).to eq(mock_result)
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
end
