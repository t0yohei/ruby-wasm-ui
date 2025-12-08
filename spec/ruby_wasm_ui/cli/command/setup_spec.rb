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
      expect(setup_instance).to receive(:run_command).with(
        'bundle exec rbwasm build --ruby-version 3.4 -o ruby.wasm'
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
  end
end
