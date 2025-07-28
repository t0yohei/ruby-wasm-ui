# frozen_string_literal: true

module RubyWasmUi
  module Template
    module Parser
      module_function

      # @param template [String]
      # @return [String]
      def parse(template)
        parser = JS.eval('return new DOMParser()')
        document = parser.call(:parseFromString, JS.try_convert(template), 'text/html')
        elements = document.getElementsByTagName('body')[0][:childNodes]

        build_vdom(elements)
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

          # fragment node
          if element[:nodeType] == JS.global[:Node][:ELEMENT_NODE] && element[:tagName] == 'TEMPLATE'
            vdom << "RubyWasmUi::Vdom.h_fragment([#{build_vdom(element[:content][:childNodes])}])"
            next
          end

          # element node
          if element[:nodeType] == JS.global[:Node][:ELEMENT_NODE]
            tag_name = element[:tagName].to_s
            attributes = parse_attributes(element[:attributes])
            children = build_vdom(element[:childNodes])

            if is_component?(tag_name)
              # Component (tag name starts with uppercase)
              component_name = find_component_constant(tag_name)
              vdom << "RubyWasmUi::Vdom.h(#{component_name}, {#{attributes}}, [#{children}])"
            else
              # Regular HTML element
              vdom << "RubyWasmUi::Vdom.h('#{tag_name.downcase}', {#{attributes}}, [#{children}])"
            end
            next
          end
        end
        vdom.compact.join(',')
      end

      # @param element [JS.Object]
      # @return [String]
      def parse_text_node(element)
        value = element[:nodeValue].to_s.chomp.strip

        return nil if value.empty?

        if embed_script?(value)
          # Handle mixed text with embedded scripts
          # Split the text into parts and process each part
          parts = []
          remaining = value

          while remaining.include?('{')
            # Find the text before the next embedded script
            before_match = remaining.match(/^(.*?)\{/)
            if before_match && !before_match[1].empty?
              parts << "'#{before_match[1]}'"
            end

            # Find and extract the embedded script
            script_match = remaining.match(/\{(.+?)\}/)
            if script_match
              parts << "(#{script_match[1]}).to_s"
              remaining = remaining[script_match.end(0)..-1]
            else
              break
            end
          end

          # Add any remaining text
          unless remaining.empty?
            parts << "'#{remaining}'"
          end

          # Join all parts with string concatenation and wrap in h_string
          concatenated_string = parts.join(' + ')
          "RubyWasmUi::Vdom.h_string(#{concatenated_string})"
        else
          # Pure text without embedded scripts
          "'#{value}'"
        end
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
        # Component tags start with uppercase letter but exclude standard HTML elements
        return false unless tag_name.match?(/\A[A-Z]/)

        # List of standard HTML elements (case-sensitive comparison)
        # HTML elements come as uppercase from DOM, but components maintain their original case
        html_elements = %w[
          A ABBR ADDRESS AREA ARTICLE ASIDE AUDIO B BASE BDI BDO BLOCKQUOTE BODY BR BUTTON
          CANVAS CAPTION CITE CODE COL COLGROUP DATA DATALIST DD DEL DETAILS DFN DIALOG DIV DL DT
          EM EMBED FIELDSET FIGCAPTION FIGURE FOOTER FORM H1 H2 H3 H4 H5 H6 HEAD HEADER HGROUP HR HTML
          I IFRAME IMG INPUT INS KBD LABEL LEGEND LI LINK MAIN MAP MARK MENU META METER NAV NOSCRIPT
          OBJECT OL OPTGROUP OPTION OUTPUT P PARAM PICTURE PRE PROGRESS Q RP RT RUBY S SAMP SCRIPT
          SECTION SELECT SMALL SOURCE SPAN STRONG STYLE SUB SUMMARY SUP TABLE TBODY TD TEMPLATE
          TEXTAREA TFOOT TH THEAD TIME TITLE TR TRACK U UL VAR VIDEO WBR
        ]

        # Only exclude if tag_name is exactly a standard HTML element (all uppercase)
        !html_elements.include?(tag_name)
      end

      # @param tag_name [String]
      # @return [String]
      def find_component_constant(tag_name)
        # DOM parser converts component names to uppercase (e.g., "SearchField" -> "SEARCHFIELD")
        # We need to find the actual constant name that was defined

        possible_names = []

        # If it's all uppercase, try to convert to PascalCase
        if tag_name == tag_name.upcase && tag_name.length > 1
          if tag_name.include?('-')
            # For hyphenated names, split and capitalize each part (recommended approach)
            # e.g., "SEARCH-FIELD" -> "SearchField", "USER-PROFILE-CARD" -> "UserProfileCard"
            hyphenated_result = tag_name.split('-').map(&:capitalize).join('')
            possible_names << hyphenated_result
          else
            # For non-hyphenated uppercase names, generate multiple possibilities
            candidates = generate_pascal_case_candidates(tag_name)
            possible_names.concat(candidates)
          end
        end

        # Add fallback options
        pascalized = pascalize_tag_name(tag_name)
        possible_names << pascalized
        possible_names << tag_name    # Keep as-is

        # Try to find the first candidate that exists as a constant
        possible_names.uniq.each do |candidate|
          if constant_exists?(candidate)
            return candidate
          end
        end

        # If no existing constant found, return the first possibility
        possible_names.uniq.first || pascalized
      end

      # @param tag_name [String]
      # @return [Array<String>]
      def generate_pascal_case_candidates(tag_name)
        candidates = []

        # Simple capitalization (e.g., "BUTTON" -> "Button")
        candidates << tag_name.capitalize

        # Try to split compound words and recombine
        # This is a heuristic approach for common patterns
        candidates.concat(split_compound_word(tag_name))

        candidates
      end

      # @param tag_name [String]
      # @return [Array<String>]
      def split_compound_word(tag_name)
        candidates = []

        # Common word endings that might indicate compound words
        word_endings = %w[FIELD BUTTON CARD COMPONENT MODAL DIALOG INPUT AREA BOX LIST ITEM VIEW PANEL SECTION HEADER FOOTER NAV BAR MENU FORM TABLE ROW CELL]

        word_endings.each do |ending|
          if tag_name.end_with?(ending) && tag_name.length > ending.length
            base = tag_name[0...(tag_name.length - ending.length)]
            candidate = "#{base.capitalize}#{ending.capitalize}"
            candidates << candidate
          end
        end

        # Try splitting at common word boundaries (basic heuristic)
        # Look for common patterns like "SearchField", "UserCard", etc.
        if tag_name.length > 4
          # Try different split points
          (2...(tag_name.length - 2)).each do |split_point|
            first_part = tag_name[0...split_point].capitalize
            second_part = tag_name[split_point..-1].capitalize
            candidates << "#{first_part}#{second_part}"
          end
        end

        candidates.uniq
      end

      # @param constant_name [String]
      # @return [Boolean]
      def constant_exists?(constant_name)
        # Try to check if the constant exists
        # In Ruby WASM environment, we'll use a safe approach
        begin
          # Use eval to check if constant is defined
          # defined? returns a string if defined, nil if not defined
          result = eval("defined?(#{constant_name})")
          !result.nil?
        rescue
          false
        end
      end

      # @param tag_name [String]
      # @return [String]
      def pascalize_tag_name(tag_name)
        # Convert component names to PascalCase
        # e.g., "my-component" -> "MyComponent", "SEARCHFIELD" -> "SearchField", "MyButton" -> "MyButton"

        # If tag_name contains hyphens, split and capitalize each part
        if tag_name.include?('-')
          tag_name.split('-').map(&:capitalize).join('')
        else
          # Check if it's all uppercase (DOM parser converts component names to uppercase)
          if tag_name == tag_name.upcase && tag_name.length > 1
            # Convert all uppercase to PascalCase (e.g., "SEARCHFIELD" -> "SearchField")
            tag_name.capitalize
          elsif tag_name.match?(/\A[A-Z]/)
            # Already starts with uppercase, keep as-is (preserve PascalCase)
            tag_name
          else
            # Convert to PascalCase
            tag_name.capitalize
          end
        end
      end

      # @param doc [String]
      # @return [Boolean]
      def embed_script?(doc)
        doc.match?(/\{.+\}/)
      end

      # @param script [String]
      # @return [String]
      def get_embed_script(script)
        script.gsub(/\{(.+)\}/) { ::Regexp.last_match(1) }
      end
    end
  end
end
