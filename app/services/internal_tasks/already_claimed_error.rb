module InternalTasks
  class AlreadyClaimedError < StandardError
    attr_reader :task

    def initialize(task)
      @task = task
      super('Task already claimed by another user')
    end
  end
end
