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

  describe '.is_component?' do
    context 'when tag name starts with uppercase letter' do
      it 'returns true for single uppercase word' do
        result = described_class.is_component?('Button')
        expect(result).to be true
      end

      it 'returns true for PascalCase component name' do
        result = described_class.is_component?('MyButton')
        expect(result).to be true
      end

      it 'returns true for component with numbers' do
        result = described_class.is_component?('Button2')
        expect(result).to be true
      end

      it 'returns true for hyphenated component name starting with uppercase' do
        result = described_class.is_component?('My-Component')
        expect(result).to be true
      end
    end

    context 'when tag name starts with lowercase letter' do
      it 'returns false for standard HTML elements' do
        result = described_class.is_component?('div')
        expect(result).to be false
      end

      it 'returns false for camelCase element name' do
        result = described_class.is_component?('myElement')
        expect(result).to be false
      end

      it 'returns false for hyphenated element name' do
        result = described_class.is_component?('my-element')
        expect(result).to be false
      end
    end

    context 'when tag name is empty or special characters' do
      it 'returns false for empty string' do
        result = described_class.is_component?('')
        expect(result).to be false
      end

      it 'returns false for numeric start' do
        result = described_class.is_component?('123Component')
        expect(result).to be false
      end
    end
  end

  describe '.find_component_constant' do
    # Define test components for testing constant detection
    before do
      # Define test constants if they don't exist
      unless defined?(SearchField)
        Object.const_set(:SearchField, Class.new)
      end
      unless defined?(UserCard)
        Object.const_set(:UserCard, Class.new)
      end
      unless defined?(MyButton)
        Object.const_set(:MyButton, Class.new)
      end
    end

    after do
      # Clean up test constants
      Object.send(:remove_const, :SearchField) if defined?(SearchField)
      Object.send(:remove_const, :UserCard) if defined?(UserCard)
      Object.send(:remove_const, :MyButton) if defined?(MyButton)
    end

    context 'when processing PascalCase component names converted by DOM parser' do
      it 'finds existing SearchField constant from SEARCHFIELD' do
        result = described_class.find_component_constant('SEARCHFIELD')
        expect(result).to eq('SearchField')
      end

      it 'finds existing UserCard constant from USERCARD' do
        result = described_class.find_component_constant('USERCARD')
        expect(result).to eq('UserCard')
      end

      it 'finds existing MyButton constant from MYBUTTON' do
        result = described_class.find_component_constant('MYBUTTON')
        expect(result).to eq('MyButton')
      end
    end

    context 'when no matching constant exists' do
      it 'falls back to best guess for non-existing component' do
        result = described_class.find_component_constant('NONEXISTENTFIELD')
        # Should try NonexistentField first, but when not found, falls back to first candidate
        expect(result).to eq('Nonexistentfield')
      end
    end

    context 'when processing hyphenated component names from DOM (recommended approach)' do
      it 'converts SEARCH-FIELD to SearchField' do
        result = described_class.find_component_constant('SEARCH-FIELD')
        expect(result).to eq('SearchField')
      end

      it 'converts MY-BUTTON to MyButton' do
        result = described_class.find_component_constant('MY-BUTTON')
        expect(result).to eq('MyButton')
      end

      it 'converts USER-CARD to UserCard' do
        result = described_class.find_component_constant('USER-CARD')
        expect(result).to eq('UserCard')
      end

      it 'converts USER-PROFILE-CARD to UserProfileCard' do
        result = described_class.find_component_constant('USER-PROFILE-CARD')
        expect(result).to eq('UserProfileCard')
      end

      it 'converts NAV-COMPONENT to NavComponent' do
        result = described_class.find_component_constant('NAV-COMPONENT')
        expect(result).to eq('NavComponent')
      end
    end

    context 'when processing single uppercase words' do
      it 'converts BUTTON to Button' do
        result = described_class.find_component_constant('BUTTON')
        expect(result).to eq('Button')
      end

      it 'converts MODAL to Modal' do
        result = described_class.find_component_constant('MODAL')
        expect(result).to eq('Modal')
      end

      it 'converts DIALOG to Dialog' do
        result = described_class.find_component_constant('DIALOG')
        expect(result).to eq('Dialog')
      end
    end

    context 'when processing already properly cased names' do
      it 'keeps PascalCase unchanged' do
        result = described_class.find_component_constant('SearchField')
        expect(result).to eq('SearchField')
      end

      it 'keeps single word capitalized unchanged' do
        result = described_class.find_component_constant('Button')
        expect(result).to eq('Button')
      end
    end
  end

  describe '.pascalize_tag_name' do
    context 'when converting component names' do
      it 'keeps single PascalCase word unchanged' do
        result = described_class.pascalize_tag_name('Button')
        expect(result).to eq('Button')
      end

      it 'keeps multi-word PascalCase unchanged' do
        result = described_class.pascalize_tag_name('MyButton')
        expect(result).to eq('MyButton')
      end

      it 'converts hyphenated name to PascalCase' do
        result = described_class.pascalize_tag_name('my-component')
        expect(result).to eq('MyComponent')
      end

      it 'converts multi-hyphenated name to PascalCase' do
        result = described_class.pascalize_tag_name('user-profile-card')
        expect(result).to eq('UserProfileCard')
      end

      it 'handles mixed case hyphenated names' do
        result = described_class.pascalize_tag_name('My-Custom-Button')
        expect(result).to eq('MyCustomButton')
      end

      it 'handles single lowercase word' do
        result = described_class.pascalize_tag_name('button')
        expect(result).to eq('Button')
      end

      it 'converts all uppercase single word to capitalized' do
        result = described_class.pascalize_tag_name('SEARCHFIELD')
        expect(result).to eq('Searchfield')
      end
    end

    context 'when handling edge cases' do
      it 'handles empty string' do
        result = described_class.pascalize_tag_name('')
        expect(result).to eq('')
      end

      it 'handles single character' do
        result = described_class.pascalize_tag_name('a')
        expect(result).to eq('A')
      end

      it 'handles name with trailing hyphen' do
        result = described_class.pascalize_tag_name('my-component-')
        expect(result).to eq('MyComponent')
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
        expect(result).to eq("'Hello World'")
      end
    end

    context 'when text node contains embedded script' do
      before do
        allow(mock_element).to receive(:[]).with(:nodeValue).and_return('{variable}')
      end

      it 'returns h_string wrapped script' do
        result = described_class.parse_text_node(mock_element)
        expect(result).to eq('RubyWasmUi::Vdom.h_string((variable).to_s)')
      end
    end

    context 'when text node contains mixed text and embedded script' do
      before do
        allow(mock_element).to receive(:[]).with(:nodeValue).and_return('Current count: {state[:count]}')
      end

      it 'returns h_string wrapped string concatenation' do
        result = described_class.parse_text_node(mock_element)
        expect(result).to eq("RubyWasmUi::Vdom.h_string('Current count: ' + (state[:count]).to_s)")
      end
    end

    context 'when text node contains multiple embedded scripts' do
      before do
        allow(mock_element).to receive(:[]).with(:nodeValue).and_return('Hello {user.name}, you have {count} items')
      end

      it 'returns h_string wrapped multiple concatenations' do
        result = described_class.parse_text_node(mock_element)
        expect(result).to eq("RubyWasmUi::Vdom.h_string('Hello ' + (user.name).to_s + ', you have ' + (count).to_s + ' items')")
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

    context 'when parsing on attribute with embedded scripts' do
      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute1)

        allow(mock_attribute1).to receive(:[]).with(:name).and_return('on')
        allow(mock_attribute1).to receive(:[]).with(:value).and_return('{click: handler}')
      end

      it 'wraps on attribute in hash syntax' do
        result = described_class.parse_attributes(mock_attributes)
        expect(result).to eq(':on => { click: handler }')
      end
    end

    context 'when parsing attributes with embedded scripts' do
      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute1)

        allow(mock_attribute1).to receive(:[]).with(:name).and_return('value')
        allow(mock_attribute1).to receive(:[]).with(:value).and_return('{state.value}')
      end

      it 'extracts script without quotes for non-on attributes' do
        result = described_class.parse_attributes(mock_attributes)
        expect(result).to eq(':value => state.value')
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
    let(:mock_component_node) { double('component_node') }
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
        expect(result).to eq("'Hello'")
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

    context 'when processing component nodes' do
      let(:mock_child_elements) { double('child_elements') }

      before do
        allow(mock_elements).to receive(:forEach).and_yield(mock_component_node)
        allow(mock_component_node).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_component_node).to receive(:[]).with(:tagName).and_return('SEARCH-FIELD')
        allow(mock_component_node).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_component_node).to receive(:[]).with(:childNodes).and_return(mock_child_elements)

        # Mock attributes
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(double('attr').tap do |attr|
          allow(attr).to receive(:[]).with(:name).and_return('value')
          allow(attr).to receive(:[]).with(:value).and_return('test')
        end)

        # Mock empty children
        allow(mock_child_elements).to receive(:forEach)
      end

      it 'builds VDOM for component nodes using find_component_constant' do
        result = described_class.build_vdom(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h(SearchField, {:value => 'test'}, [])")
      end
    end

    context 'when processing hyphenated component nodes' do
      let(:mock_child_elements) { double('child_elements') }

      before do
        allow(mock_elements).to receive(:forEach).and_yield(mock_component_node)
        allow(mock_component_node).to receive(:[]).with(:nodeType).and_return(1)
        allow(mock_component_node).to receive(:[]).with(:tagName).and_return('USER-CARD')
        allow(mock_component_node).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_component_node).to receive(:[]).with(:childNodes).and_return(mock_child_elements)

        # Mock attributes
        allow(mock_attributes).to receive(:[]).with(:length).and_return(0)

        # Mock empty children
        allow(mock_child_elements).to receive(:forEach)
      end

      it 'builds VDOM for hyphenated component nodes with PascalCase conversion' do
        result = described_class.build_vdom(mock_elements)
        expect(result).to eq("RubyWasmUi::Vdom.h(UserCard, {}, [])")
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
