module RubyWasmUi
  class Vdom
    DOM_TYPES = {
      TEXT: 'text',
      ELEMENT: 'element',
      FRAGMENT: 'fragment',
      COMPONENT: 'component'
    }

    # @param tag [String]
    # @param props [Hash]
    # @param children [Array]
    # @param type [Symbol]
    # @param value [Object]
    # @return [Vdom]
    def self.h(tag, props = {}, children = [])
      type = tag.is_a?(String) ? DOM_TYPES[:ELEMENT] : DOM_TYPES[:COMPONENT]
      new(tag, props, type, children, nil)
    end

    # @param str [String]
    # @return [Vdom]
    def self.h_string(str)
      vdom = new('', {}, DOM_TYPES[:TEXT], [], str.to_s)
      vdom
    end

    # @param vdoms [Array]
    # @return [Vdom]
    def self.h_fragment(vdoms)
      new('', {}, DOM_TYPES[:FRAGMENT], map_text_nodes(RubyWasmUi::Utils::Arrays.without_nulls(vdoms)), nil)
    end

    # @param type [Symbol]
    # @param props [Hash]
    # @param children [Array]
    # @param value [Object]
    # @return [Vdom]
    def initialize(tag, props, type, children, value)
      @tag = tag
      @props = props
      @children = self.class.map_text_nodes(RubyWasmUi::Utils::Arrays.without_nulls(children))
      @type = type
      @value = value.to_s
      @el = nil
      @listeners = {}
      @component = nil
    end

    attr_reader :tag, :props, :children, :type, :value
    attr_accessor :el, :listeners, :component

    private

    # @param children [Array]
    def self.map_text_nodes(children)
      children.map { |child| is_text_node?(child) ? h_string(child) : child }
    end

    # @param child [Object]
    # @return [Boolean]
    def self.is_text_node?(child)
      child.is_a?(String) || child.is_a?(Integer) || child.is_a?(JS::Object)
    end

    # @param vdom [Vdom]
    # @return [Array]
    def self.extract_children(vdom)
      return [] if vdom.children.nil?

      children = []

      vdom.children.each do |child|
        if child.type == DOM_TYPES[:FRAGMENT]
          children.concat(extract_children(child))
        else
          children << child
        end
      end

      children
    end
  end
end
