module RubyWasmUi
  class App
    def self.create(state:, view:, reducers: {})
      new(state, view, reducers)
    end

    # @param state [Object]
    # @param view [Proc]
    # @param reducers [Hash]
    def initialize(state, view, reducers)
      @state = state
      @view = view
      @reducers = reducers
      @parent_el = nil
      @vdom = nil
      @dispatcher = Dispatcher.new
      @subscriptions = []

      setup_subscriptions
    end

    # @param parent_el [Element]
    # @return [void]
    def mount(parent_el)
      @parent_el = parent_el
      render_app
    end

    # @return [void]
    def unmount
      destroy_dom(@vdom) if @vdom
      @vdom = nil
      @subscriptions.each(&:call)
    end

    private

    # @return [Array<Proc>]
    def setup_subscriptions
      @subscriptions << @dispatcher.after_every_command(method(:render_app))

      @reducers.each do |action_name, reducer|
        handler = ->(payload) {
          @state = reducer.call(@state, payload)
        }
        @subscriptions << @dispatcher.subscribe(action_name, handler)
      end
    end

    # @return [void]
    def render_app
      RubyWasmUi::Dom::DestroyDom.destroy(@vdom) if @vdom
      @vdom = @view.call(@state, method(:emit))
      RubyWasmUi::Dom::MountDom.mount(@vdom, @parent_el)
    end

    # @param event_name [String]
    # @param payload [Object]
    # @return [void]
    def emit(event_name, payload = nil)
      @dispatcher.dispatch(event_name, payload)
      return nil
    end
  end
end
