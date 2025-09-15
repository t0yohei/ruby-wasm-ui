# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyWasmUi do
  describe '.define_component' do
    let(:render) { ->(component) { 'rendered content' } }
    let(:state) { ->(props) { { count: 0 } } }

    context 'with render proc' do
      it 'works with render proc that accepts component argument' do
        component_class = RubyWasmUi.define_component(
          render: ->(component) { 'rendered with component' }
        )
        instance = component_class.new
        expect(instance.render).to eq('rendered with component')
      end

      it 'works with render proc that accepts no arguments' do
        component_class = RubyWasmUi.define_component(
          render: -> { 'rendered without args' }
        )
        instance = component_class.new
        expect(instance.render).to eq('rendered without args')
      end
    end

    context 'with state proc' do
      it 'works with state proc that accepts props argument' do
        component_class = RubyWasmUi.define_component(
          render: -> { 'content' },
          state: ->(props) { { value: props[:initial] } }
        )
        instance = component_class.new(initial: 5)
        expect(instance.state).to eq({ value: 5 })
      end

      it 'works with state proc that accepts no arguments' do
        component_class = RubyWasmUi.define_component(
          render: -> { 'content' },
          state: -> { { value: 10 } }
        )
        instance = component_class.new
        expect(instance.state).to eq({ value: 10 })
      end
    end

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

    context 'with on_mounted parameter' do
      it 'works with on_mounted proc that accepts component argument' do
        mounted_called = false
        received_component = nil

        component_class = RubyWasmUi.define_component(
          render: -> { 'content' },
          on_mounted: ->(component) {
            mounted_called = true
            received_component = component
          }
        )

        instance = component_class.new
        instance.on_mounted

        expect(mounted_called).to be true
        expect(received_component).to eq(instance)
      end

      it 'works with on_mounted proc that accepts no arguments' do
        mounted_called = false

        component_class = RubyWasmUi.define_component(
          render: -> { 'content' },
          on_mounted: -> {
            mounted_called = true
          }
        )

        instance = component_class.new
        instance.on_mounted

        expect(mounted_called).to be true
      end

      it 'uses default empty proc when on_mounted is not provided' do
        component_class = RubyWasmUi.define_component(render: -> { 'content' })
        instance = component_class.new

        expect { instance.on_mounted }.not_to raise_error
      end
    end

    context 'with on_unmounted parameter' do
      it 'works with on_unmounted proc that accepts component argument' do
        unmounted_called = false
        received_component = nil

        component_class = RubyWasmUi.define_component(
          render: -> { 'content' },
          on_unmounted: ->(component) {
            unmounted_called = true
            received_component = component
          }
        )

        instance = component_class.new
        instance.on_unmounted

        expect(unmounted_called).to be true
        expect(received_component).to eq(instance)
      end

      it 'works with on_unmounted proc that accepts no arguments' do
        unmounted_called = false

        component_class = RubyWasmUi.define_component(
          render: -> { 'content' },
          on_unmounted: -> {
            unmounted_called = true
          }
        )

        instance = component_class.new
        instance.on_unmounted

        expect(unmounted_called).to be true
      end

      it 'uses default empty proc when on_unmounted is not provided' do
        component_class = RubyWasmUi.define_component(render: -> { 'content' })
        instance = component_class.new

        expect { instance.on_unmounted }.not_to raise_error
      end
    end
  end

  describe RubyWasmUi::Component do
    describe '#emit' do
      let(:render) { -> { 'content' } }
      let(:component_class) { RubyWasmUi.define_component(render:) }
      let(:event_name) { 'test_event' }

      context 'when dispatcher is set' do
        it 'dispatches event with payload' do
          component = component_class.new
          dispatcher = component.instance_variable_get(:@dispatcher)
          payload = { value: 42 }

          expect(dispatcher).to receive(:dispatch).with(event_name, payload)
          component.emit(event_name, payload)
        end

        it 'dispatches event without payload (nil by default)' do
          component = component_class.new
          dispatcher = component.instance_variable_get(:@dispatcher)

          expect(dispatcher).to receive(:dispatch).with(event_name, nil)
          component.emit(event_name)
        end
      end

      context 'when dispatcher is not set' do
        it 'does not raise error' do
          component = component_class.new
          component.instance_variable_set(:@dispatcher, nil)

          expect { component.emit(event_name) }.not_to raise_error
          expect { component.emit(event_name, { value: 42 }) }.not_to raise_error
        end
      end
    end

    describe '#wire_event_handler' do
      let(:render) { -> { 'content' } }
      let(:component_class) { RubyWasmUi.define_component(render:) }
      let(:event_name) { 'test_event' }
      let(:parent_component) { component_class.new }

      context 'with parent component' do
        it 'handles event with payload when handler has arity of 1' do
          handler = ->(payload) { payload[:value] * 2 }
          component = component_class.new({}, { event_name => handler }, parent_component)
          subscription = component.send(:wire_event_handler, event_name, handler)
          expect(subscription).to be_a(Proc)
        end

        it 'handles event without payload when handler has arity of 0' do
          handler = -> { 'no payload' }
          component = component_class.new({}, { event_name => handler }, parent_component)
          subscription = component.send(:wire_event_handler, event_name, handler)
          expect(subscription).to be_a(Proc)
        end
      end

      context 'without parent component' do
        it 'handles event with payload when handler has arity of 1' do
          handler = ->(payload) { payload[:value] * 2 }
          component = component_class.new({}, { event_name => handler })
          subscription = component.send(:wire_event_handler, event_name, handler)
          expect(subscription).to be_a(Proc)
        end

        it 'handles event without payload when handler has arity of 0' do
          handler = -> { 'no payload' }
          component = component_class.new({}, { event_name => handler })
          subscription = component.send(:wire_event_handler, event_name, handler)
          expect(subscription).to be_a(Proc)
        end
      end

      it 'returns a no-op unsubscription when subscription is nil' do
        allow_any_instance_of(RubyWasmUi::Dispatcher).to receive(:subscribe).and_return(nil)
        handler = -> { 'test' }
        component = component_class.new({}, { event_name => handler })
        subscription = component.send(:wire_event_handler, event_name, handler)
        expect(subscription).to be_a(Proc)
        expect { subscription.call }.not_to raise_error
      end
    end
  end
end
