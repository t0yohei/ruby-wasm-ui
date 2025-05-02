module RubyWasmUi
  class Vdom
    DOM_TYPES = {
      TEXT: 'text',
      ELEMENT: 'element',
      FRAGMENT: 'fragment'
    }

    # @param tag [String]
    # @param props [Hash]
    # @param children [Array]
    # @param type [Symbol]
    # @return [Vdom]
    def self.h(tag, props = {}, children = [], type = DOM_TYPES[:ELEMENT])
      new(tag, props, children, type)
    end

    # @param str [String]
    # @return [Vdom]
    def self.h_string(str)
      vdom = new('', {}, [], DOM_TYPES[:TEXT])
      vdom.value = str.to_s
      vdom
    end

    # @param vdoms [Array]
    # @return [Vdom]
    def self.h_fragment(vdoms)
      new('', {}, map_text_nodes(RubyWasmUi::Arrays.without_nulls(vdoms)), DOM_TYPES[:FRAGMENT])
    end

    # @param type [Symbol]
    # @param props [Hash]
    # @param children [Array]
    def initialize(tag, props, children, type)
      @tag = tag
      @props = props
      @children = map_text_nodes(RubyWasmUi::Arrays.without_nulls(children))
      @type = type
      @value = nil
      @el = nil
      @listeners = {}
    end

    attr_reader :tag, :props, :children, :type
    attr_accessor :el, :listeners, :value

    private

    # @param children [Array]
    def map_text_nodes(children)
      children.map { |child| is_text_node?(child) ? self.class.h_string(child) : child }
    end

    # @param child [Object]
    # @return [Boolean]
    def is_text_node?(child)
      child.is_a?(String) || child.is_a?(Integer)
    end
  end
end
