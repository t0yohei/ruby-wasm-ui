# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyWasmUi::Template::Parser do
  describe '.preprocess_pascal_case_component_name' do
    context 'when processing PascalCase component names' do
      it 'converts simple PascalCase component name' do
        input = '<ButtonComponent>Click me</ButtonComponent>'
        expected = '<button-component>Click me</button-component>'
        result = described_class.preprocess_pascal_case_component_name(input)
        expect(result).to eq(expected)
      end

      it 'converts component with attributes' do
        input = '<ButtonComponent class="primary" disabled>Click me</ButtonComponent>'
        expected = '<button-component class="primary" disabled>Click me</button-component>'
        result = described_class.preprocess_pascal_case_component_name(input)
        expect(result).to eq(expected)
      end

      it 'converts self-closing component' do
        input = '<SearchField placeholder="Search..." />'
        expected = '<search-field placeholder="Search..." />'
        result = described_class.preprocess_pascal_case_component_name(input)
        expect(result).to eq(expected)
      end

      it 'converts multiple components in the same template' do
        input = '<ButtonComponent><SearchField /><IconComponent name="search" /></ButtonComponent>'
        expected = '<button-component><search-field /><icon-component name="search" /></button-component>'
        result = described_class.preprocess_pascal_case_component_name(input)
        expect(result).to eq(expected)
      end

      it 'converts components with complex PascalCase names' do
        input = '<TodoListItemComponent><UserProfileCardComponent /></TodoListItemComponent>'
        expected = '<todo-list-item-component><user-profile-card-component /></todo-list-item-component>'
        result = described_class.preprocess_pascal_case_component_name(input)
        expect(result).to eq(expected)
      end

      it 'handles components with embedded Ruby expressions' do
        input = '<ButtonComponent on="{ click: ->(e) { handle_click(e) } }">Count: {count}</ButtonComponent>'
        expected = '<button-component on="{ click: ->(e) { handle_click(e) } }">Count: {count}</button-component>'
        result = described_class.preprocess_pascal_case_component_name(input)
        expect(result).to eq(expected)
      end
    end

    context 'when processing mixed content' do
      it 'does not convert regular HTML elements' do
        input = '<div><span>Text</span><ButtonComponent>Click me</ButtonComponent></div>'
        expected = '<div><span>Text</span><button-component>Click me</button-component></div>'
        result = described_class.preprocess_pascal_case_component_name(input)
        expect(result).to eq(expected)
      end

      it 'preserves existing kebab-case components' do
        input = '<custom-button><ButtonComponent>Click me</ButtonComponent></custom-button>'
        expected = '<custom-button><button-component>Click me</button-component></custom-button>'
        result = described_class.preprocess_pascal_case_component_name(input)
        expect(result).to eq(expected)
      end
    end
  end

  describe '.preprocess_template_tag' do
    context 'when processing template tags' do
      it 'converts simple template tag' do
        input = '<template>Hello World</template>'
        expected = '<div data-template>Hello World</div>'
        result = described_class.preprocess_template_tag(input)
        expect(result).to eq(expected)
      end

      it 'converts template tag with attributes' do
        input = '<template class="container" data-test="value">Content</template>'
        expected = '<div data-template class="container" data-test="value">Content</div>'
        result = described_class.preprocess_template_tag(input)
        expect(result).to eq(expected)
      end

      it 'converts nested template tags' do
        input = '<template><template>Nested</template></template>'
        expected = '<div data-template><div data-template>Nested</div></div>'
        result = described_class.preprocess_template_tag(input)
        expect(result).to eq(expected)
      end

      it 'converts template tags with complex content' do
        input = '<template><div>Text</div><ButtonComponent>Click</ButtonComponent></template>'
        expected = '<div data-template><div>Text</div><ButtonComponent>Click</ButtonComponent></div>'
        result = described_class.preprocess_template_tag(input)
        expect(result).to eq(expected)
      end

      it 'preserves whitespace and indentation' do
        input = "  <template>\n    <div>Content</div>\n  </template>"
        expected = "  <div data-template>\n    <div>Content</div>\n  </div>"
        result = described_class.preprocess_template_tag(input)
        expect(result).to eq(expected)
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
        count = 42 # rubocop:disable Lint/UselessAssignment
        test_binding = binding()

        # Mock element node
        allow(mock_element).to receive(:[]).with(:nodeType).and_return(1) # ELEMENT_NODE
        allow(mock_element).to receive(:[]).with(:tagName).and_return('DIV')
        mock_element_attributes = double('element_attributes')
        allow(mock_element_attributes).to receive(:to_a).and_return([])
        allow(mock_element_attributes).to receive(:[]).with(:length).and_return(0)
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_element_attributes)

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
        handle_click = -> { 'clicked' } # rubocop:disable Lint/UselessAssignment
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
        count = 42 # rubocop:disable Lint/UselessAssignment
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
end
