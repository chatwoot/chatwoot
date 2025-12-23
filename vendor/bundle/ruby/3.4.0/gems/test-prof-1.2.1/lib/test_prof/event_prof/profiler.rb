# frozen_string_literal: true

module TestProf
  module EventProf
    class Profiler # :nodoc:
      attr_reader :event, :total_count, :total_time, :rank_by, :top_count, :per_example,
        :time, :count, :example_time, :example_count, :absolute_run_time

      alias_method :per_example?, :per_example

      def initialize(event:, instrumenter:, rank_by: :time, top_count: 5, per_example: false)
        @event = event
        @rank_by = rank_by
        @top_count = top_count
        @per_example = per_example

        instrumenter.subscribe(event) { |time| track(time) }

        @groups = Utils::SizedOrderedSet.new(
          top_count, sort_by: rank_by
        )

        @examples = Utils::SizedOrderedSet.new(
          top_count, sort_by: rank_by
        )

        @total_count = 0
        @total_time = 0.0
        @absolute_run_time = 0.0
      end

      def track(time)
        return if @current_group.nil?
        @total_time += time
        @total_count += 1

        @time += time
        @count += 1

        return if @current_example.nil?

        @example_time += time
        @example_count += 1
      end

      def group_started(id)
        reset_group!
        @current_group = id
      end

      def group_finished(id)
        group_run_time = take_time(@group_ts)
        @absolute_run_time += group_run_time

        data = {
          id: id,
          time: @time,
          run_time: group_run_time,
          count: @count,
          examples: @total_examples
        }

        @groups << data unless data[rank_by].zero?

        @current_group = nil
      end

      def example_started(id)
        return unless per_example?
        reset_example!
        @current_example = id
      end

      def example_finished(id)
        @total_examples += 1
        return unless per_example?

        example_run_time = take_time(@example_ts)
        data = {
          id: id,
          time: @example_time,
          run_time: example_run_time,
          count: @example_count
        }

        @examples << data unless data[rank_by].zero?
        @current_example = nil
      end

      def results
        {
          groups: @groups.to_a
        }.tap do |data|
          next unless per_example?

          data[:examples] = @examples.to_a
        end
      end

      def take_time(start_ts)
        TestProf.now - start_ts
      end

      private

      def reset_group!
        @time = 0.0
        @count = 0
        @total_examples = 0
        @group_ts = TestProf.now
      end

      def reset_example!
        @example_count = 0
        @example_time = 0.0
        @example_ts = TestProf.now
      end
    end

    # Multiple profilers wrapper
    class ProfilersGroup
      attr_reader :profilers

      def initialize(event:, **options)
        events = event.split(",")
        @profilers = events.map do |ev|
          Profiler.new(event: ev, **options)
        end
      end

      def each(&block)
        if block
          @profilers.each(&block)
        else
          @profilers.each
        end
      end

      def events
        @profilers.map(&:event)
      end

      %i[group_started group_finished example_started example_finished].each do |name|
        class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{name}(id)
            @profilers.each { |profiler| profiler.#{name}(id) }
          end
        CODE
      end
    end
  end
end
