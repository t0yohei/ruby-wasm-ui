module RubyWasmUi
  class Component
    def self.define_component(render:, state: nil)
      Class.new(Component) do
        @@state = state
        @@render = render
      end
    end

    def initialize(props = {})
      @props = props
      @is_mounted = false
      @vdom = nil
      @host_el = nil
      @state = @@state ? @@state.call(@props) : {}
      @render = @@render
    end

    attr_reader :state, :props

    # Get VDOM elements
    # @return [Array<JS::Object>]
    def elements
      return [] if @vdom.nil?

      if @vdom.type == RubyWasmUi::Vdom::DOM_TYPES[:FRAGMENT]
        RubyWasmUi::Vdom.extract_children(@vdom).map(&:el)
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
      @state = @state.merge(new_state)
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
      RubyWasmUi::Dom::MountDom.execute(@vdom, host_el, index)

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
