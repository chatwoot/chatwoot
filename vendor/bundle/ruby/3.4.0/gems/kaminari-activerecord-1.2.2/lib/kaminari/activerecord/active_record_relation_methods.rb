# frozen_string_literal: true

module Kaminari
  # Active Record specific page scope methods implementations
  module ActiveRecordRelationMethods
    # Used for page_entry_info
    def entry_name(options = {})
      default = options[:count] == 1 ? model_name.human : model_name.human.pluralize
      model_name.human(options.reverse_merge(default: default))
    end

    def reset #:nodoc:
      @total_count = nil
      super
    end

    def total_count(column_name = :all, _options = nil) #:nodoc:
      return @total_count if defined?(@total_count) && @total_count

      # There are some cases that total count can be deduced from loaded records
      if loaded?
        # Total count has to be 0 if loaded records are 0
        return @total_count = 0 if (current_page == 1) && @records.empty?
        # Total count is calculable at the last page
        return @total_count = (current_page - 1) * limit_value + @records.length if @records.any? && (@records.length < limit_value)
      end

      # #count overrides the #select which could include generated columns referenced in #order, so skip #order here, where it's irrelevant to the result anyway
      c = except(:offset, :limit, :order)
      # Remove includes only if they are irrelevant
      c = c.except(:includes) unless references_eager_loaded_tables?

      c = c.limit(max_pages * limit_value) if max_pages && max_pages.respond_to?(:*)

      # .group returns an OrderedHash that responds to #count
      c = c.count(column_name)
      @total_count = if c.is_a?(Hash) || c.is_a?(ActiveSupport::OrderedHash)
                       c.count
                     elsif c.respond_to? :count
                       c.count(column_name)
                     else
                       c
                     end
    end

    # Turn this Relation to a "without count mode" Relation.
    # Note that the "without count mode" is supposed to be performant but has a feature limitation.
    #   Pro: paginates without casting an extra SELECT COUNT query
    #   Con: unable to know the total number of records/pages
    def without_count
      extend ::Kaminari::PaginatableWithoutCount
    end
  end

  # A module that makes AR::Relation paginatable without having to cast another SELECT COUNT query
  module PaginatableWithoutCount
    module LimitValueSetter
      # refine PaginatableWithoutCount do  # NOTE: this doesn't work in Ruby < 2.4
      refine ::ActiveRecord::Relation do
        private

        # Update multiple instance variables that hold `limit` to a given value
        def set_limit_value(new_limit)
          @values[:limit] = new_limit

          if @arel
            case @arel.limit.class.name
            when 'Integer', 'Fixnum'
              @arel.limit = new_limit
            when 'ActiveModel::Attribute::WithCastValue'  # comparing by class name because ActiveModel::Attribute::WithCastValue is a private constant
              @arel.limit = build_cast_value 'LIMIT', new_limit
            when 'Arel::Nodes::BindParam'
              if @arel.limit.respond_to?(:value)
                @arel.limit = Arel::Nodes::BindParam.new(@arel.limit.value.with_cast_value(new_limit))
              end
            end
          end
        end
      end
    end
  end
end
# NOTE: ending all modules and reopening again because using has to be called from the toplevel in Ruby 2.0
using Kaminari::PaginatableWithoutCount::LimitValueSetter

module Kaminari
  module PaginatableWithoutCount
    # Overwrite AR::Relation#load to actually load one more record to judge if the page has next page
    # then store the result in @_has_next ivar
    def load
      if loaded? || limit_value.nil?
        super
      else
        set_limit_value limit_value + 1
        super
        set_limit_value limit_value - 1

        if @records.any?
          @records = @records.dup if (frozen = @records.frozen?)
          @_has_next = !!@records.delete_at(limit_value)
          @records.freeze if frozen
        end

        self
      end
    end

    # The page wouldn't be the last page if there's "limit + 1" record
    def last_page?
      !out_of_range? && !@_has_next
    end

    # Empty relation needs no pagination
    def out_of_range?
      load unless loaded?
      @records.empty?
    end

    # Force to raise an exception if #total_count is called explicitly.
    def total_count
      raise "This scope is marked as a non-count paginable scope and can't be used in combination " \
            "with `#paginate' or `#page_entries_info'. Use #link_to_next_page or #link_to_previous_page instead."
    end
  end
end
