module RubyWasmUi
  module NodesEqual
    module_function

    # @param node_one [RubyWasmUi::Vdom]
    # @param node_two [RubyWasmUi::Vdom]
    # @return [Boolean]
    def equal?(node_one, node_two)
      if node_one.type != node_two.type
        return false
      end

      if node_one.type == RubyWasmUi::Vdom::DOM_TYPES[:ELEMENT]
        tag_one = node_one.tag
        tag_two = node_two.tag

        return tag_one == tag_two
      end

      if node_one.type == RubyWasmUi::Vdom::DOM_TYPES[:TEXT]
        value_one = node_one.value
        value_two = node_two.value

        return value_one == value_two
      end

      if node_one.type == RubyWasmUi::Vdom::DOM_TYPES[:FRAGMENT]
        return true
      end

      false
    end
  end
end
