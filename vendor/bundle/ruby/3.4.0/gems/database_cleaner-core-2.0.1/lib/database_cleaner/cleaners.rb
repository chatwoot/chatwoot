require 'database_cleaner/cleaner'
require 'database_cleaner/safeguard'

module DatabaseCleaner
  class Cleaners < Hash
    def initialize hash={}
      super.replace(hash)
    end

    # FIXME this method conflates creation with lookup... both a command and a query. yuck.
    def [](orm, **opts)
      raise ArgumentError if orm.nil?
      fetch([orm, opts]) { add_cleaner(orm, **opts) }
    end

    def strategy=(strategy)
      values.each { |cleaner| cleaner.strategy = strategy }
      remove_duplicates
    end

    def start
      Safeguard.new.run
      values.each { |cleaner| cleaner.start }
    end

    def clean
      Safeguard.new.run
      values.each { |cleaner| cleaner.clean }
    end

    def cleaning(&inner_block)
      Safeguard.new.run
      values.inject(inner_block) do |curr_block, cleaner|
        proc { cleaner.cleaning(&curr_block) }
      end.call
    end

    def clean_with(*args)
      Safeguard.new.run
      values.each { |cleaner| cleaner.clean_with(*args) }
    end

    private

    def add_cleaner(orm, **opts)
      self[[orm, opts]] = Cleaner.new(orm, **opts)
    end

    def remove_duplicates
      replace(reduce(Cleaners.new) do |cleaners, (key, value)|
        cleaners[key] = value unless cleaners.values.include?(value)
        cleaners
      end)
    end
  end
end
