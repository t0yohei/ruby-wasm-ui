module RubyWasmUi
  module Dom
    module DestroyDom
      # @param vdom [RubyWasmUi::Vdom]
      def execute(vdom)
        case vdom.type
        when RubyWasmUi::Vdom::DOM_TYPES[:TEXT]
          remove_text_node(vdom)
        when RubyWasmUi::Vdom::DOM_TYPES[:ELEMENT]
          remove_element_node(vdom)
        when RubyWasmUi::Vdom::DOM_TYPES[:FRAGMENT]
          remove_fragment_nodes(vdom)
        else
          raise "Can't destroy DOM of type: #{vdom.type}"
        end

        vdom.el = nil
      end

      module_function :execute

      private

      def self.remove_text_node(vdom)
        vdom.el&.remove
      end

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

      def self.remove_fragment_nodes(vdom)
        children = vdom.children
        children&.each { |child| execute(child) }
      end
    end
  end
end
