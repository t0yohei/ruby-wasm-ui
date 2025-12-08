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

      it 'returns true' do
        result = base_instance.send(:run_command, 'echo "test"')
        expect(result).to be true
      end
    end

    context 'when command fails' do
      it 'outputs error message and exits by default' do
        expect { base_instance.send(:run_command, 'false') }.to output(
          /Command failed: false/
        ).to_stdout.and raise_error(SystemExit)
      end

      it 'exits with correct status code' do
        expect { base_instance.send(:run_command, 'false') }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      context 'when exit_on_error is false' do
        it 'outputs error message but does not exit' do
          expect { base_instance.send(:run_command, 'false', exit_on_error: false) }.to output(
            /Command failed: false/
          ).to_stdout
          expect { base_instance.send(:run_command, 'false', exit_on_error: false) }.not_to raise_error
        end

        it 'returns false' do
          result = base_instance.send(:run_command, 'false', exit_on_error: false)
          expect(result).to be false
        end
      end
    end
  end

  describe '#ensure_src_directory' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:original_dir) { Dir.pwd }

    around do |example|
      Dir.chdir(temp_dir) do
        example.run
      end
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    end

    context 'when src directory does not exist' do
      it 'outputs error message and exits' do
        expect { base_instance.send(:ensure_src_directory) }.to output(
          /src directory not found. Please run 'ruby-wasm-ui setup' first./
        ).to_stdout.and raise_error(SystemExit)
      end

      it 'exits with status 1' do
        expect { base_instance.send(:ensure_src_directory) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context 'when src directory exists' do
      before do
        FileUtils.mkdir_p('src')
      end

      it 'does not raise error' do
        expect { base_instance.send(:ensure_src_directory) }.not_to raise_error
      end

      it 'does not output error message' do
        expect { base_instance.send(:ensure_src_directory) }.not_to output(
          /src directory not found/
        ).to_stdout
      end
    end
  end

  describe '#ensure_ruby_wasm' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:original_dir) { Dir.pwd }

    around do |example|
      Dir.chdir(temp_dir) do
        example.run
      end
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    end

    context 'when ruby.wasm does not exist' do
      it 'outputs error message and exits' do
        expect { base_instance.send(:ensure_ruby_wasm) }.to output(
          /ruby.wasm not found. Please run 'ruby-wasm-ui setup' first./
        ).to_stdout.and raise_error(SystemExit)
      end

      it 'exits with status 1' do
        expect { base_instance.send(:ensure_ruby_wasm) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context 'when ruby.wasm exists' do
      before do
        FileUtils.touch('ruby.wasm')
      end

      it 'does not raise error' do
        expect { base_instance.send(:ensure_ruby_wasm) }.not_to raise_error
      end

      it 'does not output error message' do
        expect { base_instance.send(:ensure_ruby_wasm) }.not_to output(
          /ruby.wasm not found/
        ).to_stdout
      end
    end
  end

  describe '#check_ruby_version' do
    context 'when Ruby version is 3.2 or higher' do
      before do
        stub_const('RUBY_VERSION', '3.2.0')
      end

      it 'returns the version string' do
        result = base_instance.send(:check_ruby_version)
        expect(result).to eq('3.2')
      end

      it 'does not exit' do
        expect { base_instance.send(:check_ruby_version) }.not_to raise_error
      end
    end

    context 'when Ruby version is 3.4' do
      before do
        stub_const('RUBY_VERSION', '3.4.0')
      end

      it 'returns the version string' do
        result = base_instance.send(:check_ruby_version)
        expect(result).to eq('3.4')
      end
    end

    context 'when Ruby version is less than 3.2' do
      context 'when Ruby version is 3.1' do
        before do
          stub_const('RUBY_VERSION', '3.1.5')
        end

        it 'outputs error message and exits' do
          expect { base_instance.send(:check_ruby_version) }.to output(
            /\[ERROR\] Ruby WASM requires Ruby 3.2 or higher. Current version: 3.1.5/
          ).to_stdout.and raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        end
      end

      context 'when Ruby version is 2.7' do
        before do
          stub_const('RUBY_VERSION', '2.7.8')
        end

        it 'outputs error message and exits' do
          expect { base_instance.send(:check_ruby_version) }.to output(
            /\[ERROR\] Ruby WASM requires Ruby 3.2 or higher. Current version: 2.7.8/
          ).to_stdout.and raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        end
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

      base_instance.send(:configure_excluded_gems)

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

      base_instance.send(:configure_excluded_gems)

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

      base_instance.send(:configure_excluded_gems)

      expect(RubyWasm::Packager::EXCLUDED_GEMS).to include('rspec', 'rubocop', 'rake')
      expect(RubyWasm::Packager::EXCLUDED_GEMS).not_to include('js')
    end
  end

  describe '#build_ruby_wasm' do
    let(:cli_instance) { instance_double(RubyWasm::CLI) }

    before do
      allow(RubyWasm::CLI).to receive(:new).and_return(cli_instance)
      allow(cli_instance).to receive(:run)
    end

    it 'executes rbwasm build command with correct arguments' do
      expect(RubyWasm::CLI).to receive(:new).with(stdout: $stdout, stderr: $stderr).and_return(cli_instance)
      expect(cli_instance).to receive(:run).with(['build', '--ruby-version', '3.2', '-o', 'ruby.wasm'])

      base_instance.send(:build_ruby_wasm, '3.2')
    end

    it 'executes rbwasm build command with different version' do
      expect(RubyWasm::CLI).to receive(:new).with(stdout: $stdout, stderr: $stderr).and_return(cli_instance)
      expect(cli_instance).to receive(:run).with(['build', '--ruby-version', '3.4', '-o', 'ruby.wasm'])

      base_instance.send(:build_ruby_wasm, '3.4')
    end
  end
end
