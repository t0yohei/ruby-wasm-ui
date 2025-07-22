# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyWasmUi do
  describe '.define_component' do
    let(:render) { ->(component) { 'rendered content' } }
    let(:state) { ->(props) { { count: 0 } } }

    context 'with methods parameter' do
      it 'successfully adds custom methods to the component' do
        custom_methods = {
          increment: -> { @state[:count] += 1 },
          get_double_count: -> { @state[:count] * 2 }
        }

        component_class = RubyWasmUi.define_component(
          render:,
          state:,
          methods: custom_methods
        )

        instance = component_class.new

        expect(instance).to respond_to(:increment)
        expect(instance).to respond_to(:get_double_count)

        # Test the custom methods work correctly
        expect(instance.get_double_count).to eq(0)
        instance.increment
        expect(instance.state[:count]).to eq(1)
        expect(instance.get_double_count).to eq(2)
      end

      it 'raises error when method name conflicts with existing method' do
        custom_methods = {
          render: -> { 'custom render' }  # conflicts with existing render method
        }

        expect {
          RubyWasmUi.define_component(
            render:,
            methods: custom_methods
          )
        }.to raise_error(/Method "render\(\)" already exists in the component\./)
      end

      it 'raises error when method name conflicts with private method' do
        custom_methods = {
          patch: -> { 'custom patch' }  # conflicts with existing private method
        }

        expect {
          RubyWasmUi.define_component(
            render:,
            methods: custom_methods
          )
        }.to raise_error(/Method "patch\(\)" already exists in the component\./)
      end

      it 'works correctly with empty methods hash' do
        component_class = RubyWasmUi.define_component(
          render:,
          methods: {}
        )

        instance = component_class.new
        expect(instance).to be_a(RubyWasmUi::Component)
      end

      it 'allows method names as strings' do
        custom_methods = {
          'string_method' => -> { 'method called' }
        }

        component_class = RubyWasmUi.define_component(
          render:,
          methods: custom_methods
        )

        instance = component_class.new
        expect(instance).to respond_to('string_method')
        expect(instance.string_method).to eq('method called')
      end
    end

    context 'without methods parameter' do
      it 'creates component successfully when methods is not provided' do
        component_class = RubyWasmUi.define_component(render:)

        instance = component_class.new
        expect(instance).to be_a(RubyWasmUi::Component)
      end
    end
  end
end
