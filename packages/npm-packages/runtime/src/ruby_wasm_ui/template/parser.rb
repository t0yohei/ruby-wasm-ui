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

      # parse text node
      # ex) "test" -> "test"
      # ex) "test {state[:count]}" -> "test #{state[:count]}"
      # ex) "test {state[:count] + 1}" -> "test #{state[:count] + 1}"
      # ex) "test {state[:count]} test" -> "test #{state[:count]} test"
      # ex) "test {state[:count]} test {state[:count]} test" -> "test #{state[:count]} test #{state[:count]} test"
      # @param element [JS.Object]
      # @return [String]
      def parse_text_node(element)
        value = element[:nodeValue].to_s.chomp.strip

        return nil if value.empty?

        # Split the text by embedded script pattern and process each part
        # Regular expression explanation:
        # (        : Start capture group (this ensures the pattern itself is included in the result)
        #  \{      : Match an opening curly brace (escaped because { is special in regex)
        #  [^}]+   : Match one or more characters that are not a closing curly brace
        #  \}      : Match a closing curly brace (escaped because } is special in regex)
        # )        : End capture group
        # Example:
        #   Input:  "hello {state[:count]} world"
        #   Output: ["hello ", "{state[:count]}", " world"]
        parts = value.split(/(\{[^}]+\})/)
        processed_parts = parts.map do |part|
          if embed_script?(part)
            "\#{#{get_embed_script(part)}}"
          else
            part
          end
        end

        # Join all parts and wrap in double quotes
        %("#{processed_parts.join}")
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
            # Special handling for 'on' attribute to preserve hash structure
            if key == 'on'
              # Extract the hash content and ensure it's wrapped properly
              hash_content = get_embed_script(value)
              attributes_str << ":#{key} => { #{hash_content} }"
            else
              attributes_str << ":#{key} => #{get_embed_script(value)}"
            end
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

      # get value from embed script
      # ex) Count: {component.state[:count]} -> Count: component.state[:count]
      # @param script [String]
      # @return [String]
      def get_embed_script(script)
        script.gsub(/\{(.+)\}/) { ::Regexp.last_match(1) }
      end
    end
  end
end
