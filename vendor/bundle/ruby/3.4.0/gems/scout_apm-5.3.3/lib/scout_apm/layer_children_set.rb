module ScoutApm
  # A set of children records for any given Layer.  This implements some
  # rate-limiting logic.
  #
  # We store the first `unique_cutoff` count of each layer type. So if cutoff
  # is 1000, we'd store 1000 HTTP layers, and 1000 ActiveRecord calls, and 1000
  # of each other layer type. After that, make a LimitedLayer object and store
  # only aggregate counts and times of future layers of that type. (So the
  # 1001st an onward of ActiveRecord would get only aggregate times, and
  # counts, without any detail about the SQL called)
  #
  # When the set of children is small, keep them unique
  # When the set of children gets large enough, stop keeping details
  #
  # The next optimization, which is not yet implemented:
  #   when the set of children gets larger, attempt to merge them without data loss
  class LayerChildrenSet
    include Enumerable

    # By default, how many unique children of a type do we store before
    # flipping over to storing only aggregate info.
    DEFAULT_UNIQUE_CUTOFF = 2000
    attr_reader :unique_cutoff

    # The Set of children objects
    attr_reader :children
    private :children

    def initialize(unique_cutoff = DEFAULT_UNIQUE_CUTOFF)
      @children = Hash.new
      @limited_layers = nil # populated when needed
      @unique_cutoff = unique_cutoff
    end

    def child_set(metric_type)
      children[metric_type] = Set.new if !children.has_key?(metric_type)
      children[metric_type]
    end

    # Add a new layer into this set
    # Only add completed layers - otherwise this will collect up incorrect info
    # into the created LimitedLayer, since it will "freeze" any current data for
    # total_call_time and similar methods.
    def <<(child)
      metric_type = child.type
      set = child_set(metric_type)

      if set.size >= unique_cutoff
        # find or create limited_layer
        @limited_layers ||= Hash.new 
        layer = if @limited_layers.has_key?(metric_type)
                  @limited_layers[metric_type]
                else
                  @limited_layers[metric_type] = LimitedLayer.new(metric_type)
                end

        layer.absorb(child)
      else
        # we have space just add it
        set << child
      end
    end

    def each
      children.each do |_type, set|
        set.each do |child_layer|
          yield child_layer
        end
      end

      if @limited_layers
        @limited_layers.each do |_type, limited_layer|
          yield limited_layer
        end
      end
    end

    def length
      @children.length
    end

    def size
      @children.size
    end
  end
end
