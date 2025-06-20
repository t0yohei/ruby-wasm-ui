module RubyWasmUi
  module Dom
    class Events
      # @param event_name [String]
      # @param handler [Proc]
      # @param element [JS::Object]
      # @return [Proc]
      def self.add_event_listener(event_name, handler, element)
        element.addEventListener(event_name, handler)
        handler
      end

      def self.add_event_listeners(listeners = {}, element)
        listeners.each do |event_name, handler|
          add_event_listener(event_name, handler, element)
        end
        listeners
      end

      # @param listeners [Hash]
      # @param element [JS::Object]
      def self.remove_event_listeners(listeners = {}, element)
        listeners.each do |event_name, handler|
          element.remove_event_listener(event_name, handler)
          @events[event_name]&.delete(handler)
        end
      end
    end
  end
end
