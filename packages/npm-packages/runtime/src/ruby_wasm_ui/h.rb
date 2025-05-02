module RubyWasmUi
  class H
    DOM_TYPES = {
      TEXT: 'text',
      ELEMENT: 'element',
      FRAGMENT: 'fragment'
    }

    def initialize(tag, props = {}, children = [], type = DOM_TYPES[:ELEMENT], value = nil)
      @tag = tag
      @props = props
      @children = map_text_nodes(RubyWasmUi::Arrays.without_nulls(children))
      @type = type
      @el = nil
      @listeners = {}
      @value = value
    end

    attr_accessor :tag, :props, :children, :type, :el, :listeners, :value

    private

    def map_text_nodes(children)
      children.map { |child| child.is_a?(String) || child.is_a?(Integer) ? h_string(child) : child }
    end

    def h_string(str)
      self.class.new('', {}, [], DOM_TYPES[:TEXT], str.to_s)
    end

    def self.h_fragment(v_nodes)
      self.class.new('', {}, map_text_nodes(RubyWasmUi::Arrays.without_nulls(v_nodes)), DOM_TYPES[:FRAGMENT])
    end
  end
end
