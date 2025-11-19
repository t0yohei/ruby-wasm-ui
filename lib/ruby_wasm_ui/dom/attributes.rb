module RubyWasmUi
  module Dom
    module Attributes
      module_function

      # @param element [JS::Object]
      # @param attrs [Hash]
      def set_attributes(element, attrs)
        class_name = attrs[:class]
        style = attrs[:style]
        other_attrs = attrs.reject { |key, _| [:class, :style].include?(key) }

        if class_name
          set_class(element, class_name)
        end

        if style
          parse_style(style).each do |name, value|
            set_style(element, name, value)
          end
        end

        other_attrs.each do |name, value|
          set_attribute(element, name, value)
        end
      end

      # @param element [JS::Object]
      # @param class_name [String, Array]
      def set_class(element, class_name)
        element[:className] = ""

        case class_name
        when String
          element[:className] = class_name
        when Array
          element[:classList].add(*class_name)
        end
      end

      # @param element [JS::Object]
      # @param name [String, Symbol]
      # @param value [String]
      def set_style(element, name, value)
        element[:style][name] = value
      end

      # @param element [JS::Object]
      # @param name [String, Symbol]
      def remove_style(element, name)
        element[:style][name] = nil
      end

      # @param element [JS::Object]
      # @param name [String, Symbol]
      # @param value [String, nil]
      def set_attribute(element, name, value)
        if value.nil?
          remove_attribute(element, name)
        elsif name.to_s.start_with?("data-")
          element.setAttribute(name, value)
        elsif name.to_s == "for"
          element[:htmlFor] = value
        else
          element[name] = value
        end
      end

      # @param element [JS::Object]
      # @param name [String, Symbol]
      def remove_attribute(element, name)
        element[name] = nil
        element.removeAttribute(name)
      end

      # Parse CSS style string into hash
      # @param style_string [String] CSS style string like "color: red; margin: 10px;"
      # @return [Hash] Hash with camelCase property names as keys
      def parse_style(style)
        return {} if style.nil?

        if style.is_a?(Hash)
          return style
        end

        result = {}
        style.split(';').each do |style_rule|
          next if style_rule.strip.empty?

          property, value = style_rule.split(':', 2)
          next unless property && value

          property = property.strip
          value = value.strip

          # Convert kebab-case to camelCase for JavaScript style properties
          camel_case_property = property.gsub(/-([a-z])/) { $1.upcase }

          result[camel_case_property] = value
        end
        result
      end
    end
  end
end
