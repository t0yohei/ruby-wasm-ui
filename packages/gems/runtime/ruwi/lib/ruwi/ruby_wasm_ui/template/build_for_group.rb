# frozen_string_literal: true

module RubyWasmUi
  module Template
    module BuildForGroup
      module_function

      # Check if element has r-for attribute
      # @param element [JS.Object]
      # @return [Boolean]
      def has_for_attribute?(element)
        return false unless element[:attributes]

        length = element[:attributes][:length].to_i
        length.times do |i|
          attribute = element[:attributes][i]
          key = attribute[:name].to_s
          return true if key == 'r-for'
        end
        false
      end

      # Build for loop code for r-for attribute
      # @param element [JS.Object]
      # @return [String]
      def build_for_loop(element)
        for_expression = get_for_expression(element)
        return '' unless for_expression

        # Parse r-for expression like "{todo in todos}"
        # Remove curly braces and parse
        clean_expression = for_expression.gsub(/^\{|\}$/, '').strip

        # Match pattern: "item in collection"
        if clean_expression.match(/^(\w+)\s+in\s+(.+)$/)
          item_var = $1
          collection_expr = $2

          # Get the tag name and filtered attributes (excluding r-for)
          tag_name = element[:tagName].to_s.downcase
          filtered_attributes = filter_for_attributes(element[:attributes])

          # Generate the map code
          if RubyWasmUi::Template::BuildVdom.is_component?(tag_name)
            component_code = build_component_for_item(element, tag_name, filtered_attributes, item_var)
            "#{collection_expr}.map do |#{item_var}|\n  #{component_code}\nend"
          else
            element_code = build_element_for_item(element, tag_name, filtered_attributes, item_var)
            "#{collection_expr}.map do |#{item_var}|\n  #{element_code}\nend"
          end
        else
          # Fallback for invalid r-for syntax
          ''
        end
      end

      # Get r-for expression from element attributes
      # @param element [JS.Object]
      # @return [String, nil]
      def get_for_expression(element)
        length = element[:attributes][:length].to_i
        length.times do |i|
          attribute = element[:attributes][i]
          key = attribute[:name].to_s
          value = attribute[:value].to_s

          if key == 'r-for'
            return RubyWasmUi::Template::BuildVdom.embed_script?(value) ? RubyWasmUi::Template::BuildVdom.get_embed_script(value) : value
          end
        end
        nil
      end

      # Filter out r-for attribute from the attributes list
      # @param attributes [JS.Object]
      # @return [Array]
      def filter_for_attributes(attributes)
        filtered = []
        length = attributes[:length].to_i

        length.times do |i|
          attribute = attributes[i]
          key = attribute[:name].to_s
          value = attribute[:value].to_s

          # Skip r-for attribute
          next if key == 'r-for'

          # Create attribute object in the format expected by parse_attributes
          filtered << { name: key, value: value }
        end

        filtered
      end

      # Build component code for a single item in the loop
      # @param element [JS.Object]
      # @param tag_name [String]
      # @param filtered_attributes [Array]
      # @param item_var [String]
      # @return [String]
      def build_component_for_item(element, tag_name, filtered_attributes, item_var)
        attributes_str = RubyWasmUi::Template::BuildVdom.parse_attributes(filtered_attributes)
        children = RubyWasmUi::Template::BuildVdom.build(element[:childNodes])

        # Convert kebab-case to PascalCase for component name
        component_name = tag_name.split('-').map(&:capitalize).join
        "RubyWasmUi::Vdom.h(#{component_name}, {#{attributes_str}}, [#{children}])"
      end

      # Build element code for a single item in the loop
      # @param element [JS.Object]
      # @param tag_name [String]
      # @param filtered_attributes [Array]
      # @param item_var [String]
      # @return [String]
      def build_element_for_item(element, tag_name, filtered_attributes, item_var)
        attributes_str = RubyWasmUi::Template::BuildVdom.parse_attributes(filtered_attributes)
        children = RubyWasmUi::Template::BuildVdom.build(element[:childNodes])

        "RubyWasmUi::Vdom.h('#{tag_name}', {#{attributes_str}}, [#{children}])"
      end
    end
  end
end
