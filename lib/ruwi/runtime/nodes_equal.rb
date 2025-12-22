module Ruwi
  module NodesEqual
    module_function

    # @param node_one [Ruwi::Vdom]
    # @param node_two [Ruwi::Vdom]
    # @return [Boolean]
    def equal?(node_one, node_two)
      if node_one.type != node_two.type
        return false
      end

      if node_one.type == Ruwi::Vdom::DOM_TYPES[:ELEMENT]
        tag_one = node_one.tag
        key_one = node_one.props[:key]
        tag_two = node_two.tag
        key_two = node_two.props[:key]

        return tag_one == tag_two && key_one == key_two
      end

      if node_one.type == Ruwi::Vdom::DOM_TYPES[:COMPONENT]
        component_one = node_one.tag
        key_one = node_one.props[:key]
        component_two = node_two.tag
        key_two = node_two.props[:key]

        return component_one == component_two && key_one == key_two
      end

      if node_one.type == Ruwi::Vdom::DOM_TYPES[:TEXT]
        value_one = node_one.value
        value_two = node_two.value

        return value_one == value_two
      end

      if node_one.type == Ruwi::Vdom::DOM_TYPES[:FRAGMENT]
        return true
      end

      false
    end
  end
end
