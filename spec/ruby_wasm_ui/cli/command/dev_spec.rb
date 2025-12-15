# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe RubyWasmUi::Cli::Command::Dev do
  let(:dev_instance) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }
  let(:original_dir) { Dir.pwd }

  around do |example|
    begin
      Dir.chdir(temp_dir) do
        example.run
      end
    ensure
      # 確実に元のディレクトリに戻る
      begin
        Dir.chdir(original_dir) if Dir.exist?(original_dir)
      rescue => e
        # ディレクトリが存在しない場合は無視
      end
      FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    end
  end

  describe '.description' do
    it 'returns the description' do
      expect(described_class.description).to eq('Start development server with file watching and auto-build')
    end
  end

  describe '#run' do
    let(:watcher_thread) { instance_double(Thread, kill: nil) }

    before do
      allow(dev_instance).to receive(:build).and_return(true)
      allow(dev_instance).to receive(:start_file_watcher)
      allow(dev_instance).to receive(:start_server)
      allow(Thread).to receive(:new).and_return(watcher_thread)
    end

    context 'when src directory does not exist' do
      it 'outputs error message and exits' do
        expect { dev_instance.run([]) }.to output(
          /src directory not found. Please run 'ruby-wasm-ui setup' first./
        ).to_stdout.and raise_error(SystemExit)
      end

      it 'exits with status 1' do
        expect { dev_instance.run([]) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context 'when src directory exists' do
      before do
        FileUtils.mkdir_p('src')
      end

      it 'outputs starting message' do
        expect { dev_instance.run([]) }.to output(
          /Starting development server/
        ).to_stdout
      end

      it 'performs initial build' do
        expect(dev_instance).to receive(:build).and_return(true)
        dev_instance.run([])
      end

      it 'outputs initial build completion message' do
        expect { dev_instance.run([]) }.to output(
          /Initial build completed/
        ).to_stdout
      end

      it 'starts file watcher' do
        file_watcher_called = false
        # Allow Thread.new to actually create threads so start_file_watcher gets called
        allow(Thread).to receive(:new).and_call_original
        allow(dev_instance).to receive(:start_file_watcher) do
          file_watcher_called = true
        end
        # Mock start_server to block briefly to allow thread to execute
        allow(dev_instance).to receive(:start_server) do
          sleep 0.1  # Give thread time to execute
        end

        dev_instance.run([])

        expect(file_watcher_called).to be true
      end

      it 'starts development server' do
        allow(dev_instance).to receive(:start_file_watcher).and_return(nil)
        expect(dev_instance).to receive(:start_server)
        dev_instance.run([])
      end

      context 'when build fails' do
        before do
          allow(dev_instance).to receive(:build).and_return(false)
        end

        it 'still starts the server' do
          expect(dev_instance).to receive(:start_server)
          dev_instance.run([])
        end
      end
    end
  end

  describe '#build' do
    before do
      FileUtils.mkdir_p('src')
      FileUtils.touch('ruby.wasm')
    end

    context 'when command succeeds' do
      before do
        allow(dev_instance).to receive(:run_command).and_return(true)
      end

      it 'calls pack_wasm with Building log_prefix' do
        expect(dev_instance).to receive(:pack_wasm).with(exit_on_error: false, log_prefix: 'Building').and_return(true)
        allow(dev_instance).to receive(:copy_non_ruby_files)
        dev_instance.send(:build)
      end

      it 'outputs build message' do
        expect { dev_instance.send(:build) }.to output(
          /Building: bundle exec rbwasm pack/
        ).to_stdout
      end

      it 'calls copy_non_ruby_files when build succeeds' do
        allow(dev_instance).to receive(:pack_wasm).and_return(true)
        expect(dev_instance).to receive(:copy_non_ruby_files)
        dev_instance.send(:build)
      end

      it 'outputs success message' do
        expect { dev_instance.send(:build) }.to output(
          /Build completed/
        ).to_stdout
      end

      it 'returns true' do
        result = dev_instance.send(:build)
        expect(result).to be true
      end
    end

    context 'when command fails' do
      before do
        allow(dev_instance).to receive(:run_command).and_return(false)
      end

      it 'does not call copy_non_ruby_files when build fails' do
        allow(dev_instance).to receive(:pack_wasm).and_return(false)
        expect(dev_instance).not_to receive(:copy_non_ruby_files)
        dev_instance.send(:build)
      end

      it 'outputs error message' do
        expect { dev_instance.send(:build) }.to output(
          /Build failed/
        ).to_stdout
      end

      it 'returns false' do
        result = dev_instance.send(:build)
        expect(result).to be false
      end
    end
  end

  describe '#start_file_watcher' do
    before do
      FileUtils.mkdir_p('src')
      @listener = instance_double(Listen::Listener, start: nil, stop: nil)
      allow(Listen).to receive(:to).and_return(@listener)
    end

    it 'starts listening to src directory' do
      expect(Listen).to receive(:to).with('src')
      dev_instance.send(:start_file_watcher)
    end

    it 'starts the listener' do
      expect(@listener).to receive(:start)
      dev_instance.send(:start_file_watcher)
    end

    context 'when file changes occur' do
      let(:callback_container) { {} }

      before do
        allow(Listen).to receive(:to) do |_dir, &block|
          callback_container[:callback] = block
          @listener
        end
        dev_instance.instance_variable_set(:@build_lock, Mutex.new)
        dev_instance.instance_variable_set(:@build_queue, Queue.new)
        allow(dev_instance).to receive(:build)
        allow(dev_instance).to receive(:log_info)
      end

      it 'triggers rebuild on file change' do
        dev_instance.send(:start_file_watcher)
        callback = callback_container[:callback]
        expect(callback).not_to be_nil

        # Allow Thread.new to create actual threads for the debounce logic
        allow(Thread).to receive(:new).and_call_original

        callback.call(['src/app.rb'], [], [])
        sleep 0.6 # Wait for debounce
        expect(dev_instance).to have_received(:build)
      end

      it 'ignores temporary files' do
        dev_instance.send(:start_file_watcher)
        callback = callback_container[:callback]
        expect(callback).not_to be_nil

        # Allow Thread.new to create actual threads for the debounce logic
        allow(Thread).to receive(:new).and_call_original

        callback.call(['src/app.rb.swp'], [], [])
        sleep 0.6
        expect(dev_instance).not_to have_received(:build)
      end
    end

    context 'when listener raises an error' do
      before do
        allow(Listen).to receive(:to).and_raise(StandardError.new('Listener error'))
      end

      it 'outputs error message' do
        expect { dev_instance.send(:start_file_watcher) }.to output(
          /File watcher error: Listener error/
        ).to_stdout
      end
    end
  end

  describe '#start_server' do
    let(:puma_handler_class) do
      Class.new do
        def self.run(app, options = {})
          # Blocking call - will be mocked
        end
      end
    end

    before do
      FileUtils.mkdir_p('src')
    end

    context 'when Puma handler is available' do
      before do
        stub_const('Rack::Handler::Puma', puma_handler_class)
        # Mock require to prevent LoadError for rack/handler/puma
        allow(dev_instance).to receive(:require).with('rack/handler/puma').and_return(true)
        # Prevent browser from opening in all tests by default
        allow(dev_instance).to receive(:open_browser)
        # Prevent Thread.new from creating actual threads by default
        allow(Thread).to receive(:new).and_return(instance_double(Thread))
      end

      it 'outputs server start message' do
        allow(Rack::Handler::Puma).to receive(:run)
        expect { dev_instance.send(:start_server) }.to output(
          a_string_including('Starting development server on http://localhost:8080')
        ).to_stdout
      end

      it 'outputs instructions message' do
        allow(Rack::Handler::Puma).to receive(:run)
        expect { dev_instance.send(:start_server) }.to output(
          a_string_including('Press Ctrl+C to stop')
        ).to_stdout
      end

        it 'starts Puma server' do
        expect(Rack::Handler::Puma).to receive(:run).with(
          anything,
          Port: 8080,
          Host: '0.0.0.0'
        )
        dev_instance.send(:start_server)
      end

      it 'outputs handler info message' do
        allow(Rack::Handler::Puma).to receive(:run)
        expect { dev_instance.send(:start_server) }.to output(
          a_string_including('Using handler: puma')
        ).to_stdout
      end

        it 'opens browser after server starts' do
        allow(Rack::Handler::Puma).to receive(:run)
        browser_thread_called = false

        allow(Thread).to receive(:new) do |&block|
          if block
            browser_thread_called = true
            # Execute block immediately for testing (without sleep)
            allow(Kernel).to receive(:sleep)
            block.call
          end
          instance_double(Thread)
        end

        expect(dev_instance).to receive(:open_browser).with('http://localhost:8080/index.html').and_return(nil)

        dev_instance.send(:start_server)

        expect(browser_thread_called).to be true
        end
      end

    context 'when Puma handler is not available' do
      before do
        allow(dev_instance).to receive(:require).with('rack/handler/puma').and_raise(LoadError.new('cannot load such file'))
      end

      it 'outputs error message' do
        expect { dev_instance.send(:start_server) }.to output(
          /Puma handler not available/
        ).to_stdout.and raise_error(SystemExit)
      end

      it 'exits with status 1' do
        expect { dev_instance.send(:start_server) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context 'when server raises an error' do
      before do
        stub_const('Rack::Handler::Puma', puma_handler_class)
        allow(dev_instance).to receive(:require).with('rack/handler/puma').and_return(true)
        allow(Rack::Handler::Puma).to receive(:run).and_raise(StandardError.new('Server error'))
      end

      it 'outputs error message and exits' do
        expect { dev_instance.send(:start_server) }.to output(
          /Server error: Server error/
        ).to_stdout.and raise_error(SystemExit)
      end
    end
  end

  describe '#open_browser' do
    before do
      FileUtils.mkdir_p('src')
    end

    context 'on macOS' do
      before do
        allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return('darwin')
      end

      it 'calls open command' do
        expect(dev_instance).to receive(:system).with('open', 'http://localhost:8080/index.html').and_return(true)
        dev_instance.send(:open_browser, 'http://localhost:8080/index.html')
      end

      context 'when system call fails' do
        before do
          allow(dev_instance).to receive(:system).and_raise(StandardError.new('Command failed'))
        end

        it 'outputs fallback message' do
          expect { dev_instance.send(:open_browser, 'http://localhost:8080/index.html') }.to output(
            /Please open http:\/\/localhost:8080\/index.html in your browser/
          ).to_stdout
        end
      end
    end

    context 'on Linux' do
      before do
        allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return('linux')
      end

      it 'calls xdg-open command' do
        expect(dev_instance).to receive(:system).with('xdg-open', 'http://localhost:8080/index.html').and_return(true)
        dev_instance.send(:open_browser, 'http://localhost:8080/index.html')
      end
    end

    context 'on Windows' do
      before do
        allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return('mswin')
      end

      it 'calls start command' do
        expect(dev_instance).to receive(:system).with('start', 'http://localhost:8080/index.html').and_return(true)
        dev_instance.send(:open_browser, 'http://localhost:8080/index.html')
      end
    end

    context 'on unknown OS' do
      before do
        allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return('unknown')
      end

      it 'outputs manual instruction' do
        expect { dev_instance.send(:open_browser, 'http://localhost:8080/index.html') }.to output(
          /Please open http:\/\/localhost:8080\/index.html in your browser/
        ).to_stdout
      end
    end
  end
end
