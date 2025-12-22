module Ruwi
  module Dom
    module Scheduler
      class << self
        # @return [Boolean] Flag indicating if a job processing is scheduled
        attr_accessor :scheduled

        # @return [Array] Array of jobs to be processed
        attr_accessor :jobs

        # Initialize class variables
        def initialize_scheduler
          @scheduled = false
          @jobs = []
        end

        # Enqueues a job to be processed
        # @param job [Proc] The job to be executed
        # @return [void]
        def enqueue_job(job)
          initialize_scheduler if @jobs.nil?
          @jobs.push(job)
          schedule_update
        end

        private

        # Schedules an update if not already scheduled
        # @return [void]
        def schedule_update
          return if @scheduled

          @scheduled = true
          # Using JS.global to access queueMicrotask
          JS.global.queueMicrotask(-> { process_jobs })
        end

        # Processes all jobs in the queue
        # @return [void]
        def process_jobs
          while @jobs.any?
            job = @jobs.shift
            job.call
          end

          @scheduled = false
        end
      end
    end
  end
end
