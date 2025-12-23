# Abstract strategy class for orm adapter gems to subclass

module DatabaseCleaner
  class Strategy
    # Override this method if the strategy accepts options
    def initialize(options=nil)
      if options
        name = self.class.name.sub("DatabaseCleaner::","").sub("::"," ") # e.g. "ActiveRecord Transaction"
        raise ArgumentError, "No options are available for the #{name} strategy."
      end
    end

    def db
      @db ||= :default
    end
    attr_writer :db

    # Override this method to start a database transaction if the strategy uses them
    def start
    end

    # Override this method with the actual cleaning procedure. Its the only mandatory method implementation.
    def clean
      raise NotImplementedError
    end

    def cleaning(&block)
      begin
        start
        yield
      ensure
        clean
      end
    end
  end
end
