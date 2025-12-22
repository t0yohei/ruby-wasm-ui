module Ruwi
  module Dom
    module Events
      module_function

      # @param event_name [String]
      # @param handler [Proc]
      # @param element [JS::Object]
      # @param host_component [Object, nil]
      # @return [Proc]
      def add_event_listener(event_name, handler, element, host_component = nil)
        if host_component
          # Same as JavaScript's handler.apply(hostComponent, arguments)
          call_handler = JS.try_convert(->(event) {
            handler.arity == 0 ? host_component.instance_exec(&handler) : host_component.instance_exec(event, &handler)
          })
        else
          call_handler = JS.try_convert(->(event) { handler.arity == 0 ? handler.call : handler.call(event) })
        end
        element.call(:addEventListener, event_name.to_s, call_handler)
        call_handler
      end

      def add_event_listeners(element, listeners = {}, host_component = nil)
        listeners.each do |event_name, handler|
          add_event_listener(event_name, handler, element, host_component)
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
