module Ruwi
  class App
    # @param root_component [Class]
    # @param props [Hash]
    # @return [App]
    def self.create(root_component, props = {})
      new(root_component, props)
    end

    # @param root_component [Class]
    # @param props [Hash]
    def initialize(root_component, props)
      @root_component = root_component
      @props = props
      @parent_el = nil
      @is_mounted = false
      @vdom = nil
    end

    # @param parent_el [Element]
    # @return [void]
    def mount(parent_el)
      if @is_mounted
        raise "The application is already mounted"
      end

      @parent_el = parent_el
      @vdom = Ruwi::Vdom.h(@root_component, @props)
      Ruwi::Dom::MountDom.execute(@vdom, @parent_el)

      @is_mounted = true
    end

    # @return [void]
    def unmount
      unless @is_mounted
        raise "The application is not mounted"
      end

      Ruwi::Dom::DestroyDom.execute(@vdom)
      reset
    end

    private

    # @return [void]
    def reset
      @parent_el = nil
      @is_mounted = false
      @vdom = nil
    end
  end
end
