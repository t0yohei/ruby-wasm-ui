# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruwi::Utils::Props do
  describe '.extract_props_and_events' do
    context 'when vdom has props with events using symbol key' do
      it 'separates props and events correctly' do
        click_handler = proc { puts 'clicked' }
        vdom = Ruwi::Vdom.new(
          'div',
          {
            :on => { :click => click_handler },
            :class => 'container',
            :id => 'main'
          },
          Ruwi::Vdom::DOM_TYPES[:ELEMENT],
          [],
          nil
        )

        result = described_class.extract_props_and_events(vdom)

        expect(result[:props]).to eq({ :class => 'container', :id => 'main' })
        expect(result[:events]).to eq({ :click => click_handler })
      end
    end

    context 'when vdom has props with events using string key' do
      it 'separates props and events correctly' do
        click_handler = proc { puts 'clicked' }
        vdom = Ruwi::Vdom.new(
          'div',
          {
            "on" => { :click => click_handler },
            :class => 'container',
            :id => 'main'
          },
          Ruwi::Vdom::DOM_TYPES[:ELEMENT],
          [],
          nil
        )

        result = described_class.extract_props_and_events(vdom)

        expect(result[:props]).to eq({ :class => 'container', :id => 'main' })
        expect(result[:events]).to eq({ :click => click_handler })
      end
    end

    context 'when vdom has props without events' do
      it 'returns all props as props and empty events' do
        vdom = Ruwi::Vdom.new(
          'div',
          {
            :class => 'container',
            :id => 'main',
            :style => 'color: red'
          },
          Ruwi::Vdom::DOM_TYPES[:ELEMENT],
          [],
          nil
        )

        result = described_class.extract_props_and_events(vdom)

        expect(result[:props]).to eq({
          :class => 'container',
          :id => 'main',
          :style => 'color: red'
        })
        expect(result[:events]).to eq({})
      end
    end

    context 'when vdom has empty props' do
      it 'returns empty props and events' do
        vdom = Ruwi::Vdom.new(
          'div',
          {},
          Ruwi::Vdom::DOM_TYPES[:ELEMENT],
          [],
          nil
        )

        result = described_class.extract_props_and_events(vdom)

        expect(result[:props]).to eq({})
        expect(result[:events]).to eq({})
      end
    end

    context 'when vdom.props is nil' do
      it 'returns empty props and events' do
        vdom = Ruwi::Vdom.new(
          'div',
          nil,
          Ruwi::Vdom::DOM_TYPES[:ELEMENT],
          [],
          nil
        )

        result = described_class.extract_props_and_events(vdom)

        expect(result[:props]).to eq({})
        expect(result[:events]).to eq({})
      end
    end

    context 'when vdom is nil' do
      it 'returns empty props and events' do
        result = described_class.extract_props_and_events(nil)

        expect(result[:props]).to eq({})
        expect(result[:events]).to eq({})
      end
    end

    context 'when vdom has props with both symbol and string keys' do
      it 'prioritizes symbol key for events' do
        symbol_click_handler = proc { puts 'symbol click' }
        string_hover_handler = proc { puts 'string hover' }
        vdom = Ruwi::Vdom.new(
          'div',
          {
            :on => { :click => symbol_click_handler },
            "on" => { :hover => string_hover_handler },
            :class => 'container'
          },
          Ruwi::Vdom::DOM_TYPES[:ELEMENT],
          [],
          nil
        )

        result = described_class.extract_props_and_events(vdom)

        expect(result[:props]).to eq({ :class => 'container' })
        expect(result[:events]).to eq({ :click => symbol_click_handler })
      end
    end

    context 'when vdom has props with only on events' do
      it 'returns only events and empty props' do
        click_handler = proc { puts 'clicked' }
        hover_handler = proc { puts 'hovered' }
        vdom = Ruwi::Vdom.new(
          'div',
          {
            :on => {
              :click => click_handler,
              :hover => hover_handler
            }
          },
          Ruwi::Vdom::DOM_TYPES[:ELEMENT],
          [],
          nil
        )

        result = described_class.extract_props_and_events(vdom)

        expect(result[:props]).to eq({})
        expect(result[:events]).to eq({
          :click => click_handler,
          :hover => hover_handler
        })
      end
    end

    context 'when vdom has complex props structure' do
      it 'correctly separates complex props and events' do
        click_handler = proc { puts 'clicked' }
        mouseover_handler = proc { puts 'mouseover' }
        vdom = Ruwi::Vdom.new(
          'div',
          {
            :on => {
              :click => click_handler,
              :mouseover => mouseover_handler
            },
            :class => ['container', 'active'],
            :style => { :color => 'red', :fontSize => '16px' },
            :data_testid => 'my-component',
            :aria_label => 'Interactive element'
          },
          Ruwi::Vdom::DOM_TYPES[:ELEMENT],
          [],
          nil
        )

        result = described_class.extract_props_and_events(vdom)

        expect(result[:props]).to eq({
          :class => ['container', 'active'],
          :style => { :color => 'red', :fontSize => '16px' },
          :data_testid => 'my-component',
          :aria_label => 'Interactive element'
        })
        expect(result[:events]).to eq({
          :click => click_handler,
          :mouseover => mouseover_handler
        })
      end
    end
  end
end
