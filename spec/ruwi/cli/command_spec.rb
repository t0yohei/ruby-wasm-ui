# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruwi::Cli::Command do
  describe '.run' do
    context 'when command is provided' do
      context 'with valid command' do
        context 'setup command' do
          let(:setup_instance) { instance_double(Ruwi::Cli::Command::Setup) }

          before do
            allow(Ruwi::Cli::Command::Setup).to receive(:new).and_return(setup_instance)
            allow(setup_instance).to receive(:run)
          end

          it 'executes the setup command' do
            expect(setup_instance).to receive(:run).with([])
            described_class.run(['setup'])
          end

          it 'passes remaining arguments to the command' do
            expect(setup_instance).to receive(:run).with(['arg1', 'arg2'])
            described_class.run(['setup', 'arg1', 'arg2'])
          end
        end

        context 'dev command' do
          let(:dev_instance) { instance_double(Ruwi::Cli::Command::Dev) }

          before do
            allow(Ruwi::Cli::Command::Dev).to receive(:new).and_return(dev_instance)
            allow(dev_instance).to receive(:run)
          end

          it 'executes the dev command' do
            expect(dev_instance).to receive(:run).with([])
            described_class.run(['dev'])
          end

          it 'passes remaining arguments to the command' do
            expect(dev_instance).to receive(:run).with(['arg1', 'arg2'])
            described_class.run(['dev', 'arg1', 'arg2'])
          end
        end

        context 'rebuild command' do
          let(:rebuild_instance) { instance_double(Ruwi::Cli::Command::Rebuild) }

          before do
            allow(Ruwi::Cli::Command::Rebuild).to receive(:new).and_return(rebuild_instance)
            allow(rebuild_instance).to receive(:run)
          end

          it 'executes the rebuild command' do
            expect(rebuild_instance).to receive(:run).with([])
            described_class.run(['rebuild'])
          end

          it 'passes remaining arguments to the command' do
            expect(rebuild_instance).to receive(:run).with(['arg1', 'arg2'])
            described_class.run(['rebuild', 'arg1', 'arg2'])
          end
        end
      end

      context 'with invalid command' do
        it 'prints error message and shows usage' do
          expect { described_class.run(['unknown']) }.to output(
            /Unknown command: unknown/
          ).to_stdout.and raise_error(SystemExit)
        end
      end
    end

    context 'when no command is provided' do
      it 'shows usage and exits' do
        expect { described_class.run([]) }.to output(
          /Usage: ruwi <command>/
        ).to_stdout.and raise_error(SystemExit)
      end
    end
  end

  describe '.show_usage' do
    it 'displays usage information' do
      expect { described_class.show_usage }.to output(
        /Usage: ruwi <command>/
      ).to_stdout
    end

    it 'lists available commands' do
      expect { described_class.show_usage }.to output(
        /setup.*Set up the project for ruwi/
      ).to_stdout
      expect { described_class.show_usage }.to output(
        /dev.*Start development server with file watching and auto-build/
      ).to_stdout
      expect { described_class.show_usage }.to output(
        /rebuild.*Rebuild Ruby WASM file/
      ).to_stdout
    end
  end

  describe 'COMMANDS' do
    it 'contains setup command' do
      expect(described_class::COMMANDS).to include('setup' => Ruwi::Cli::Command::Setup)
    end

    it 'contains dev command' do
      expect(described_class::COMMANDS).to include('dev' => Ruwi::Cli::Command::Dev)
    end

    it 'contains rebuild command' do
      expect(described_class::COMMANDS).to include('rebuild' => Ruwi::Cli::Command::Rebuild)
    end
  end
end
