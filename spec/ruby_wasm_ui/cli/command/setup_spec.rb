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
      allow(setup_instance).to receive(:run_command)
      allow(setup_instance).to receive(:update_gitignore)
    end

    it 'outputs setup message' do
      expect { setup_instance.run([]) }.to output(
        /Setting up ruby-wasm-ui project/
      ).to_stdout
    end

    it 'executes rbwasm build command' do
      ruby_version = RUBY_VERSION.split('.')[0..1].join('.')
      expect(setup_instance).to receive(:run_command).with(
        "bundle exec rbwasm build --ruby-version #{ruby_version} -o ruby.wasm"
      )
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
          expect(setup_instance).not_to receive(:run_command)
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
        allow(setup_instance).to receive(:run_command)
        allow(setup_instance).to receive(:update_gitignore)
      end

      it 'executes rbwasm build command with correct version' do
        expect(setup_instance).to receive(:run_command).with(
          'bundle exec rbwasm build --ruby-version 3.2 -o ruby.wasm'
        )
        setup_instance.run([])
      end
    end
  end
end
