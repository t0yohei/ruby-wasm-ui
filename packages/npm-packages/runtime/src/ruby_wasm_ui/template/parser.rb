# frozen_string_literal: true

module RubyWasmUi
  module Template
    module Parser
      module_function

      def parse(template)
        parser = JS.eval('return new DOMParser()')
        document = parser.call(:parseFromString, JS.try_convert(template), 'text/html')
        elements = document.getElementsByTagName('body')[0][:childNodes]

        build_vdom(elements)
      end

      def build_vdom(elements)
        vdom = []
        elements.forEach do |element|
          if element[:nodeType] == JS.global[:Node][:TEXT_NODE]
            value = element[:nodeValue].to_s.chomp.strip

            next if value.empty?

            vdom << if embed_script?(value)
                      get_embed_script(value)
                    else
                      "'#{value}'"
                    end

            next
          end

          if element[:nodeType] == JS.global[:Node][:ELEMENT_NODE]
            if element[:tagName] == 'TEMPLATE'
              vdom << "RubyWasmUi::Vdom.h_fragment([#{build_vdom(element[:content][:childNodes])}])"
              next
            end
          end

          attributes_str = []
          attributes = element[:attributes]
          length = attributes[:length].to_i
          length.times do |i|
            attribute = attributes[i]
            key = attribute[:name].to_s
            value = attribute[:value].to_s

            result = if embed_script?(value)
                        script = get_embed_script(value)
                        ":#{key} => #{script}"
                      else
                        ":#{key} => '#{value}'"
                      end
            attributes_str << result
          end

          vdom << "RubyWasmUi::Vdom.h('#{element[:tagName].to_s.downcase}', {#{attributes_str.join(', ')}}, [#{build_vdom(element[:childNodes])}])"
        end
        vdom.join(',')
      end

      def embed_script?(doc)
        doc.match?(/\{.+\}/)
      end

      def get_embed_script(script)
        script.gsub(/\{(.+)\}/) { ::Regexp.last_match(1) }
      end
    end
  end
end
