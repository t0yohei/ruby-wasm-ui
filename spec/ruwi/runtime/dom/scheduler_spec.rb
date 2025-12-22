# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruwi::Dom::Scheduler do
  let(:mock_job) { -> { 'job executed' } }
  let(:js) { class_double('JS').as_stubbed_const }
  let(:global) { double('JS.global') }

  before do
    allow(js).to receive(:global).and_return(global)
    allow(global).to receive(:queueMicrotask)
    described_class.initialize_scheduler
  end

  describe '.initialize_scheduler' do
    it 'initializes the scheduler with empty jobs and scheduled false' do
      expect(described_class.jobs).to eq([])
      expect(described_class.scheduled).to be false
    end
  end

  describe '.enqueue_job' do
    context 'when jobs is nil' do
      before do
        described_class.jobs = nil
      end

      it 'initializes scheduler and enqueues the job' do
        described_class.enqueue_job(mock_job)
        expect(described_class.jobs).to eq([mock_job])
      end
    end

    context 'when jobs is already initialized' do
      it 'enqueues the job' do
        described_class.enqueue_job(mock_job)
        expect(described_class.jobs).to eq([mock_job])
      end
    end

    it 'schedules an update' do
      expect(global).to receive(:queueMicrotask)
      described_class.enqueue_job(mock_job)
    end
  end

  describe '.schedule_update' do
    context 'when not already scheduled' do
      before do
        described_class.scheduled = false
      end

      it 'sets scheduled to true and queues microtask' do
        expect(global).to receive(:queueMicrotask)
        described_class.send(:schedule_update)
        expect(described_class.scheduled).to be true
      end
    end

    context 'when already scheduled' do
      before do
        described_class.scheduled = true
      end

      it 'does not queue microtask' do
        expect(global).not_to receive(:queueMicrotask)
        described_class.send(:schedule_update)
      end
    end
  end

  describe '.process_jobs' do
    let(:job1) { spy('job1') }
    let(:job2) { spy('job2') }

    before do
      described_class.jobs = [job1, job2]
      described_class.scheduled = true
    end

    it 'processes all jobs in the queue' do
      described_class.send(:process_jobs)
      expect(job1).to have_received(:call)
      expect(job2).to have_received(:call)
    end

    it 'empties the jobs queue' do
      described_class.send(:process_jobs)
      expect(described_class.jobs).to be_empty
    end

    it 'sets scheduled to false after processing' do
      described_class.send(:process_jobs)
      expect(described_class.scheduled).to be false
    end
  end
end
