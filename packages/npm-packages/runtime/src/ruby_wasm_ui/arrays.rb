module RubyWasmUi
  module Arrays
    def self.without_nulls(arr)
      arr.reject { |item| item.nil? }
    end
  end
end
