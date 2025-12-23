module Searchkick
  class Results
    include Enumerable
    extend Forwardable

    # TODO remove klass and options in 6.0
    attr_reader :klass, :response, :options

    def_delegators :results, :each, :any?, :empty?, :size, :length, :slice, :[], :to_ary

    def initialize(klass, response, options = {})
      @klass = klass
      @response = response
      @options = options
    end

    # TODO make private in 6.0
    def results
      @results ||= with_hit.map(&:first)
    end

    def with_hit
      return enum_for(:with_hit) unless block_given?

      build_hits.each do |result|
        yield result
      end
    end

    def missing_records
      @missing_records ||= with_hit_and_missing_records[1]
    end

    def suggestions
      if response["suggest"]
        response["suggest"].values.flat_map { |v| v.first["options"] }.sort_by { |o| -o["score"] }.map { |o| o["text"] }.uniq
      elsif options[:suggest] || options[:term] == "*" # TODO remove 2nd term
        []
      else
        raise "Pass `suggest: true` to the search method for suggestions"
      end
    end

    def aggregations
      response["aggregations"]
    end

    def aggs
      @aggs ||= begin
        if aggregations
          aggregations.dup.each do |field, filtered_agg|
            buckets = filtered_agg[field]
            # move the buckets one level above into the field hash
            if buckets
              filtered_agg.delete(field)
              filtered_agg.merge!(buckets)
            end
          end
        end
      end
    end

    def took
      response["took"]
    end

    def error
      response["error"]
    end

    def model_name
      if klass.nil?
        ActiveModel::Name.new(self.class, nil, 'Result')
      else
        klass.model_name
      end
    end

    def entry_name(options = {})
      if options.empty?
        # backward compatibility
        model_name.human.downcase
      else
        default = options[:count] == 1 ? model_name.human : model_name.human.pluralize
        model_name.human(options.reverse_merge(default: default))
      end
    end

    def total_count
      if options[:total_entries]
        options[:total_entries]
      elsif response["hits"]["total"].is_a?(Hash)
        response["hits"]["total"]["value"]
      else
        response["hits"]["total"]
      end
    end
    alias_method :total_entries, :total_count

    def current_page
      options[:page]
    end

    def per_page
      options[:per_page]
    end
    alias_method :limit_value, :per_page

    def padding
      options[:padding]
    end

    def total_pages
      (total_count / per_page.to_f).ceil
    end
    alias_method :num_pages, :total_pages

    def offset_value
      (current_page - 1) * per_page + padding
    end
    alias_method :offset, :offset_value

    def previous_page
      current_page > 1 ? (current_page - 1) : nil
    end
    alias_method :prev_page, :previous_page

    def next_page
      current_page < total_pages ? (current_page + 1) : nil
    end

    def first_page?
      previous_page.nil?
    end

    def last_page?
      next_page.nil?
    end

    def out_of_range?
      current_page > total_pages
    end

    def hits
      if error
        raise Error, "Query error - use the error method to view it"
      else
        @response["hits"]["hits"]
      end
    end

    def highlights(multiple: false)
      hits.map do |hit|
        hit_highlights(hit, multiple: multiple)
      end
    end

    def with_highlights(multiple: false)
      return enum_for(:with_highlights, multiple: multiple) unless block_given?

      with_hit.each do |result, hit|
        yield result, hit_highlights(hit, multiple: multiple)
      end
    end

    def with_score
      return enum_for(:with_score) unless block_given?

      with_hit.each do |result, hit|
        yield result, hit["_score"]
      end
    end

    def misspellings?
      @options[:misspellings]
    end

    def scroll_id
      @response["_scroll_id"]
    end

    def scroll
      raise Error, "Pass `scroll` option to the search method for scrolling" unless scroll_id

      if block_given?
        records = self
        while records.any?
          yield records
          records = records.scroll
        end

        records.clear_scroll
      else
        begin
          # TODO Active Support notifications for this scroll call
          Results.new(@klass, Searchkick.client.scroll(scroll: options[:scroll], body: {scroll_id: scroll_id}), @options)
        rescue => e
          if Searchkick.not_found_error?(e) && e.message =~ /search_context_missing_exception/i
            raise Error, "Scroll id has expired"
          else
            raise e
          end
        end
      end
    end

    def clear_scroll
      begin
        # try to clear scroll
        # not required as scroll will expire
        # but there is a cost to open scrolls
        Searchkick.client.clear_scroll(scroll_id: scroll_id)
      rescue => e
        raise e unless Searchkick.transport_error?(e)
      end
    end

    private

    def with_hit_and_missing_records
      @with_hit_and_missing_records ||= begin
        missing_records = []

        if options[:load]
          grouped_hits = hits.group_by { |hit, _| hit["_index"] }

          # determine models
          index_models = {}
          grouped_hits.each do |index, _|
            models =
              if @klass
                [@klass]
              else
                index_alias = index.split("_")[0..-2].join("_")
                Array((options[:index_mapping] || {})[index_alias])
              end
            raise Error, "Unknown model for index: #{index}. Pass the `models` option to the search method." unless models.any?
            index_models[index] = models
          end

          # fetch results
          results = {}
          grouped_hits.each do |index, index_hits|
            results[index] = {}
            index_models[index].each do |model|
              results[index].merge!(results_query(model, index_hits).to_a.index_by { |r| r.id.to_s })
            end
          end

          # sort
          results =
            hits.map do |hit|
              result = results[hit["_index"]][hit["_id"].to_s]
              if result && !(options[:load].is_a?(Hash) && options[:load][:dumpable])
                if (hit["highlight"] || options[:highlight]) && !result.respond_to?(:search_highlights)
                  highlights = hit_highlights(hit)
                  result.define_singleton_method(:search_highlights) do
                    highlights
                  end
                end
              end
              [result, hit]
            end.select do |result, hit|
              unless result
                models = index_models[hit["_index"]]
                missing_records << {
                  id: hit["_id"],
                  # may be multiple models for inheritance with child models
                  # not ideal to return different types
                  # but this situation shouldn't be common
                  model: models.size == 1 ? models.first : models
                }
              end
              result
            end
        else
          results =
            hits.map do |hit|
              result =
                if hit["_source"]
                  hit.except("_source").merge(hit["_source"])
                elsif hit["fields"]
                  hit.except("fields").merge(hit["fields"])
                else
                  hit
                end

              if hit["highlight"] || options[:highlight]
                highlight = hit["highlight"].to_a.to_h { |k, v| [base_field(k), v.first] }
                options[:highlighted_fields].map { |k| base_field(k) }.each do |k|
                  result["highlighted_#{k}"] ||= (highlight[k] || result[k])
                end
              end

              result["id"] ||= result["_id"] # needed for legacy reasons
              [HashWrapper.new(result), hit]
            end
        end

       [results, missing_records]
      end
    end

    def build_hits
      @build_hits ||= begin
        if missing_records.any?
          Searchkick.warn("Records in search index do not exist in database: #{missing_records.map { |v| "#{Array(v[:model]).map(&:model_name).sort.join("/")} #{v[:id]}" }.join(", ")}")
        end
        with_hit_and_missing_records[0]
      end
    end

    def results_query(records, hits)
      records = Searchkick.scope(records)

      ids = hits.map { |hit| hit["_id"] }
      if options[:includes] || options[:model_includes]
        included_relations = []
        combine_includes(included_relations, options[:includes])
        combine_includes(included_relations, options[:model_includes][records]) if options[:model_includes]

        records = records.includes(included_relations)
      end

      if options[:scope_results]
        records = options[:scope_results].call(records)
      end

      Searchkick.load_records(records, ids)
    end

    def combine_includes(result, inc)
      if inc
        if inc.is_a?(Array)
          result.concat(inc)
        else
          result << inc
        end
      end
    end

    def base_field(k)
      k.sub(/\.(analyzed|word_start|word_middle|word_end|text_start|text_middle|text_end|exact)\z/, "")
    end

    def hit_highlights(hit, multiple: false)
      if hit["highlight"]
        hit["highlight"].to_h { |k, v| [(options[:json] ? k : k.sub(/\.#{@options[:match_suffix]}\z/, "")).to_sym, multiple ? v : v.first] }
      else
        {}
      end
    end
  end
end
