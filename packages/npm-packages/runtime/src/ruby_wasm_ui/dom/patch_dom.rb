module RubyWasmUi
  module Dom
    module PatchDom
      # @param old_vdom [RubyWasmUi::Vdom]
      # @param new_vdom [RubyWasmUi::Vdom]
      # @param parent_el [JS::Object]
      # @param host_component [RubyWasmUi::Component, nil]
      # @return [RubyWasmUi::Vdom]
      def execute(old_vdom, new_vdom, parent_el, host_component = nil)
        if !NodesEqual.equal?(old_vdom, new_vdom)
          index = find_index_in_parent(parent_el, old_vdom.el)
          RubyWasmUi::Dom::DestroyDom.execute(old_vdom)
          RubyWasmUi::Dom::MountDom.execute(new_vdom, parent_el, index, host_component)

          return new_vdom
        end

        # when old_vdom and new_vdom is same type
        new_vdom.el = old_vdom.el

        case new_vdom.type
        when RubyWasmUi::Vdom::DOM_TYPES[:TEXT]
          patch_text(old_vdom, new_vdom)
          return new_vdom # return early and skip children patch
        when RubyWasmUi::Vdom::DOM_TYPES[:ELEMENT]
          patch_element(old_vdom, new_vdom, host_component)
        when RubyWasmUi::Vdom::DOM_TYPES[:COMPONENT]
          patch_component(old_vdom, new_vdom)
        else
          # noop
        end

        patch_children(old_vdom, new_vdom, host_component)

        new_vdom
      end

      module_function :execute

      private

      # @param parent_el [JS::Object]
      # @param el [JS::Object]
      # @return [Integer, nil]
      def self.find_index_in_parent(parent_el, el)
        index = parent_el[:childNodes].to_a.index(el)
        return nil if index.nil? || index < 0

        index
      end

      # @param old_vdom [RubyWasmUi::Vdom]
      # @param new_vdom [RubyWasmUi::Vdom]
      def self.patch_text(old_vdom, new_vdom)
        el = old_vdom.el
        old_text = old_vdom.value
        new_text = new_vdom.value

        if old_text != new_text
          el.nodeValue = new_text
        end
      end

      # @param old_vdom [RubyWasmUi::Vdom]
      # @param new_vdom [RubyWasmUi::Vdom]
      # @param host_component [RubyWasmUi::Component, nil]
      def self.patch_element(old_vdom, new_vdom, host_component)
        el = old_vdom.el

        # Extract attributes from oldVdom.props (equivalent to JavaScript destructuring)
        old_props = old_vdom.props || {}
        old_class = old_props[:class]
        old_style = old_props[:style]
        old_events = old_props[:on]
        old_attrs = old_props.reject { |key, _| [:class, :style, :on].include?(key) }

        # Extract attributes from newVdom.props
        new_props = new_vdom.props || {}
        new_class = new_props[:class]
        new_style = new_props[:style]
        new_events = new_props[:on]
        new_attrs = new_props.reject { |key, _| [:class, :style, :on].include?(key) }

        # Get listeners from oldVdom
        old_listeners = old_vdom.listeners

        patch_attrs(el, old_attrs, new_attrs)
        patch_classes(el, old_class, new_class)
        patch_styles(el, old_style, new_style)
        new_vdom.listeners = patch_events(el, old_listeners, old_events, new_events, host_component)
      end

      # @param el [JS::Object]
      # @param old_attrs [Hash]
      # @param new_attrs [Hash]
      def self.patch_attrs(el, old_attrs, new_attrs)
        diff = RubyWasmUi::Utils::Objects.diff(old_attrs, new_attrs)

        diff[:removed].each do |key|
          RubyWasmUi::Dom::Attributes.remove_attribute(el, key)
        end

        (diff[:added] + diff[:updated]).each do |key|
          RubyWasmUi::Dom::Attributes.set_attribute(el, key, new_attrs[key])
        end
      end

      # @param el [JS::Object]
      # @param old_class [String, Array]
      # @param new_class [String, Array]
      def self.patch_classes(el, old_class, new_class)
        old_classes = to_class_list(old_class)
        new_classes = to_class_list(new_class)

        diff = RubyWasmUi::Utils::Arrays.diff(old_classes, new_classes)

        diff[:removed].each do |key|
          el[:classList].remove(key)
        end

        diff[:added].each do |key|
          el[:classList].add(key)
        end
      end

      # @param el [JS::Object]
      # @param old_style [String, Array]
      # @param new_style [String, Array]
      def self.patch_styles(el, old_style = {}, new_style = {})
        diff = RubyWasmUi::Utils::Objects.diff(old_style || {}, new_style || {})

        diff[:removed].each do |key|
          RubyWasmUi::Dom::Attributes.remove_style(el, key)
        end

        (diff[:added] + diff[:updated]).each do |key|
          RubyWasmUi::Dom::Attributes.set_style(el, key, new_style[key])
        end
      end

      # @param el [JS::Object]
      # @param old_listeners [Hash]
      # @param old_events [Hash]
      # @param new_events [Hash]
      # @return [Hash]
      def self.patch_events(el, old_listeners = {}, old_events = {}, new_events = {}, host_component = nil)
        diff = RubyWasmUi::Utils::Objects.diff(old_events || {}, new_events || {})

        # Remove old event listeners for removed and updated events
        (diff[:removed] + diff[:updated]).each do |event_name|
          if old_listeners[event_name]
            el.call(:removeEventListener, event_name.to_s, old_listeners[event_name])
          end
        end

        added_listeners = {}

        # Add new event listeners for added and updated events
        (diff[:added] + diff[:updated]).each do |event_name|
          listener = RubyWasmUi::Dom::Events.add_event_listener(
            event_name,
            new_events[event_name],
            el,
            host_component
          )
          added_listeners[event_name] = listener
        end

        added_listeners
      end

      # @param old_vdom [RubyWasmUi::Vdom]
      # @param new_vdom [RubyWasmUi::Vdom]
      # @param host_component [RubyWasmUi::Component, nil]
      # @return [void]
      def self.patch_children(old_vdom, new_vdom, host_component)
        old_children = RubyWasmUi::Vdom.extract_children(old_vdom)
        new_children = RubyWasmUi::Vdom.extract_children(new_vdom)
        parent_el = old_vdom.el

        equal_proc = ->(a, b) { NodesEqual.equal?(a, b) }

        diff_seq = RubyWasmUi::Utils::Arrays.diff_sequence(old_children, new_children, equal_proc)

        diff_seq.each do |operation|
          original_index = operation[:original_index]
          index = operation[:index]
          item = operation[:item]
          offset = host_component&.offset || 0

          case operation[:op]
          when 'add'
            RubyWasmUi::Dom::MountDom.execute(item, parent_el, index + offset, host_component)
          when 'remove'
            RubyWasmUi::Dom::DestroyDom.execute(item)
          when 'move'
            old_child = old_children[original_index]
            new_child = new_children[index]
            el = old_child.el
            el_at_target_index = parent_el[:childNodes][index + offset]

            parent_el.insertBefore(el, el_at_target_index)
            RubyWasmUi::Dom::PatchDom.execute(old_child, new_child, parent_el, host_component)
          when 'noop'
            RubyWasmUi::Dom::PatchDom.execute(old_children[original_index], new_children[index], parent_el, host_component)
          end
        end
      end

      # @param classes [String, Array]
      # @return [Array]
      def self.to_class_list(classes = '')
        if classes.is_a?(Array)
          classes.select { |c| RubyWasmUi::Utils::Strings.is_not_blank_or_empty_string(c) }
        else
          # string case
          classes.to_s.split(/\s+/).select { |c| RubyWasmUi::Utils::Strings.is_not_empty_string(c) }
        end
      end

      # @param old_vdom [RubyWasmUi::Vdom]
      # @param new_vdom [RubyWasmUi::Vdom]
      # @return [void]
      def self.patch_component(old_vdom, new_vdom)
        component = old_vdom.component
        props = RubyWasmUi::Utils::Props.extract_props_and_events(new_vdom)[:props]

        component.update_props(props)

        new_vdom.component = component
        new_vdom.el = component.first_element
      end
    end
  end
end
