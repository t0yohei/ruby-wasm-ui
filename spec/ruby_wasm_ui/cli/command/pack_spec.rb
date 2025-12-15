# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe RubyWasmUi::Cli::Command::Pack do
  let(:pack_instance) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }
  let(:original_dir) { Dir.pwd }

  around do |example|
    Dir.chdir(temp_dir) do
      example.run
    end
  ensure
    Dir.chdir(original_dir)
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe '.description' do
    it 'returns the description' do
      expect(described_class.description).to eq('Pack WASM file by packing Ruby source files')
    end
  end

  describe '#run' do
    context 'when src directory does not exist' do
      it 'outputs error message and exits' do
        expect { pack_instance.run([]) }.to output(
          /src directory not found. Please run 'ruby-wasm-ui setup' first./
        ).to_stdout.and raise_error(SystemExit)
      end

      it 'exits with status 1' do
        expect { pack_instance.run([]) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context 'when src directory exists but ruby.wasm does not exist' do
      before do
        FileUtils.mkdir_p('src')
      end

      it 'outputs error message and exits' do
        expect { pack_instance.run([]) }.to output(
          /ruby.wasm not found. Please run 'ruby-wasm-ui setup' first./
        ).to_stdout.and raise_error(SystemExit)
      end

      it 'exits with status 1' do
        expect { pack_instance.run([]) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context 'when src directory and ruby.wasm exist' do
      before do
        FileUtils.mkdir_p('src')
        FileUtils.touch('ruby.wasm')
        allow(pack_instance).to receive(:pack)
        allow(pack_instance).to receive(:copy_non_ruby_files)
      end

      it 'outputs packing message' do
        expect { pack_instance.run([]) }.to output(
          /Packing WASM file/
        ).to_stdout
      end

      it 'calls pack method' do
        expect(pack_instance).to receive(:pack)
        pack_instance.run([])
      end

      it 'calls copy_non_ruby_files method' do
        expect(pack_instance).to receive(:copy_non_ruby_files)
        pack_instance.run([])
      end
    end
  end

  describe '#pack' do
    before do
      FileUtils.mkdir_p('src')
      FileUtils.touch('ruby.wasm')
    end

    context 'when command succeeds' do
      before do
        allow(pack_instance).to receive(:run_command).and_return(true)
      end

      it 'calls pack_wasm with default parameters' do
        expect(pack_instance).to receive(:pack_wasm).with(exit_on_error: true, log_prefix: 'Packing').and_return(true)
        pack_instance.send(:pack)
      end

      it 'outputs pack message' do
        expect { pack_instance.send(:pack) }.to output(
          /Packing: bundle exec rbwasm pack/
        ).to_stdout
      end

      it 'outputs success message' do
        expect { pack_instance.send(:pack) }.to output(
          /Pack completed/
        ).to_stdout
      end
    end

    context 'when command fails' do
      before do
        allow(pack_instance).to receive(:run_command).and_raise(SystemExit.new(1))
      end

      it 'outputs error message and exits' do
        expect { pack_instance.send(:pack) }.to raise_error(SystemExit)
      end

      it 'exits with status 1' do
        expect { pack_instance.send(:pack) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end
  end
end
