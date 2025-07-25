module RubyWasmUi
  module Dom
    module MountDom
      # @param vdom [RubyWasmUi::Vdom]
      # @param parent_el [JS::Object]
      # @param index [Integer, nil] Index position to insert at
      # @param hostComponent [RubyWasmUi::Component, nil] Host component
      def execute(vdom, parent_el, index = nil, hostComponent = nil)
        case vdom.type
        when RubyWasmUi::Vdom::DOM_TYPES[:TEXT]
          create_text_node(vdom, parent_el, index)
        when RubyWasmUi::Vdom::DOM_TYPES[:ELEMENT]
          create_element_node(vdom, parent_el, index, hostComponent)
        when RubyWasmUi::Vdom::DOM_TYPES[:FRAGMENT]
          create_fragment_nodes(vdom, parent_el, index, hostComponent)
        when RubyWasmUi::Vdom::DOM_TYPES[:COMPONENT]
          create_component_node(vdom, parent_el, index, hostComponent)
        else
          raise "Can't mount DOM of type: #{vdom.type}"
        end
      end

      # @param el [JS::Object] Element to insert
      # @param parent_el [JS::Object] Parent element
      # @param index [Integer, nil] Index position to insert at
      def insert(el, parent_el, index)
        # If index is nil or undefined, simply append to the end
        if index.nil?
          parent_el.append(el)
          return
        end

        # If index is negative, raise an error
        if index < 0
          raise "Index must be a positive integer, got #{index}"
        end

        children = parent_el[:childNodes]

        # If index is greater than or equal to the number of children, append to the end
        if index >= children[:length].to_i # to_i is necessary because length is a JS::Number
          parent_el.append(el)
        else
          # Insert at the specified index position
          parent_el.insertBefore(el, children[index])
        end
      end

      module_function :execute, :insert

      private

      def self.create_text_node(vdom, parent_el, index)
        text_node = JS.global[:document].createTextNode(vdom.value)
        vdom.el = text_node
        insert(text_node, parent_el, index)
      end

      def self.create_element_node(vdom, parent_el, index, hostComponent)
        element = JS.global[:document].createElement(vdom.tag)
        add_props(element, vdom, hostComponent)
        vdom.el = element

        vdom.children&.each do |child|
          execute(child, element, nil, hostComponent)
        end

        insert(element, parent_el, index)
      end

      # @param el [JS::Object] Element to add props to
      # @param vdom [RubyWasmUi::Vdom] VDOM node
      # @param hostComponent [RubyWasmUi::Component, nil] Host component
      def self.add_props(el, vdom, hostComponent)
        extracted = RubyWasmUi::Utils::Props.extract_props_and_events(vdom)
        events = extracted[:events]
        attrs = extracted[:props]

        vdom.listeners = Events.add_event_listeners(el, events, hostComponent) if events
        RubyWasmUi::Dom::Attributes.set_attributes(el, attrs) if attrs.any?
      end

      def self.create_fragment_nodes(vdom, parent_el, index, hostComponent)
        vdom.el = parent_el

        vdom.children&.each_with_index do |child, i|
          execute(child, parent_el, index ? index + i : nil, hostComponent)
        end
      end

      # @param vdom [RubyWasmUi::Vdom]
      # @param parent_el [JS::Object] Parent element
      # @param index [Integer, nil] Index position to insert at
      # @param host_component [RubyWasmUi::Component, nil] Host component
      # @return [void]
      def self.create_component_node(vdom, parent_el, index, host_component)
        component_class = vdom.tag
        extracted = RubyWasmUi::Utils::Props.extract_props_and_events(vdom)
        component = component_class.new(extracted[:props], extracted[:events], host_component)

        component.mount(parent_el, index)
        vdom.component = component
        vdom.el = component.first_element
      end
    end
  end
end
