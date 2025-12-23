module ScoutApm
  class Debug
    # see self.instance
    @@instance = nil

    def self.instance
      @@instance ||= new
    end

    def register_periodic_hook(&hook)
      @periodic_hooks << hook
    end

    def call_periodic_hooks
      @periodic_hooks.each do |hook|
        begin
          hook.call
        rescue => e
          logger.info("Periodic debug hook failed to run: #{e}\n\t#{e.backtrace.join("\n\t")}")
        end
      end
    rescue
      # Something went super wrong for the inner rescue to not catch this. Just
      # swallow the error. The debug tool should never crash the app.
    end

    private

    def initialize
      @periodic_hooks = []
    end

    def logger
      ScoutApm::Agent.instance.context.logger
    end
  end
end
