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

        RubyWasmUi::Template::BuildVdom.build(elements)
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
    end
  end
end
