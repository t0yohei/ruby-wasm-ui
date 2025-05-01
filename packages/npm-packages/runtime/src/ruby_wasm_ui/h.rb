module RubyWasmUi
  class H
    DOM_TYPES = {
      TEXT: 'text',
      ELEMENT: 'element',
      FRAGMENT: 'fragment'
    }

    def initialize(tag, props = {}, children = [])
      @tag = tag
      @props = props
      @children = map_text_nodes(RubyWasmUi::Arrays.without_nulls(children)),
      @type = DOM_TYPES[:ELEMENT]
    end

    private

    def map_text_nodes(children)
      children.map { |child| child.is_a?(String) ? h_string(child) : child }
    end

    def h_string(str)
      puts "h_string"
      {
        type: DOM_TYPES[:TEXT],
        value: str
      }
    end

    def self.h_fragment(v_nodes)
      {
        type: DOM_TYPES[:FRAGMENT],
        children: map_text_nodes(RubyWasmUi::Arrays.without_nulls(v_nodes))
      }
    end
  end
end
