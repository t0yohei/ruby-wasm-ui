# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyWasmUi::Template::BuildForGroup do
  let(:mock_node_constants) { double('Node') }

  before do
    # Mock JS.global[:Node] constants
    js_mock = double('JS')
    allow(js_mock).to receive(:global).and_return({ Node: mock_node_constants })
    stub_const('JS', js_mock)

    allow(mock_node_constants).to receive(:[]).with(:ELEMENT_NODE).and_return(1)
    allow(mock_node_constants).to receive(:[]).with(:TEXT_NODE).and_return(3)
  end

  describe '.has_for_attribute?' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }

    context 'when element has r-for attribute' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-for')
      end

      let(:mock_attribute) { double('attribute') }

      it 'returns true' do
        result = described_class.has_for_attribute?(mock_element)
        expect(result).to be true
      end
    end

    context 'when element has no r-for attribute' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
        allow(mock_attribute).to receive(:[]).with(:name).and_return('class')
      end

      let(:mock_attribute) { double('attribute') }

      it 'returns false' do
        result = described_class.has_for_attribute?(mock_element)
        expect(result).to be false
      end
    end

    context 'when element has no attributes' do
      before do
        allow(mock_element).to receive(:[]).with(:attributes).and_return(nil)
      end

      it 'returns false' do
        result = described_class.has_for_attribute?(mock_element)
        expect(result).to be false
      end
    end
  end

  describe '.build_for_loop' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }
    let(:mock_child_nodes) { double('child_nodes') }

    before do
      allow(mock_element).to receive(:[]).with(:tagName).and_return('TODO-ITEM-COMPONENT')
      allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      allow(mock_element).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)
      allow(mock_child_nodes).to receive(:[]).with(:length).and_return(0)
    end

    context 'when element has valid r-for expression' do
      let(:mock_for_attribute) { double('for_attribute') }
      let(:mock_key_attribute) { double('key_attribute') }
      let(:mock_todo_attribute) { double('todo_attribute') }
      let(:mock_id_attribute) { double('id_attribute') }

      before do
        # Mock attributes
        allow(mock_attributes).to receive(:[]).with(:length).and_return(4)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_for_attribute)
        allow(mock_attributes).to receive(:[]).with(1).and_return(mock_key_attribute)
        allow(mock_attributes).to receive(:[]).with(2).and_return(mock_todo_attribute)
        allow(mock_attributes).to receive(:[]).with(3).and_return(mock_id_attribute)

        # Mock r-for attribute
        allow(mock_for_attribute).to receive(:[]).with(:name).and_return('r-for')
        allow(mock_for_attribute).to receive(:[]).with(:value).and_return('{todo in todos}')

        # Mock other attributes
        allow(mock_key_attribute).to receive(:[]).with(:name).and_return('key')
        allow(mock_key_attribute).to receive(:[]).with(:value).and_return('{todo[:text]}')
        allow(mock_todo_attribute).to receive(:[]).with(:name).and_return('todo')
        allow(mock_todo_attribute).to receive(:[]).with(:value).and_return('{todo[:text]}')
        allow(mock_id_attribute).to receive(:[]).with(:name).and_return('id')
        allow(mock_id_attribute).to receive(:[]).with(:value).and_return('{todo[:id]}')

        # Mock BuildVdom methods
        allow(RubyWasmUi::Template::BuildVdom).to receive(:embed_script?).with('{todo in todos}').and_return(true)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:get_embed_script).with('{todo in todos}').and_return('todo in todos')
        allow(RubyWasmUi::Template::BuildVdom).to receive(:is_component?).with('todo-item-component').and_return(true)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:parse_attributes).and_return(':key => todo[:text], :todo => todo[:text], :id => todo[:id]')
        allow(RubyWasmUi::Template::BuildVdom).to receive(:build).with(mock_child_nodes).and_return('')
      end

      it 'generates map code for component' do
        result = described_class.build_for_loop(mock_element)
        expected = "todos.map do |todo|\n  RubyWasmUi::Vdom.h(TodoItemComponent, {:key => todo[:text], :todo => todo[:text], :id => todo[:id]}, [])\nend"
        expect(result).to eq(expected)
      end
    end

    context 'when element has r-for expression without curly braces' do
      let(:mock_for_attribute) { double('for_attribute') }

      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_for_attribute)
        allow(mock_for_attribute).to receive(:[]).with(:name).and_return('r-for')
        allow(mock_for_attribute).to receive(:[]).with(:value).and_return('item in items')

        allow(RubyWasmUi::Template::BuildVdom).to receive(:embed_script?).with('item in items').and_return(false)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:is_component?).with('todo-item-component').and_return(true)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:parse_attributes).and_return('')
        allow(RubyWasmUi::Template::BuildVdom).to receive(:build).with(mock_child_nodes).and_return('')
      end

      it 'generates map code without script extraction' do
        result = described_class.build_for_loop(mock_element)
        expected = "items.map do |item|\n  RubyWasmUi::Vdom.h(TodoItemComponent, {}, [])\nend"
        expect(result).to eq(expected)
      end
    end

    context 'when element is a regular HTML element' do
      before do
        allow(mock_element).to receive(:[]).with(:tagName).and_return('LI')
        
        # Mock r-for attribute
        mock_for_attribute = double('for_attribute')
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_for_attribute)
        allow(mock_for_attribute).to receive(:[]).with(:name).and_return('r-for')
        allow(mock_for_attribute).to receive(:[]).with(:value).and_return('{item in items}')

        allow(RubyWasmUi::Template::BuildVdom).to receive(:embed_script?).with('{item in items}').and_return(true)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:get_embed_script).with('{item in items}').and_return('item in items')
        allow(RubyWasmUi::Template::BuildVdom).to receive(:is_component?).with('li').and_return(false)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:parse_attributes).and_return('')
        allow(RubyWasmUi::Template::BuildVdom).to receive(:build).with(mock_child_nodes).and_return('')
      end

      it 'generates map code for HTML element' do
        result = described_class.build_for_loop(mock_element)
        expected = "items.map do |item|\n  RubyWasmUi::Vdom.h('li', {}, [])\nend"
        expect(result).to eq(expected)
      end
    end

    context 'when r-for expression has invalid syntax' do
      let(:mock_for_attribute) { double('for_attribute') }

      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_for_attribute)
        allow(mock_for_attribute).to receive(:[]).with(:name).and_return('r-for')
        allow(mock_for_attribute).to receive(:[]).with(:value).and_return('invalid syntax')

        allow(RubyWasmUi::Template::BuildVdom).to receive(:embed_script?).with('invalid syntax').and_return(false)
      end

      it 'returns empty string' do
        result = described_class.build_for_loop(mock_element)
        expect(result).to eq('')
      end
    end

    context 'when element has no r-for attribute' do
      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(0)
      end

      it 'returns empty string' do
        result = described_class.build_for_loop(mock_element)
        expect(result).to eq('')
      end
    end
  end

  describe '.get_for_expression' do
    let(:mock_element) { double('element') }
    let(:mock_attributes) { double('attributes') }
    let(:mock_attribute) { double('attribute') }

    before do
      allow(mock_element).to receive(:[]).with(:attributes).and_return(mock_attributes)
      allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
      allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute)
    end

    context 'when element has r-for attribute with embedded script' do
      before do
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-for')
        allow(mock_attribute).to receive(:[]).with(:value).and_return('{item in items}')
        allow(RubyWasmUi::Template::BuildVdom).to receive(:embed_script?).with('{item in items}').and_return(true)
        allow(RubyWasmUi::Template::BuildVdom).to receive(:get_embed_script).with('{item in items}').and_return('item in items')
      end

      it 'returns the extracted script' do
        result = described_class.get_for_expression(mock_element)
        expect(result).to eq('item in items')
      end
    end

    context 'when element has r-for attribute with plain value' do
      before do
        allow(mock_attribute).to receive(:[]).with(:name).and_return('r-for')
        allow(mock_attribute).to receive(:[]).with(:value).and_return('item in items')
        allow(RubyWasmUi::Template::BuildVdom).to receive(:embed_script?).with('item in items').and_return(false)
      end

      it 'returns the plain value' do
        result = described_class.get_for_expression(mock_element)
        expect(result).to eq('item in items')
      end
    end

    context 'when element has no r-for attribute' do
      before do
        allow(mock_attribute).to receive(:[]).with(:name).and_return('class')
        allow(mock_attribute).to receive(:[]).with(:value).and_return('some-class')
      end

      it 'returns nil' do
        result = described_class.get_for_expression(mock_element)
        expect(result).to be_nil
      end
    end
  end

  describe '.filter_for_attributes' do
    let(:mock_attributes) { double('attributes') }
    let(:mock_attribute_1) { double('attribute_1') }
    let(:mock_attribute_2) { double('attribute_2') }
    let(:mock_attribute_3) { double('attribute_3') }

    context 'when attributes contain r-for and other attributes' do
      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(3)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute_1)
        allow(mock_attributes).to receive(:[]).with(1).and_return(mock_attribute_2)
        allow(mock_attributes).to receive(:[]).with(2).and_return(mock_attribute_3)

        allow(mock_attribute_1).to receive(:[]).with(:name).and_return('r-for')
        allow(mock_attribute_1).to receive(:[]).with(:value).and_return('{item in items}')
        allow(mock_attribute_2).to receive(:[]).with(:name).and_return('class')
        allow(mock_attribute_2).to receive(:[]).with(:value).and_return('item-class')
        allow(mock_attribute_3).to receive(:[]).with(:name).and_return('id')
        allow(mock_attribute_3).to receive(:[]).with(:value).and_return('{item.id}')
      end

      it 'filters out r-for attribute and returns others in correct format' do
        result = described_class.filter_for_attributes(mock_attributes)
        expected = [
          { name: 'class', value: 'item-class' },
          { name: 'id', value: '{item.id}' }
        ]
        expect(result).to eq(expected)
      end
    end

    context 'when attributes contain only r-for attribute' do
      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(1)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute_1)

        allow(mock_attribute_1).to receive(:[]).with(:name).and_return('r-for')
        allow(mock_attribute_1).to receive(:[]).with(:value).and_return('{item in items}')
      end

      it 'returns empty array' do
        result = described_class.filter_for_attributes(mock_attributes)
        expect(result).to eq([])
      end
    end

    context 'when attributes contain no r-for attribute' do
      before do
        allow(mock_attributes).to receive(:[]).with(:length).and_return(2)
        allow(mock_attributes).to receive(:[]).with(0).and_return(mock_attribute_1)
        allow(mock_attributes).to receive(:[]).with(1).and_return(mock_attribute_2)

        allow(mock_attribute_1).to receive(:[]).with(:name).and_return('class')
        allow(mock_attribute_1).to receive(:[]).with(:value).and_return('item-class')
        allow(mock_attribute_2).to receive(:[]).with(:name).and_return('id')
        allow(mock_attribute_2).to receive(:[]).with(:value).and_return('item-id')
      end

      it 'returns all attributes in correct format' do
        result = described_class.filter_for_attributes(mock_attributes)
        expected = [
          { name: 'class', value: 'item-class' },
          { name: 'id', value: 'item-id' }
        ]
        expect(result).to eq(expected)
      end
    end
  end

  describe '.build_component_for_item' do
    let(:mock_element) { double('element') }
    let(:mock_child_nodes) { double('child_nodes') }
    let(:filtered_attributes) do
      [
        { name: 'key', value: '{todo[:text]}' },
        { name: 'todo', value: '{todo[:text]}' },
        { name: 'id', value: '{todo[:id]}' }
      ]
    end

    before do
      allow(mock_element).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)
      allow(mock_child_nodes).to receive(:[]).with(:length).and_return(0)
      allow(RubyWasmUi::Template::BuildVdom).to receive(:parse_attributes).with(filtered_attributes).and_return(':key => todo[:text], :todo => todo[:text], :id => todo[:id]')
      allow(RubyWasmUi::Template::BuildVdom).to receive(:build).with(mock_child_nodes).and_return('')
    end

    it 'builds component with PascalCase name conversion' do
      result = described_class.build_component_for_item(mock_element, 'todo-item-component', filtered_attributes, 'todo')
      expect(result).to eq("RubyWasmUi::Vdom.h(TodoItemComponent, {:key => todo[:text], :todo => todo[:text], :id => todo[:id]}, [])")
    end

    it 'builds multi-word component with PascalCase name conversion' do
      result = described_class.build_component_for_item(mock_element, 'my-custom-button', filtered_attributes, 'item')
      expect(result).to eq("RubyWasmUi::Vdom.h(MyCustomButton, {:key => todo[:text], :todo => todo[:text], :id => todo[:id]}, [])")
    end

    it 'builds single word component' do
      result = described_class.build_component_for_item(mock_element, 'mycomponent', filtered_attributes, 'item')
      expect(result).to eq("RubyWasmUi::Vdom.h(Mycomponent, {:key => todo[:text], :todo => todo[:text], :id => todo[:id]}, [])")
    end
  end

  describe '.build_element_for_item' do
    let(:mock_element) { double('element') }
    let(:mock_child_nodes) { double('child_nodes') }
    let(:filtered_attributes) do
      [
        { name: 'class', value: 'item-class' },
        { name: 'id', value: '{item.id}' }
      ]
    end

    before do
      allow(mock_element).to receive(:[]).with(:childNodes).and_return(mock_child_nodes)
      allow(mock_child_nodes).to receive(:[]).with(:length).and_return(0)
      allow(RubyWasmUi::Template::BuildVdom).to receive(:parse_attributes).with(filtered_attributes).and_return(':class => \'item-class\', :id => item.id')
      allow(RubyWasmUi::Template::BuildVdom).to receive(:build).with(mock_child_nodes).and_return('')
    end

    it 'builds regular HTML element' do
      result = described_class.build_element_for_item(mock_element, 'li', filtered_attributes, 'item')
      expect(result).to eq("RubyWasmUi::Vdom.h('li', {:class => 'item-class', :id => item.id}, [])")
    end

    it 'builds HTML element with lowercase tag name' do
      result = described_class.build_element_for_item(mock_element, 'div', filtered_attributes, 'item')
      expect(result).to eq("RubyWasmUi::Vdom.h('div', {:class => 'item-class', :id => item.id}, [])")
    end
  end
end
