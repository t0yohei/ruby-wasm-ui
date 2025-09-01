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

        # If the code contains multiple top-level expressions, wrap them in a fragment
        if vdom_code.include?('end,') || (vdom_code.count(',') > 0 && !vdom_code.start_with?('['))
          vdom_code = "RubyWasmUi::Vdom.h_fragment([#{vdom_code}])"
        end

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
            if has_conditional_attribute?(element)
              # Process conditional group (r-if, r-elsif, r-else)
              conditional_group, next_index = build_conditional_group(elements, i)
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
            if has_conditional_attribute?(element)
              # Process conditional group (r-if, r-elsif, r-else)
              conditional_group, next_index = build_conditional_group(elements, i)
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

      # Check if element has conditional attributes (r-if, r-elsif, r-else)
      # @param element [JS.Object]
      # @return [Boolean]
      def has_conditional_attribute?(element)
        return false unless element[:attributes]

        length = element[:attributes][:length].to_i
        length.times do |i|
          attribute = element[:attributes][i]
          key = attribute[:name].to_s
          return true if %w[r-if r-elsif r-else].include?(key)
        end
        false
      end

      # Build conditional group (r-if, r-elsif, r-else)
      # @param elements [JS.Array] Array of elements
      # @param start_index [Integer] Starting index
      # @return [Array] [conditional_code, next_index]
      def build_conditional_group(elements, start_index)
        conditions = []
        current_index = start_index
        elements_length = elements[:length].to_i

        # Process all consecutive conditional elements
        while current_index < elements_length
          element = elements[current_index]
          # Skip text nodes (whitespace between elements)
          if element[:nodeType] == JS.global[:Node][:TEXT_NODE]
            current_index += 1
            next
          end

          # Break if this is not an element with conditional attributes
          unless element[:nodeType] == JS.global[:Node][:ELEMENT_NODE] && has_conditional_attribute?(element)
            break
          end

          conditional_type = get_conditional_type(element)

          # If we encounter a new r-if after the first one, break the group
          if conditions.any? && conditional_type == 'r-if'
            break
          end

          condition = get_conditional_expression(element)
          content = build_single_conditional_content(element)

          case conditional_type
          when 'r-if'
            conditions << "if #{condition}"
            conditions << "  #{content}"
          when 'r-elsif'
            conditions << "elsif #{condition}"
            conditions << "  #{content}"
          when 'r-else'
            conditions << "else"
            conditions << "  #{content}"
            current_index += 1
            break
          end

          current_index += 1
        end

        # Add final else clause if not present
        unless conditions.any? { |c| c == 'else' }
          conditions << "else"
          conditions << "  RubyWasmUi::Vdom.h_fragment([])"
        end

        conditions << "end"

        [conditions.join("\n"), current_index]
      end

      # Build content for a single conditional element
      # @param element [JS.Object]
      # @return [String]
      def build_single_conditional_content(element)
        tag_name = element[:tagName].to_s.downcase
        filtered_attributes = filter_conditional_attributes(element[:attributes])

        if tag_name == 'template' || (tag_name == 'div' && has_data_template_attribute?(element))
          # For template elements, render the content directly
          build_fragment(element, tag_name)
        elsif is_component?(tag_name)
          # For components, render the component
          build_component(element, tag_name, filtered_attributes)
        else
          # For regular HTML elements, render the element
          build_element(element, tag_name, filtered_attributes)
        end
      end

      # Get conditional expression from element attributes
      # @param element [JS.Object]
      # @return [String]
      def get_conditional_expression(element)
        length = element[:attributes][:length].to_i
        length.times do |i|
          attribute = element[:attributes][i]
          key = attribute[:name].to_s
          value = attribute[:value].to_s

          if %w[r-if r-elsif].include?(key)
            return embed_script?(value) ? get_embed_script(value) : value
          end
        end
        'true' # fallback for r-else
      end

      # Get conditional type from element attributes
      # @param element [JS.Object]
      # @return [String]
      def get_conditional_type(element)
        length = element[:attributes][:length].to_i
        length.times do |i|
          attribute = element[:attributes][i]
          key = attribute[:name].to_s
          return key if %w[r-if r-elsif r-else].include?(key)
        end
        'r-if' # fallback
      end

      # Filter out conditional attributes from the attributes list
      # @param attributes [JS.Object]
      # @return [Array]
      def filter_conditional_attributes(attributes)
        filtered = []
        length = attributes[:length].to_i
        length.times do |i|
          attribute = attributes[i]
          key = attribute[:name].to_s
          unless %w[r-if r-elsif r-else data-template].include?(key)
            filtered << attribute
          end
        end
        filtered
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
        children = build_vdom(content_nodes)
        "RubyWasmUi::Vdom.h_fragment([#{children}])"
      end

      # Build component element
      # @param element [JS.Object]
      # @param tag_name [String]
      # @param filtered_attributes [Array]
      # @return [String]
      def build_component(element, tag_name, filtered_attributes = nil)
        attributes_str = parse_attributes(filtered_attributes || element[:attributes].to_a)
        children = build_vdom(element[:childNodes])

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
        children = build_vdom(element[:childNodes])

        "RubyWasmUi::Vdom.h('#{tag_name}', {#{attributes_str}}, [#{children}])"
      end
    end
  end
end
