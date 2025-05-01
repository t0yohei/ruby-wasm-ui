module RubyWasmUi
  module Dom
    class DestroyDom
      # @param vdom [RubyWasmUi::H]
      def self.destroy(vdom)
        case vdom.type
        when RubyWasmUi::H::DOM_TYPES[:TEXT]
          remove_text_node(vdom)
        when RubyWasmUi::H::DOM_TYPES[:ELEMENT]
          remove_element_node(vdom)
        when RubyWasmUi::H::DOM_TYPES[:FRAGMENT]
          remove_fragment_nodes(vdom)
        else
          raise "Can't destroy DOM of type: #{vdom.type}"
        end

        vdom.el = nil
      end

      private

      def self.remove_text_node(vdom)
        vdom.el&.remove
      end

      def self.remove_element_node(vdom)
        el = vdom.el
        children = vdom.children
        listeners = vdom.listeners

        el&.remove
        children&.each { |child| destroy(child) }

        if listeners
          Events.remove_event_listeners(listeners, el)
          vdom.listeners = nil
        end
      end

      def self.remove_fragment_nodes(vdom)
        children = vdom.children
        children&.each { |child| destroy(child) }
      end
    end
  end
end
