# frozen_string_literal: true

module RubyWasmUi
  module Template
    module Parser
      # Standard HTML elements that should not be treated as custom components
      STANDARD_HTML_ELEMENTS = %w[
        a abbr address area article aside audio b base bdi bdo blockquote body br button canvas caption cite code col colgroup
        data datalist dd del details dfn dialog div dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6
        head header hr html i iframe img input ins kbd label legend li link main map mark meta meter nav noscript object ol
        optgroup option output p param picture pre progress q rp rt ruby s samp script section select small source span
        strong style sub summary sup table tbody td template textarea tfoot th thead time title tr track u ul var video wbr
      ].freeze

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

        # Convert PascalCase component names to kebab-case
        processed_template = preprocess_pascal_case_component_name(processed_template)

        # Replace <template> with <div data-template> to work around DOMParser limitations
        processed_template = preprocess_template_tag(processed_template)

        parser = JS.eval('return new DOMParser()')
        document = parser.call(:parseFromString, JS.try_convert(processed_template), 'text/html')
        elements = document.getElementsByTagName('body')[0][:childNodes]

        RubyWasmUi::Template::BuildVdom.build(elements)
      end

      # Convert PascalCase component names to kebab-case in template
      # @param template [String]
      # @return [String]
      def preprocess_pascal_case_component_name(template)
        processed_template = template.dup

        # Convert opening tags (e.g., <ButtonComponent> -> <button-component>)
        # Pattern explanation:
        # - <: Matches the opening angle bracket
        # - ([A-Z][a-zA-Z0-9]*): Captures PascalCase component name
        #   - [A-Z]: First letter must be uppercase
        #   - [a-zA-Z0-9]*: Followed by any number of letters or numbers
        # - (\s|>|\/): Captures the delimiter after the component name
        #   - \s: Whitespace for attributes
        #   - >: End of opening tag
        #   - \/: Self-closing tag
        # - /i: Case-insensitive matching
        processed_template = processed_template.gsub(/<([A-Z][a-zA-Z0-9]*)(\s|>|\/)/i) do
          component_name = ::Regexp.last_match(1)  # e.g., "ButtonComponent"
          delimiter = ::Regexp.last_match(2)       # e.g., " " or ">" or "/"

          # Convert component name to kebab-case:
          # 1. Insert hyphen before capital letters: ButtonComponent -> Button-Component
          # 2. Convert to lowercase: Button-Component -> button-component
          kebab_name = component_name.gsub(/([a-z0-9])([A-Z])/, '\1-\2').downcase

          "<#{kebab_name}#{delimiter}"
        end

        # Convert closing tags (e.g., </ButtonComponent> -> </button-component>)
        # Pattern explanation:
        # - <\/: Matches the closing tag prefix
        # - ([A-Z][a-zA-Z0-9]*): Captures PascalCase component name (same as above)
        # - >: Matches the closing angle bracket
        # - /i: Case-insensitive matching
        processed_template = processed_template.gsub(/<\/([A-Z][a-zA-Z0-9]*)>/i) do
          component_name = ::Regexp.last_match(1)  # e.g., "ButtonComponent"

          # Convert component name to kebab-case (same process as above)
          kebab_name = component_name.gsub(/([a-z0-9])([A-Z])/, '\1-\2').downcase

          "</#{kebab_name}>"
        end

        processed_template
      end

      # Replace <template> tags with <div data-template> to work around DOMParser limitations
      # @param template [String]
      # @return [String]
      def preprocess_template_tag(template)
        processed_template = template.dup

        # Replace <template> with attributes (e.g., <template class="container">)
        processed_template = processed_template.gsub(/<template\s/, '<div data-template ')

        # Replace simple <template> without attributes
        processed_template = processed_template.gsub(/<template>/, '<div data-template>')

        # Replace closing tag
        processed_template = processed_template.gsub(/<\/template>/, '</div>')

        processed_template
      end

      # Convert self-closing custom element tags to regular tags
      # Custom elements are identified by having hyphens in their name or starting with uppercase (PascalCase components)
      # Standard void elements and HTML elements are not converted
      # @param template [String]
      # @return [String]
      def preprocess_self_closing_tags(template)
        # Pattern matches both:
        # 1. kebab-case custom elements: <tag-name attributes />
        # 2. PascalCase components: <ComponentName attributes />
        # Use a more robust pattern that handles nested brackets and quotes
        template.gsub(/<((?:[a-z]+(?:-[a-z]+)+)|(?:[A-Z][a-zA-Z0-9]*))((?:[^>]|"[^"]*"|'[^']*')*?)\/>/i) do
          tag_name = ::Regexp.last_match(1)
          attributes = ::Regexp.last_match(2)

          # Skip standard HTML elements
          if STANDARD_HTML_ELEMENTS.include?(tag_name.downcase)
            # Return original self-closing tag unchanged
            "<#{tag_name}#{attributes}/>"
          else
            # Convert custom elements to regular open/close tags
            "<#{tag_name}#{attributes}></#{tag_name}>"
          end
        end
      end
    end
  end
end
