module RubyWasmUi
  class Component
    def self.define_component(render:, state: nil, methods: {})
      Class.new(Component) do
        self.class_variable_set(:@@state, state)
        self.class_variable_set(:@@render, render)

        # Add methods to the component
        methods.each do |method_name, method_proc|
          # Check if method already exists
          if method_defined?(method_name) || private_method_defined?(method_name)
            raise "Method \"#{method_name}()\" already exists in the component."
          end

          # Define the method dynamically
          define_method(method_name, method_proc)
        end
      end
    end

    def initialize(props = {})
      @props = props
      @is_mounted = false
      @vdom = nil
      @host_el = nil
      @state = self.class.class_variable_get(:@@state) ? self.class.class_variable_get(:@@state).call(@props) : {}
      @render = self.class.class_variable_get(:@@render)
    end

    attr_reader :state, :props, :render

    # Get VDOM elements
    # @return [Array<JS::Object>]
    def elements
      return [] if @vdom.nil?

      if @vdom.type == RubyWasmUi::Vdom::DOM_TYPES[:FRAGMENT]
        RubyWasmUi::Vdom.extract_children(@vdom).flat_map do |child|
          if child.type == RubyWasmUi::Vdom::DOM_TYPES[:COMPONENT]
            child.component.elements
          else
            [child.el]
          end
        end
      else
        [@vdom.el]
      end
    end

    # Get the first element
    # @return [JS::Object, nil]
    def first_element
      elements[0]
    end

    # Get offset within host element
    # @return [Integer]
    def offset
      if @vdom.type == RubyWasmUi::Vdom::DOM_TYPES[:FRAGMENT]
        children = @host_el[:children].to_a
        children.index(first_element) || 0
      else
        0
      end
    end

    # Update state
    # @param new_state [Hash] New state
    def update_state(new_state)
      merged_state = @state.merge(new_state)
      return if @state == merged_state

      @state = merged_state
      patch
    end

    # Update props
    # @param new_props [Hash] New props
    def update_props(new_props)
      merged_props = @props.merge(new_props)
      return if @props == merged_props

      @props = merged_props
      patch
    end

    # @return [RubyWasmUi::Vdom]
    def render
      @render.call(self)
    end

    # Mount component
    # @param host_el [JS::Object] Host element
    # @param index [Integer, nil] Insert position
    def mount(host_el, index = nil)
      raise "Component is already mounted" if @is_mounted

      @vdom = render
      RubyWasmUi::Dom::MountDom.execute(@vdom, host_el, index, self)

      @host_el = host_el
      @is_mounted = true
    end

    # Unmount component
    def unmount
      raise "Component is not mounted" unless @is_mounted

      RubyWasmUi::Dom::DestroyDom.execute(@vdom)

      @vdom = nil
      @host_el = nil
      @is_mounted = false
    end

    private

    # Patch VDOM
    def patch
      raise "Component is not mounted" unless @is_mounted

      vdom = render
      @vdom = RubyWasmUi::Dom::PatchDom.execute(@vdom, vdom, @host_el, self)
    end
  end
end
