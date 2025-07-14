module RubyWasmUi
  module Dom
    module Events
      module_function

      # @param event_name [String]
      # @param handler [Proc]
      # @param element [JS::Object]
      # @return [Proc]
      def add_event_listener(event_name, handler, element)
        call_handler = JS.try_convert(->(event) { handler.call(event) })
        element.call(:addEventListener, event_name.to_s, call_handler)
        call_handler
      end

      def add_event_listeners(listeners = {}, element)
        listeners.each do |event_name, handler|
          add_event_listener(event_name, handler, element)
        end
        listeners
      end

      # @param listeners [Hash]
      # @param element [JS::Object]
      def remove_event_listeners(listeners = {}, element)
        listeners.each do |event_name, handler|
          element.call(:removeEventListener, event_name.to_s, handler)
        end
      end
    end
  end
end
