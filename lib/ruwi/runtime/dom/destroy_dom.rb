module Ruwi
  module Dom
    module DestroyDom
      # @param vdom [Ruwi::Vdom]
      def execute(vdom)
        case vdom.type
        when Ruwi::Vdom::DOM_TYPES[:TEXT]
          remove_text_node(vdom)
        when Ruwi::Vdom::DOM_TYPES[:ELEMENT]
          remove_element_node(vdom)
        when Ruwi::Vdom::DOM_TYPES[:FRAGMENT]
          remove_fragment_nodes(vdom)
        when Ruwi::Vdom::DOM_TYPES[:COMPONENT]
          remove_component_node(vdom)
        else
          raise "Can't destroy DOM of type: #{vdom.type}"
        end

        vdom.el = nil
      end

      module_function :execute

      private

      # @param vdom [Ruwi::Vdom]
      # @return [void]
      def self.remove_text_node(vdom)
        vdom.el&.remove
      end

      # @param vdom [Ruwi::Vdom]
      # @return [void]
      def self.remove_element_node(vdom)
        el = vdom.el
        children = vdom.children
        listeners = vdom.listeners

        el&.remove
        children&.each { |child| execute(child) }

        if listeners
          Events.remove_event_listeners(listeners, el)
          vdom.listeners = nil
        end
      end

      # @param vdom [Ruwi::Vdom]
      # @return [void]
      def self.remove_fragment_nodes(vdom)
        children = vdom.children
        children&.each { |child| execute(child) }
      end

      # @param vdom [Ruwi::Vdom]
      # @return [void]
      def self.remove_component_node(vdom)
        vdom.component.unmount
        Ruwi::Dom::Scheduler.enqueue_job(-> { vdom.component.on_unmounted })
      end
    end
  end
end
