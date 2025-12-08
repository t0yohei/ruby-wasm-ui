# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe RubyWasmUi::Cli::Command::Base do
  let(:base_instance) { described_class.new }

  describe '#run' do
    it 'raises NotImplementedError' do
      expect { base_instance.run([]) }.to raise_error(NotImplementedError, /Subclasses must implement #run/)
    end
  end

  describe '#update_gitignore' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:original_dir) { Dir.pwd }

    around do |example|
      Dir.chdir(temp_dir) do
        example.run
      end
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    end

    context 'when .gitignore does not exist' do
      it 'creates .gitignore with new entries' do
        base_instance.send(:update_gitignore, ['*.wasm', '/rubies'])
        content = File.read('.gitignore')
        expect(content).to include('*.wasm')
        expect(content).to include('/rubies')
      end
    end

    context 'when .gitignore exists' do
      before do
        File.write('.gitignore', "node_modules/\n*.log\n")
      end

      it 'adds new entries to existing .gitignore' do
        base_instance.send(:update_gitignore, ['*.wasm', '/rubies'])
        content = File.read('.gitignore')
        expect(content).to include('node_modules/')
        expect(content).to include('*.log')
        expect(content).to include('*.wasm')
        expect(content).to include('/rubies')
      end

      it 'does not add duplicate entries' do
        File.write('.gitignore', "*.wasm\n")
        base_instance.send(:update_gitignore, ['*.wasm', '/rubies'])
        content = File.read('.gitignore')
        expect(content.scan(/^\*\.wasm$/).count).to eq(1)
      end

      it 'outputs message when entries are added' do
        expect { base_instance.send(:update_gitignore, ['*.wasm']) }.to output(
          /Added to .gitignore: \*\.wasm/
        ).to_stdout
      end

      it 'outputs message when no entries are added' do
        File.write('.gitignore', "*.wasm\n")
        expect { base_instance.send(:update_gitignore, ['*.wasm']) }.to output(
          /No new entries added to .gitignore/
        ).to_stdout
      end
    end
  end

  describe '#run_command' do
    context 'when command succeeds' do
      it 'executes the command and outputs stdout' do
        expect { base_instance.send(:run_command, 'echo "test output"') }.to output(
          /test output/
        ).to_stdout
      end

      it 'does not raise error' do
        expect { base_instance.send(:run_command, 'echo "test"') }.not_to raise_error
      end
    end

    context 'when command fails' do
      it 'outputs error message and exits' do
        expect { base_instance.send(:run_command, 'false') }.to output(
          /Command failed: false/
        ).to_stdout.and raise_error(SystemExit)
      end
    end
  end
end
