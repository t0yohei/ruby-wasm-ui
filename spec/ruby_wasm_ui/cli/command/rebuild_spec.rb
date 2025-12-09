# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyWasmUi::Cli::Command::Rebuild do
  let(:rebuild_instance) { described_class.new }

  describe '.description' do
    it 'returns the description' do
      expect(described_class.description).to eq('Rebuild Ruby WASM file (useful when gems are added)')
    end
  end

  describe '#run' do
    before do
      allow(rebuild_instance).to receive(:check_ruby_version).and_return(RUBY_VERSION.split('.')[0..1].join('.'))
      allow(rebuild_instance).to receive(:configure_excluded_gems)
      allow(rebuild_instance).to receive(:build_ruby_wasm)
    end

    it 'outputs rebuild message' do
      expect { rebuild_instance.run([]) }.to output(
        /Rebuilding Ruby WASM/
      ).to_stdout
    end

    it 'checks Ruby version' do
      expect(rebuild_instance).to receive(:check_ruby_version)
      rebuild_instance.run([])
    end

    it 'configures excluded gems' do
      expect(rebuild_instance).to receive(:configure_excluded_gems)
      rebuild_instance.run([])
    end

    it 'executes rbwasm build command' do
      ruby_version = RUBY_VERSION.split('.')[0..1].join('.')
      expect(rebuild_instance).to receive(:build_ruby_wasm).with(ruby_version)
      rebuild_instance.run([])
    end

    it 'outputs completion message' do
      expect { rebuild_instance.run([]) }.to output(
        /Rebuild completed successfully!/
      ).to_stdout
    end

    it 'outputs progress messages' do
      expect { rebuild_instance.run([]) }.to output(
        /Configuring excluded gems/
      ).to_stdout
      expect { rebuild_instance.run([]) }.to output(
        /Building Ruby WASM/
      ).to_stdout
    end

    it 'does not update .gitignore' do
      expect(rebuild_instance).not_to respond_to(:update_gitignore)
      rebuild_instance.run([])
    end

    it 'does not create initial files' do
      expect(rebuild_instance).not_to respond_to(:create_initial_files)
      rebuild_instance.run([])
    end

    context 'when Ruby version check fails' do
      before do
        allow(rebuild_instance).to receive(:check_ruby_version).and_raise(SystemExit.new(1))
        allow(Kernel).to receive(:exit)
      end

      it 'does not execute subsequent steps' do
        expect(rebuild_instance).not_to receive(:configure_excluded_gems)
        expect(rebuild_instance).not_to receive(:build_ruby_wasm)
        expect { rebuild_instance.run([]) }.to raise_error(SystemExit)
      end
    end

    context 'when Ruby version is 3.2' do
      before do
        stub_const('RUBY_VERSION', '3.2.0')
        allow(rebuild_instance).to receive(:check_ruby_version).and_return('3.2')
        allow(rebuild_instance).to receive(:configure_excluded_gems)
        allow(rebuild_instance).to receive(:build_ruby_wasm)
      end

      it 'executes rbwasm build command with correct version' do
        expect(rebuild_instance).to receive(:build_ruby_wasm).with('3.2')
        rebuild_instance.run([])
      end
    end
  end
end
