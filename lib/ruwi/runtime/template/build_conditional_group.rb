# frozen_string_literal: true

module Ruwi
  module Template
    module BuildConditionalGroup
      module_function

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
          conditions << "  Ruwi::Vdom.h_fragment([])"
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

        if tag_name == 'template' || (tag_name == 'div' && BuildVdom.has_data_template_attribute?(element))
          # For template elements, render the content directly
          BuildVdom.build_fragment(element, tag_name)
        elsif BuildVdom.is_component?(tag_name)
          # For components, render the component
          BuildVdom.build_component(element, tag_name, filtered_attributes)
        else
          # For regular HTML elements, render the element
          BuildVdom.build_element(element, tag_name, filtered_attributes)
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
            return BuildVdom.embed_script?(value) ? BuildVdom.get_embed_script(value) : value
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
    end
  end
end
