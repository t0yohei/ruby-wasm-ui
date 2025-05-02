module RubyWasmUi
  module Dom
    class MountDom
      # @param vdom [RubyWasmUi::H]
      # @param parent_el [JS::Object]
      def self.execute(vdom, parent_el)
        case vdom.type
        when RubyWasmUi::H::DOM_TYPES[:TEXT]
          create_text_node(vdom, parent_el)
        when RubyWasmUi::H::DOM_TYPES[:ELEMENT]
          create_element_node(vdom, parent_el)
        when RubyWasmUi::H::DOM_TYPES[:FRAGMENT]
          create_fragment_nodes(vdom, parent_el)
        else
          raise "Can't mount DOM of type: #{vdom.type}"
        end
      end

      private

      def self.create_text_node(vdom, parent_el)
        text_node = JS.global[:document].createTextNode(vdom.value)
        vdom.el = text_node
        parent_el.append(text_node)
      end

      def self.create_element_node(vdom, parent_el)
        element = JS.global[:document].createElement(vdom.tag)
        add_props(element, vdom.props, vdom)
        vdom.el = element

        vdom.children&.each do |child|
          execute(child, element)
        end

        parent_el.append(element)
      end

      def self.add_props(el, props, vdom)
        return unless props

        events = props.delete(:on)
        attrs = props

        vdom.listeners = Events.add_event_listeners(events, el) if events
        Attributes.new(el).set_attributes(attrs) if attrs.any?
      end

      def self.create_fragment_nodes(vdom, parent_el)
        vdom.el = parent_el

        vdom.children&.each do |child|
          execute(child, parent_el)
        end
      end
    end
  end
end
