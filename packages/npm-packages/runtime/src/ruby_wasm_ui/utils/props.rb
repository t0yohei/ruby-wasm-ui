module RubyWasmUi
  module Utils
    module Props
      module_function

      # Extract props and events from vdom
      # Equivalent to JavaScript: const { on: events = {}, ...props } = vdom.props;
      # @param vdom [RubyWasmUi::Vdom]
      # @return [Hash]
      def extract_props_and_events(vdom)
        return { props: {}, events: {} } unless vdom&.props

        all_props = vdom.props || {}
        events = all_props[:on] || all_props["on"] || {}

        # Create props hash excluding the 'on' key
        props = all_props.reject { |key, _| key == :on || key == "on" }

        { props:, events: }
      end
    end
  end
end
