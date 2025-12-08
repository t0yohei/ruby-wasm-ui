# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyWasmUi::Cli::Command::Setup do
  let(:setup_instance) { described_class.new }

  describe '.description' do
    it 'returns the description' do
      expect(described_class.description).to eq('Set up the project for ruby-wasm-ui')
    end
  end

  describe '#run' do
    before do
      allow(setup_instance).to receive(:configure_excluded_gems)
      allow(setup_instance).to receive(:build_ruby_wasm)
      allow(setup_instance).to receive(:update_gitignore)
    end

    it 'outputs setup message' do
      expect { setup_instance.run([]) }.to output(
        /Setting up ruby-wasm-ui project/
      ).to_stdout
    end

    it 'configures excluded gems' do
      expect(setup_instance).to receive(:configure_excluded_gems)
      setup_instance.run([])
    end

    it 'executes rbwasm build command' do
      ruby_version = RUBY_VERSION.split('.')[0..1].join('.')
      expect(setup_instance).to receive(:build_ruby_wasm).with(ruby_version)
      setup_instance.run([])
    end

    it 'updates .gitignore with required entries' do
      expect(setup_instance).to receive(:update_gitignore).with(
        ['*.wasm', '/rubies', '/build']
      )
      setup_instance.run([])
    end

    it 'outputs completion message' do
      expect { setup_instance.run([]) }.to output(
        /Setup completed successfully!/
      ).to_stdout
    end

    it 'outputs progress messages' do
      expect { setup_instance.run([]) }.to output(
        /Configuring excluded gems/
      ).to_stdout
      expect { setup_instance.run([]) }.to output(
        /Building Ruby WASM/
      ).to_stdout
      expect { setup_instance.run([]) }.to output(
        /Updating .gitignore/
      ).to_stdout
    end

    context 'when Ruby version is less than 3.2' do
      before do
        allow(Kernel).to receive(:exit)
      end

      context 'when Ruby version is 3.1' do
        before do
          stub_const('RUBY_VERSION', '3.1.5')
        end

        it 'outputs error message and exits' do
          expect { setup_instance.run([]) }.to output(
            /\[ERROR\] Ruby WASM requires Ruby 3.2 or higher. Current version: 3.1.5/
          ).to_stdout
          expect(Kernel).to have_received(:exit).with(1)
        end

        it 'does not execute rbwasm build command' do
          expect(setup_instance).not_to receive(:build_ruby_wasm)
          expect(setup_instance).not_to receive(:configure_excluded_gems)
          setup_instance.run([])
        end
      end

      context 'when Ruby version is 2.7' do
        before do
          stub_const('RUBY_VERSION', '2.7.8')
        end

        it 'outputs error message and exits' do
          expect { setup_instance.run([]) }.to output(
            /\[ERROR\] Ruby WASM requires Ruby 3.2 or higher. Current version: 2.7.8/
          ).to_stdout
          expect(Kernel).to have_received(:exit).with(1)
        end
      end
    end

    context 'when Ruby version is 3.2' do
      before do
        stub_const('RUBY_VERSION', '3.2.0')
        allow(setup_instance).to receive(:configure_excluded_gems)
        allow(setup_instance).to receive(:build_ruby_wasm)
        allow(setup_instance).to receive(:update_gitignore)
      end

      it 'executes rbwasm build command with correct version' do
        expect(setup_instance).to receive(:build_ruby_wasm).with('3.2')
        setup_instance.run([])
      end
    end
  end

  describe '#configure_excluded_gems' do
    before do
      # Clear EXCLUDED_GEMS before each test
      RubyWasm::Packager::EXCLUDED_GEMS.clear if defined?(RubyWasm::Packager::EXCLUDED_GEMS)
    end

    it 'excludes rack, puma, nio4r, listen, and ffi gems' do
      allow(Bundler).to receive(:definition).and_return(
        double(
          resolve: double(
            materialize: [
              double(name: 'rack'),
              double(name: 'puma'),
              double(name: 'nio4r'),
              double(name: 'listen'),
              double(name: 'ffi'),
              double(name: 'js'),
              double(name: 'ruby_wasm')
            ]
          ),
          requested_dependencies: []
        )
      )

      setup_instance.send(:configure_excluded_gems)

      expect(RubyWasm::Packager::EXCLUDED_GEMS).to include('rack', 'puma', 'nio4r', 'listen', 'ffi')
      expect(RubyWasm::Packager::EXCLUDED_GEMS).not_to include('js', 'ruby_wasm')
    end

    it 'always excludes nio4r, puma, rack, listen, and ffi even if not in dependencies' do
      allow(Bundler).to receive(:definition).and_return(
        double(
          resolve: double(
            materialize: [
              double(name: 'js'),
              double(name: 'ruby_wasm')
            ]
          ),
          requested_dependencies: []
        )
      )

      setup_instance.send(:configure_excluded_gems)

      # Always excluded gems should be in the list even if not in dependencies
      expect(RubyWasm::Packager::EXCLUDED_GEMS).to include('nio4r', 'puma', 'rack', 'listen', 'ffi')
      expect(RubyWasm::Packager::EXCLUDED_GEMS).not_to include('js', 'ruby_wasm')
    end

    it 'excludes development/test gems' do
      allow(Bundler).to receive(:definition).and_return(
        double(
          resolve: double(
            materialize: [
              double(name: 'rspec'),
              double(name: 'rubocop'),
              double(name: 'rake'),
              double(name: 'js')
            ]
          ),
          requested_dependencies: []
        )
      )

      setup_instance.send(:configure_excluded_gems)

      expect(RubyWasm::Packager::EXCLUDED_GEMS).to include('rspec', 'rubocop', 'rake')
      expect(RubyWasm::Packager::EXCLUDED_GEMS).not_to include('js')
    end
  end
end
