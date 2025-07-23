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
          style.each do |name, value|
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
    end
  end
end
