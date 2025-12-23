module Enumerable
  Groupdate::PERIODS.each do |period|
    define_method :"group_by_#{period}" do |*args, **options, &block|
      if block
        raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 0)" if args.any?
        Groupdate::Magic::Enumerable.group_by(self, period, options, &block)
      elsif respond_to?(:scoping)
        scoping { @klass.group_by_period(period, *args, **options, &block) }
      else
        raise ArgumentError, "no block given"
      end
    end
  end

  def group_by_period(period, *args, **options, &block)
    if block || !respond_to?(:scoping)
      raise ArgumentError, "wrong number of arguments (given #{args.size + 1}, expected 1)" if args.any?

      Groupdate::Magic.validate_period(period, options.delete(:permit))
      send("group_by_#{period}", **options, &block)
    else
      scoping { @klass.group_by_period(period, *args, **options, &block) }
    end
  end
end
