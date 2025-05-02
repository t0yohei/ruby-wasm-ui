module RubyWasmUi
  class Dispatcher
    def initialize
      @subs = {}
      @after_handlers = []
    end

    # @param command_name [String]
    def subscribe(command_name, handler)
      @subs[command_name] ||= []
      handlers = @subs[command_name]

      return -> {} if handlers.include?(handler)

      handlers << handler

      -> {
        idx = handlers.index(handler)
        handlers.delete_at(idx) if idx
      }
    end

    # @param handler [Proc]
    def after_every_command(handler)
      @after_handlers << handler

      -> {
        idx = @after_handlers.index(handler)
        @after_handlers.delete_at(idx) if idx
      }
    end

    # @param command_name [String]
    # @param payload [Object]
    def dispatch(command_name, payload)
      command_name_sym = command_name.to_sym
      if @subs.key?(command_name_sym)
        @subs[command_name_sym].each { |handler| handler.call(payload) }
      else
        warn "No handlers for command: #{command_name}"
      end

      @after_handlers.each(&:call)
    end
  end
end
