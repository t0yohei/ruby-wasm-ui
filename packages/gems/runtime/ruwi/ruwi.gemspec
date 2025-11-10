# frozen_string_literal: true

require_relative "lib/ruwi/version"

Gem::Specification.new do |spec|
  spec.name = "ruwi"
  spec.version = Ruwi::VERSION
  spec.authors = ["t0yohei"]
  spec.email = ["k.t0yohei@gmail.com"]

  spec.summary = "Ruwi is a Ruby library for building web applications."
  spec.description = "Ruwi is a Ruby library for building web applications."
  spec.homepage = "https://github.com/t0yohei/ruby-wasm-ui"
  spec.license = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby_wasm", "~> 2.7"
  spec.add_dependency "js", "~> 2.7"
end
