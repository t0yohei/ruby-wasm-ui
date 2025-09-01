# frozen_string_literal: true

module RubyWasmUi
  module Template
    module BuildVdom
      module_function

      # @param elements [JS.Array]
      # @return [String]
      def build(elements)
        vdom = []
        i = 0
        elements_length = elements[:length].to_i

        while i < elements_length
          element = elements[i]

          # text node
          if element[:nodeType] == JS.global[:Node][:TEXT_NODE]
            text_result = parse_text_node(element)
            vdom << text_result if text_result
            i += 1
            next
          end

          tag_name = element[:tagName].to_s.downcase

          # fragment node (including div elements with data-template attribute)
          if element[:nodeType] == JS.global[:Node][:ELEMENT_NODE] && (tag_name == 'template' || (tag_name == 'div' && has_data_template_attribute?(element)))
            # Check for conditional attributes on template
            if RubyWasmUi::Template::BuildConditionalGroup.has_conditional_attribute?(element)
              # Process conditional group (r-if, r-elsif, r-else)
              conditional_group, next_index = RubyWasmUi::Template::BuildConditionalGroup.build_conditional_group(elements, i)
              vdom << conditional_group
              i = next_index
            else
              vdom << build_fragment(element, tag_name)
              i += 1
            end
            next
          end

          # element node (including components)
          if element[:nodeType] == JS.global[:Node][:ELEMENT_NODE]
            # Check for conditional attributes on all elements (including components)
            if RubyWasmUi::Template::BuildConditionalGroup.has_conditional_attribute?(element)
              # Process conditional group (r-if, r-elsif, r-else)
              conditional_group, next_index = RubyWasmUi::Template::BuildConditionalGroup.build_conditional_group(elements, i)
              vdom << conditional_group
              i = next_index
            else
              # Handle components and regular elements
              if is_component?(tag_name)
                vdom << build_component(element, tag_name)
              else
                vdom << build_element(element, tag_name)
              end
              i += 1
            end
            next
          end

          i += 1
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

      # Parse attributes array
      # @param attributes [Array]
      # @return [String]
      def parse_attributes(attributes)
        attributes_str = []

        attributes.each do |attribute|
          key = attribute[:name].to_s
          value = attribute[:value].to_s

          if embed_script?(value)
            # Special handling for 'on' attribute to preserve hash structure
            if key == 'on'
              attributes_str << ":#{key} => #{value}"
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

      # Build fragment or div element with data-template attribute
      # @param element [JS.Object]
      # @param tag_name [String]
      # @return [String]
      def build_fragment(element, tag_name)
        # div elements with data-template don't have content property, use childNodes directly
        if tag_name == 'template' && element[:content]
          content_nodes = element[:content][:childNodes]
        else
          content_nodes = element[:childNodes]
        end
        children = build(content_nodes)
        "RubyWasmUi::Vdom.h_fragment([#{children}])"
      end

      # Build component element
      # @param element [JS.Object]
      # @param tag_name [String]
      # @param filtered_attributes [Array]
      # @return [String]
      def build_component(element, tag_name, filtered_attributes = nil)
        attributes_str = parse_attributes(filtered_attributes || element[:attributes].to_a)
        children = build(element[:childNodes])

        # Convert kebab-case to PascalCase for component name
        component_name = tag_name.split('-').map(&:capitalize).join
        "RubyWasmUi::Vdom.h(#{component_name}, {#{attributes_str}}, [#{children}])"
      end

      # Build regular HTML element
      # @param element [JS.Object]
      # @param tag_name [String]
      # @param filtered_attributes [Array]
      # @return [String]
      def build_element(element, tag_name, filtered_attributes = nil)
        attributes_str = parse_attributes(filtered_attributes || element[:attributes].to_a)
        children = build(element[:childNodes])

        "RubyWasmUi::Vdom.h('#{tag_name}', {#{attributes_str}}, [#{children}])"
      end
    end
  end
end
