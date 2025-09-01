# frozen_string_literal: true

module RubyWasmUi
  module Template
    module Parser
      module_function

      # @param template [String]
      # @param binding [Binding]
      # @return [RubyWasmUi::Vdom]
      def parse_and_eval(template, binding)
        vdom_code = parse(template)
        eval(vdom_code, binding)
      end

      # @param template [String]
      # @return [String]
      def parse(template)
        # Preprocess self-closing custom element tags
        processed_template = preprocess_self_closing_tags(template)

        # Replace <template> with <div data-template> to work around DOMParser limitations
        processed_template = processed_template.gsub(/<template\s/, '<div data-template ')
        processed_template = processed_template.gsub(/<template>/, '<div data-template>')
        processed_template = processed_template.gsub(/<\/template>/, '</div>')

        parser = JS.eval('return new DOMParser()')
        document = parser.call(:parseFromString, JS.try_convert(processed_template), 'text/html')
        elements = document.getElementsByTagName('body')[0][:childNodes]

        build_vdom(elements)
      end

      # Convert self-closing custom element tags to regular tags
      # Custom elements are identified by having hyphens in their name
      # Standard void elements (img, input, etc.) are not converted
      # @param template [String]
      # @return [String]
      def preprocess_self_closing_tags(template)
        # Pattern matches: <tag-name attributes />
        # Where tag-name contains at least one hyphen (custom element convention)
        # Use a more robust pattern that handles nested brackets and quotes
        template.gsub(/<([a-z]+(?:-[a-z]+)+)((?:[^>]|"[^"]*"|'[^']*')*?)\/>/i) do
          tag_name = ::Regexp.last_match(1)
          attributes = ::Regexp.last_match(2)

          # Convert to regular open/close tags
          "<#{tag_name}#{attributes}></#{tag_name}>"
        end
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

          tag_name = element[:tagName].to_s.downcase

          # fragment node
          if element[:nodeType] == JS.global[:Node][:ELEMENT_NODE] && tag_name == 'template'
            vdom << "RubyWasmUi::Vdom.h_fragment([#{build_vdom(element[:content][:childNodes])}])"
            next
          end

          # fragment node (including div elements with data-template attribute)
          if element[:nodeType] == JS.global[:Node][:ELEMENT_NODE] && (tag_name == 'template' || (tag_name == 'div' && has_data_template_attribute?(element)))
            # div elements with data-template don't have content property, use childNodes directly
            if tag_name == 'template' && element[:content]
              content_nodes = element[:content][:childNodes]
            else
              content_nodes = element[:childNodes]
            end
            vdom << "RubyWasmUi::Vdom.h_fragment([#{build_vdom(content_nodes)}])"
            next
          end

          if element[:nodeType] == JS.global[:Node][:ELEMENT_NODE] && is_component?(tag_name)
            # Convert kebab-case to PascalCase for component name
            component_name = tag_name.split('-').map(&:capitalize).join
            attributes = parse_attributes(element[:attributes])
            children = build_vdom(element[:childNodes])
            vdom << "RubyWasmUi::Vdom.h(#{component_name}, {#{attributes}}, [#{children}])"
            next
          end

          # element node
          if element[:nodeType] == JS.global[:Node][:ELEMENT_NODE]
            attributes = parse_attributes(element[:attributes])
            children = build_vdom(element[:childNodes])
            vdom << "RubyWasmUi::Vdom.h('#{tag_name}', {#{attributes}}, [#{children}])"
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

      # @param tag_name [String]
      # @return [Boolean]
      def is_component?(tag_name)
        # Component tags start with  letter but exclude standard HTML elements
        return false unless tag_name.match?(/^[a-z]/)

        # List of standard HTML elements (case-sensitive comparison)
        # List of standard HTML elements in lowercase for case-insensitive comparison
        html_elements = %w[
          a abbr address area article aside audio b base bdi bdo blockquote body br button
          canvas caption cite code col colgroup data datalist dd del details dfn dialog div dl dt
          em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 head header hgroup hr html
          i iframe img input ins kbd label legend li link main map mark menu meta meter nav noscript
          object ol optgroup option output p param picture pre progress q rp rt ruby s samp script
          section select small source span strong style sub summary sup table tbody td template
          textarea tfoot th thead time title tr track u ul var video wbr
        ]

        # Convert tag_name to lowercase for case-insensitive comparison with standard HTML elements
        !html_elements.include?(tag_name)
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

      # Check if element has data-template attribute
      # @param element [JS.Object]
      # @return [Boolean]
      def has_data_template_attribute?(element)
        return false unless element[:attributes]

        length = element[:attributes][:length].to_i
        length.times do |i|
          attribute = element[:attributes][i]
          key = attribute[:name].to_s
          return true if key == 'data-template'
        end
        false
      end
    end
  end
end
