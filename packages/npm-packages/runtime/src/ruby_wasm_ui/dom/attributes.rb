module RubyWasmUi
  module Dom
    class Attributes
      # @param element [JS::Object]
      def initialize(element)
        @element = element
      end

      def set_attributes(attrs)
        attrs.each do |name, value|
          case name
          when :class
            set_class(value)
          when :style
            set_styles(value)
          else
            set_attribute(name, value)
          end
        end
      end

      def set_class(className)
        @element[:className] = ""

        case className
        when String
          @element[:className] = className
        when Array
          @element[:classList].add(*className)
        end
      end

      def set_styles(styles)
        styles.each do |name, value|
          set_style(name, value)
        end
      end

      def set_style(name, value)
        @element[:style][name] = value
      end

      def remove_style(name)
        @element[:style][name] = nil
      end

      def set_attribute(name, value)
        if value.nil?
          remove_attribute(name)
        elsif name.to_s.start_with?("data-")
          @element.setAttribute(name, value)
        else
          @element[name] = value
        end
      end

      def remove_attribute(name)
        @element[name] = nil
        @element.removeAttribute(name)
      end
    end
  end
end
