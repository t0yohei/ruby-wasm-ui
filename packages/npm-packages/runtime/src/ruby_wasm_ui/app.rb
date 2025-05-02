module RubyWasmUi
  class App
    def self.create(state:, view:, actions: {})
      new(state, view, actions)
    end

    # @param state [Object]
    # @param view [Proc]
    # @param actions [Hash]
    def initialize(state, view, actions)
      @state = state
      @view = view
      @actions = actions
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
      RubyWasmUi::Dom::DestroyDom.execute(@vdom) if @vdom
      @vdom = nil
      @subscriptions.each(&:call)
    end

    private

    # @return [Array<Proc>]
    def setup_subscriptions
      @subscriptions << @dispatcher.after_every_command(method(:render_app))

      @actions.each do |action_name, action|
        handler = ->(payload) {
          @state = action.call(@state, payload)
        }
        @subscriptions << @dispatcher.subscribe(action_name, handler)
      end
    end

    # @return [void]
    def render_app
      RubyWasmUi::Dom::DestroyDom.execute(@vdom) if @vdom
      @vdom = @view.call(@state, method(:emit))
      RubyWasmUi::Dom::MountDom.execute(@vdom, @parent_el)
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
