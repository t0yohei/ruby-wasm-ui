# frozen_string_literal: true

module RubyWasmUi
  module Template
    module Parser
      module_function

      # @param template [String]
      # @return [String]
      def parse(template)
        parser = JS.eval('return new DOMParser()')
        document = parser.call(:parseFromString, JS.try_convert(template), 'text/html')
        elements = document.getElementsByTagName('body')[0][:childNodes]

        build_vdom(elements)
      end

      # @param elements [JS.Array]
      # @return [String]
      def build_vdom(elements)
        vdom = []
        elements.forEach do |element|
          # text node
          if element[:nodeType] == JS.global[:Node][:TEXT_NODE]
            vdom << parse_text_node(element)
            next
          end

          # fragment node
          if element[:nodeType] == JS.global[:Node][:ELEMENT_NODE] && element[:tagName] == 'TEMPLATE'
            vdom << "RubyWasmUi::Vdom.h_fragment([#{build_vdom(element[:content][:childNodes])}])"
            next
          end

          # element node
          if element[:nodeType] == JS.global[:Node][:ELEMENT_NODE]
            attributes = parse_attributes(element[:attributes])
            vdom << "RubyWasmUi::Vdom.h('#{element[:tagName].to_s.downcase}', {#{attributes}}, [#{build_vdom(element[:childNodes])}])"
            next
          end
        end
        vdom.compact.join(',')
      end

      # @param element [JS.Object]
      # @return [String]
      def parse_text_node(element)
        value = element[:nodeValue].to_s.chomp.strip

        return nil if value.empty?

        return get_embed_script(value) if embed_script?(value)

        "'#{value}'"
      end

      # @param attributes [JS.Object]
      # @return [String]
      def parse_attributes(attributes)
        attributes_str = []

        # attributes is JS.Object that can't use ruby method like each
        length = attributes[:length].to_i
        length.times do |i|
          attribute = attributes[i]
          key = attribute[:name].to_s
          value = attribute[:value].to_s

          if embed_script?(value)
            attributes_str << ":#{key} => #{get_embed_script(value)}"
            next
          end

          attributes_str << ":#{key} => '#{value}'"
        end
        attributes_str.join(', ')
      end

      # @param doc [String]
      # @return [Boolean]
      def embed_script?(doc)
        doc.match?(/\{.+\}/)
      end

      # @param script [String]
      # @return [String]
      def get_embed_script(script)
        script.gsub(/\{(.+)\}/) { ::Regexp.last_match(1) }
      end
    end
  end
end
