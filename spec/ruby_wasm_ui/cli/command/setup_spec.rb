# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe RubyWasmUi::Cli::Command::Setup do
  let(:setup_instance) { described_class.new }

  describe '.description' do
    it 'returns the description' do
      expect(described_class.description).to eq('Set up the project for ruby-wasm-ui')
    end
  end

  describe '#run' do
    before do
      allow(setup_instance).to receive(:check_ruby_version).and_return(RUBY_VERSION.split('.')[0..1].join('.'))
      allow(setup_instance).to receive(:configure_excluded_gems)
      allow(setup_instance).to receive(:build_ruby_wasm)
      allow(setup_instance).to receive(:update_gitignore)
      allow(setup_instance).to receive(:create_initial_files)
    end

    it 'outputs setup message' do
      expect { setup_instance.run([]) }.to output(
        /Setting up ruby-wasm-ui project/
      ).to_stdout
    end

    it 'checks Ruby version' do
      expect(setup_instance).to receive(:check_ruby_version)
      setup_instance.run([])
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
      expect { setup_instance.run([]) }.to output(
        /Creating initial files/
      ).to_stdout
    end

    it 'creates initial files' do
      expect(setup_instance).to receive(:create_initial_files)
      setup_instance.run([])
    end

    context 'when Ruby version check fails' do
      before do
        allow(setup_instance).to receive(:check_ruby_version).and_raise(SystemExit.new(1))
        allow(Kernel).to receive(:exit)
      end

      it 'does not execute subsequent steps' do
        expect(setup_instance).not_to receive(:configure_excluded_gems)
        expect(setup_instance).not_to receive(:build_ruby_wasm)
        expect(setup_instance).not_to receive(:update_gitignore)
        expect(setup_instance).not_to receive(:create_initial_files)
        expect { setup_instance.run([]) }.to raise_error(SystemExit)
      end
    end

    context 'when Ruby version is 3.2' do
      before do
        stub_const('RUBY_VERSION', '3.2.0')
        allow(setup_instance).to receive(:check_ruby_version).and_return('3.2')
        allow(setup_instance).to receive(:configure_excluded_gems)
        allow(setup_instance).to receive(:build_ruby_wasm)
        allow(setup_instance).to receive(:update_gitignore)
        allow(setup_instance).to receive(:create_initial_files)
      end

      it 'executes rbwasm build command with correct version' do
        expect(setup_instance).to receive(:build_ruby_wasm).with('3.2')
        setup_instance.run([])
      end
    end
  end

  describe '#create_initial_files' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:src_dir) { File.join(temp_dir, 'src') }

    before do
      allow(Dir).to receive(:pwd).and_return(temp_dir)
      allow(Dir).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:write).and_call_original
      allow(Dir).to receive(:mkdir).and_call_original
    end

    after do
      FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    end

    context 'when src directory does not exist' do
      before do
        # Ensure the directory doesn't exist before the test
        FileUtils.rm_rf('src') if Dir.exist?('src')
      end

      after do
        # Clean up after test
        FileUtils.rm_rf('src') if Dir.exist?('src')
      end

      it 'creates src directory and initial files' do
        expect(Dir).to receive(:exist?).with('src').and_return(false)
        expect(File).to receive(:exist?).with('src/index.html').and_return(false)
        expect(File).to receive(:exist?).with('src/index.rb').and_return(false)
        expect(Dir).to receive(:mkdir).with('src').and_call_original
        expect(File).to receive(:write).with('src/index.html', anything).and_call_original
        expect(File).to receive(:write).with('src/index.rb', anything).and_call_original

        setup_instance.send(:create_initial_files)
      end
    end

    context 'when src directory already exists' do
      it 'skips file creation' do
        expect(Dir).to receive(:exist?).with('src').and_return(true)
        expect(File).not_to receive(:write)

        expect { setup_instance.send(:create_initial_files) }.to output(
          /src directory already exists, skipping initial file creation/
        ).to_stdout
      end
    end

    context 'when src/index.html already exists' do
      it 'skips file creation' do
        expect(Dir).to receive(:exist?).with('src').and_return(false)
        expect(File).to receive(:exist?).with('src/index.html').and_return(true)
        expect(File).not_to receive(:write)

        expect { setup_instance.send(:create_initial_files) }.to output(
          /src\/index.html already exists, skipping initial file creation/
        ).to_stdout
      end
    end

    context 'when src/index.rb already exists' do
      it 'skips file creation' do
        expect(Dir).to receive(:exist?).with('src').and_return(false)
        expect(File).to receive(:exist?).with('src/index.html').and_return(false)
        expect(File).to receive(:exist?).with('src/index.rb').and_return(true)
        expect(File).not_to receive(:write)

        expect { setup_instance.send(:create_initial_files) }.to output(
          /src\/index.rb already exists, skipping initial file creation/
        ).to_stdout
      end
    end
  end
end
