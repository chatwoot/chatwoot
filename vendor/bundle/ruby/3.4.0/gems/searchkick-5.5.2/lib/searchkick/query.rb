module Searchkick
  class Query
    include Enumerable
    extend Forwardable

    @@metric_aggs = [:avg, :cardinality, :max, :min, :sum]

    attr_reader :klass, :term, :options
    attr_accessor :body

    def_delegators :execute, :map, :each, :any?, :empty?, :size, :length, :slice, :[], :to_ary,
      :results, :suggestions, :each_with_hit, :with_details, :aggregations, :aggs,
      :took, :error, :model_name, :entry_name, :total_count, :total_entries,
      :current_page, :per_page, :limit_value, :padding, :total_pages, :num_pages,
      :offset_value, :offset, :previous_page, :prev_page, :next_page, :first_page?, :last_page?,
      :out_of_range?, :hits, :response, :to_a, :first, :scroll, :highlights, :with_highlights,
      :with_score, :misspellings?, :scroll_id, :clear_scroll, :missing_records, :with_hit

    def initialize(klass, term = "*", **options)
      unknown_keywords = options.keys - [:aggs, :block, :body, :body_options, :boost,
        :boost_by, :boost_by_distance, :boost_by_recency, :boost_where, :conversions, :conversions_term, :debug, :emoji, :exclude, :explain,
        :fields, :highlight, :includes, :index_name, :indices_boost, :knn, :limit, :load,
        :match, :misspellings, :models, :model_includes, :offset, :operator, :order, :padding, :page, :per_page, :profile,
        :request_params, :routing, :scope_results, :scroll, :select, :similar, :smart_aggs, :suggest, :total_entries, :track, :type, :where]
      raise ArgumentError, "unknown keywords: #{unknown_keywords.join(", ")}" if unknown_keywords.any?

      term = term.to_s

      if options[:emoji]
        term = EmojiParser.parse_unicode(term) { |e| " #{e.name.tr('_', ' ')} " }.strip
      end

      @klass = klass
      @term = term
      @options = options
      @match_suffix = options[:match] || searchkick_options[:match] || "analyzed"

      # prevent Ruby warnings
      @type = nil
      @routing = nil
      @misspellings = false
      @misspellings_below = nil
      @highlighted_fields = nil
      @index_mapping = nil

      prepare
    end

    def searchkick_index
      klass ? klass.searchkick_index : nil
    end

    def searchkick_options
      klass ? klass.searchkick_options : {}
    end

    def searchkick_klass
      klass ? klass.searchkick_klass : nil
    end

    def params
      if options[:models]
        @index_mapping = {}
        Array(options[:models]).each do |model|
          # there can be multiple models per index name due to inheritance - see #1259
          (@index_mapping[model.searchkick_index.name] ||= []) << model
        end
      end

      index =
        if options[:index_name]
          Array(options[:index_name]).map { |v| v.respond_to?(:searchkick_index) ? v.searchkick_index.name : v }.join(",")
        elsif options[:models]
          @index_mapping.keys.join(",")
        elsif searchkick_index
          searchkick_index.name
        else
          # fixes warning about accessing system indices
          "*,-.*"
        end

      params = {
        index: index,
        body: body
      }
      params[:type] = @type if @type
      params[:routing] = @routing if @routing
      params[:scroll] = @scroll if @scroll
      params.merge!(options[:request_params]) if options[:request_params]
      params
    end

    def execute
      @execute ||= begin
        begin
          response = execute_search
          if retry_misspellings?(response)
            prepare
            response = execute_search
          end
        rescue => e # TODO rescue type
          handle_error(e)
        end
        handle_response(response)
      end
    end

    def to_curl
      query = params
      type = query[:type]
      index = query[:index].is_a?(Array) ? query[:index].join(",") : query[:index]
      request_params = query.except(:index, :type, :body)

      # no easy way to tell which host the client will use
      host =
        if Searchkick.client.transport.respond_to?(:transport)
          Searchkick.client.transport.transport.hosts.first
        else
          Searchkick.client.transport.hosts.first
        end
      credentials = host[:user] || host[:password] ? "#{host[:user]}:#{host[:password]}@" : nil
      params = ["pretty"]
      request_params.each do |k, v|
        params << "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"
      end
      "curl #{host[:protocol]}://#{credentials}#{host[:host]}:#{host[:port]}/#{CGI.escape(index)}#{type ? "/#{type.map { |t| CGI.escape(t) }.join(',')}" : ''}/_search?#{params.join('&')} -H 'Content-Type: application/json' -d '#{query[:body].to_json}'"
    end

    def handle_response(response)
      opts = {
        page: @page,
        per_page: @per_page,
        padding: @padding,
        load: @load,
        includes: options[:includes],
        model_includes: options[:model_includes],
        json: !@json.nil?,
        match_suffix: @match_suffix,
        highlight: options[:highlight],
        highlighted_fields: @highlighted_fields || [],
        misspellings: @misspellings,
        term: term,
        scope_results: options[:scope_results],
        total_entries: options[:total_entries],
        index_mapping: @index_mapping,
        suggest: options[:suggest],
        scroll: options[:scroll]
      }

      if options[:debug]
        puts "Searchkick Version: #{Searchkick::VERSION}"
        puts "Elasticsearch Version: #{Searchkick.server_version}"
        puts

        puts "Model Searchkick Options"
        pp searchkick_options
        puts

        puts "Search Options"
        pp options
        puts

        if searchkick_index
          puts "Model Search Data"
          begin
            pp klass.limit(3).map { |r| RecordData.new(searchkick_index, r).index_data }
          rescue => e
            puts "#{e.class.name}: #{e.message}"
          end
          puts

          puts "Elasticsearch Mapping"
          puts JSON.pretty_generate(searchkick_index.mapping)
          puts

          puts "Elasticsearch Settings"
          puts JSON.pretty_generate(searchkick_index.settings)
          puts
        end

        puts "Elasticsearch Query"
        puts to_curl
        puts

        puts "Elasticsearch Results"
        puts JSON.pretty_generate(response)
      end

      # set execute for multi search
      @execute = Results.new(searchkick_klass, response, opts)
    end

    def retry_misspellings?(response)
      @misspellings_below && response["error"].nil? && Results.new(searchkick_klass, response).total_count < @misspellings_below
    end

    private

    def handle_error(e)
      status_code = e.message[1..3].to_i
      if status_code == 404
        if e.message.include?("No search context found for id")
          raise MissingIndexError, "No search context found for id"
        else
          raise MissingIndexError, "Index missing - run #{reindex_command}"
        end
      elsif status_code == 500 && (
        e.message.include?("IllegalArgumentException[minimumSimilarity >= 1]") ||
        e.message.include?("No query registered for [multi_match]") ||
        e.message.include?("[match] query does not support [cutoff_frequency]") ||
        e.message.include?("No query registered for [function_score]")
      )

        raise UnsupportedVersionError
      elsif status_code == 400
        if (
          e.message.include?("bool query does not support [filter]") ||
          e.message.include?("[bool] filter does not support [filter]")
        )

          raise UnsupportedVersionError
        elsif e.message.match?(/analyzer \[searchkick_.+\] not found/)
          raise InvalidQueryError, "Bad mapping - run #{reindex_command}"
        else
          raise InvalidQueryError, e.message
        end
      else
        raise e
      end
    end

    def reindex_command
      searchkick_klass ? "#{searchkick_klass.name}.reindex" : "reindex"
    end

    def execute_search
      name = searchkick_klass ? "#{searchkick_klass.name} Search" : "Search"
      event = {
        name: name,
        query: params
      }
      ActiveSupport::Notifications.instrument("search.searchkick", event) do
        Searchkick.client.search(params)
      end
    end

    def prepare
      boost_fields, fields = set_fields

      operator = options[:operator] || "and"

      # pagination
      page = [options[:page].to_i, 1].max
      # maybe use index.max_result_window in the future
      default_limit = searchkick_options[:deep_paging] ? 1_000_000_000 : 10_000
      per_page = (options[:limit] || options[:per_page] || default_limit).to_i
      padding = [options[:padding].to_i, 0].max
      offset = (options[:offset] || (page - 1) * per_page + padding).to_i
      scroll = options[:scroll]

      max_result_window = searchkick_options[:max_result_window]
      original_per_page = per_page
      if max_result_window
        offset = max_result_window if offset > max_result_window
        per_page = max_result_window - offset if offset + per_page > max_result_window
      end

      # model and eager loading
      load = options[:load].nil? ? true : options[:load]

      all = term == "*"

      @json = options[:body]
      if @json
        ignored_options = options.keys & [:aggs, :boost,
          :boost_by, :boost_by_distance, :boost_by_recency, :boost_where, :conversions, :conversions_term, :exclude, :explain,
          :fields, :highlight, :indices_boost, :match, :misspellings, :operator, :order,
          :profile, :select, :smart_aggs, :suggest, :where]
        raise ArgumentError, "Options incompatible with body option: #{ignored_options.join(", ")}" if ignored_options.any?
        payload = @json
      else
        must_not = []
        should = []

        if options[:similar]
          like = options[:similar] == true ? term : options[:similar]
          query = {
            more_like_this: {
              like: like,
              min_doc_freq: 1,
              min_term_freq: 1,
              analyzer: "searchkick_search2"
            }
          }
          if fields.all? { |f| f.start_with?("*.") }
            raise ArgumentError, "Must specify fields to search"
          end
          if fields != ["_all"]
            query[:more_like_this][:fields] = fields
          end
        elsif all && !options[:exclude]
          query = {
            match_all: {}
          }
        else
          queries = []

          misspellings =
            if options.key?(:misspellings)
              options[:misspellings]
            else
              true
            end

          if misspellings.is_a?(Hash) && misspellings[:below] && !@misspellings_below
            @misspellings_below = misspellings[:below].to_i
            misspellings = false
          end

          if misspellings != false
            edit_distance = (misspellings.is_a?(Hash) && (misspellings[:edit_distance] || misspellings[:distance])) || 1
            transpositions =
              if misspellings.is_a?(Hash) && misspellings.key?(:transpositions)
                {fuzzy_transpositions: misspellings[:transpositions]}
              else
                {fuzzy_transpositions: true}
              end
            prefix_length = (misspellings.is_a?(Hash) && misspellings[:prefix_length]) || 0
            default_max_expansions = @misspellings_below ? 20 : 3
            max_expansions = (misspellings.is_a?(Hash) && misspellings[:max_expansions]) || default_max_expansions
            misspellings_fields = misspellings.is_a?(Hash) && misspellings.key?(:fields) && misspellings[:fields].map(&:to_s)

            if misspellings_fields
              missing_fields = misspellings_fields - fields.map { |f| base_field(f) }
              if missing_fields.any?
                raise ArgumentError, "All fields in per-field misspellings must also be specified in fields option"
              end
            end

            @misspellings = true
          else
            @misspellings = false
          end

          fields.each do |field|
            queries_to_add = []
            qs = []

            factor = boost_fields[field] || 1
            shared_options = {
              query: term,
              boost: 10 * factor
            }

            match_type =
              if field.end_with?(".phrase")
                field =
                  if field == "_all.phrase"
                    "_all"
                  else
                    field.sub(/\.phrase\z/, ".analyzed")
                  end

                :match_phrase
              else
                :match
              end

            shared_options[:operator] = operator if match_type == :match

            exclude_analyzer = nil
            exclude_field = field

            field_misspellings = misspellings && (!misspellings_fields || misspellings_fields.include?(base_field(field)))

            if field == "_all" || field.end_with?(".analyzed")
              shared_options[:cutoff_frequency] = 0.001 unless operator.to_s == "and" || field_misspellings == false || (!below73? && !track_total_hits?) || match_type == :match_phrase || !below80? || Searchkick.opensearch?
              qs << shared_options.merge(analyzer: "searchkick_search")

              # searchkick_search and searchkick_search2 are the same for some languages
              unless %w(japanese japanese2 korean polish ukrainian vietnamese).include?(searchkick_options[:language])
                qs << shared_options.merge(analyzer: "searchkick_search2")
              end
              exclude_analyzer = "searchkick_search2"
            elsif field.end_with?(".exact")
              f = field.split(".")[0..-2].join(".")
              queries_to_add << {match: {f => shared_options.merge(analyzer: "keyword")}}
              exclude_field = f
              exclude_analyzer = "keyword"
            else
              analyzer = field.match?(/\.word_(start|middle|end)\z/) ? "searchkick_word_search" : "searchkick_autocomplete_search"
              qs << shared_options.merge(analyzer: analyzer)
              exclude_analyzer = analyzer
            end

            if field_misspellings != false && match_type == :match
              qs.concat(qs.map { |q| q.except(:cutoff_frequency).merge(fuzziness: edit_distance, prefix_length: prefix_length, max_expansions: max_expansions, boost: factor).merge(transpositions) })
            end

            if field.start_with?("*.")
              q2 = qs.map { |q| {multi_match: q.merge(fields: [field], type: match_type == :match_phrase ? "phrase" : "best_fields")} }
            else
              q2 = qs.map { |q| {match_type => {field => q}} }
            end

            # boost exact matches more
            if field =~ /\.word_(start|middle|end)\z/ && searchkick_options[:word] != false
              queries_to_add << {
                bool: {
                  must: {
                    bool: {
                      should: q2
                    }
                  },
                  should: {match_type => {field.sub(/\.word_(start|middle|end)\z/, ".analyzed") => qs.first}}
                }
              }
            else
              queries_to_add.concat(q2)
            end

            queries << queries_to_add

            if options[:exclude]
              must_not.concat(set_exclude(exclude_field, exclude_analyzer))
            end
          end

          # all + exclude option
          if all
            query = {
              match_all: {}
            }

            should = []
          else
            # higher score for matching more fields
            payload = {
              bool: {
                should: queries.map { |qs| {dis_max: {queries: qs}} }
              }
            }

            should.concat(set_conversions)
          end

          query = payload
        end

        payload = {}

        # type when inheritance
        where = ensure_permitted(options[:where] || {}).dup
        if searchkick_options[:inheritance] && (options[:type] || (klass != searchkick_klass && searchkick_index))
          where[:type] = [options[:type] || klass].flatten.map { |v| searchkick_index.klass_document_type(v, true) }
        end

        models = Array(options[:models])
        if models.any? { |m| m != m.searchkick_klass }
          # aliases are not supported with _index in ES below 7.5
          # see https://github.com/elastic/elasticsearch/pull/46640
          if below75?
            Searchkick.warn("Passing child models to models option throws off hits and pagination - use type option instead")
          else
            index_type_or =
              models.map do |m|
                v = {_index: m.searchkick_index.name}
                v[:type] = m.searchkick_index.klass_document_type(m, true) if m != m.searchkick_klass
                v
              end

            where[:or] = Array(where[:or]) + [index_type_or]
          end
        end

        # start everything as efficient filters
        # move to post_filters as aggs demand
        filters = where_filters(where)
        post_filters = []

        # aggregations
        set_aggregations(payload, filters, post_filters) if options[:aggs]

        # post filters
        set_post_filters(payload, post_filters) if post_filters.any?

        custom_filters = []
        multiply_filters = []

        set_boost_by(multiply_filters, custom_filters)
        set_boost_where(custom_filters)
        set_boost_by_distance(custom_filters) if options[:boost_by_distance]
        set_boost_by_recency(custom_filters) if options[:boost_by_recency]

        payload[:query] = build_query(query, filters, should, must_not, custom_filters, multiply_filters)

        payload[:explain] = options[:explain] if options[:explain]
        payload[:profile] = options[:profile] if options[:profile]

        # order
        set_order(payload) if options[:order]

        # indices_boost
        set_boost_by_indices(payload)

        # suggestions
        set_suggestions(payload, options[:suggest]) if options[:suggest]

        # highlight
        set_highlights(payload, fields) if options[:highlight]

        # timeout shortly after client times out
        payload[:timeout] ||= "#{((Searchkick.search_timeout + 1) * 1000).round}ms"

        # An empty array will cause only the _id and _type for each hit to be returned
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-source-filtering.html
        if options[:select]
          if options[:select] == []
            # intuitively [] makes sense to return no fields, but ES by default returns all fields
            payload[:_source] = false
          else
            payload[:_source] = options[:select]
          end
        elsif load
          payload[:_source] = false
        end
      end

      # knn
      set_knn(payload, options[:knn], per_page, offset) if options[:knn]

      # pagination
      pagination_options = options[:page] || options[:limit] || options[:per_page] || options[:offset] || options[:padding]
      if !options[:body] || pagination_options
        payload[:size] = per_page
        payload[:from] = offset if offset > 0
      end

      # type
      if !searchkick_options[:inheritance] && (options[:type] || (klass != searchkick_klass && searchkick_index))
        @type = [options[:type] || klass].flatten.map { |v| searchkick_index.klass_document_type(v) }
      end

      # routing
      @routing = options[:routing] if options[:routing]

      if track_total_hits?
        payload[:track_total_hits] = true
      end

      # merge more body options
      payload = payload.deep_merge(options[:body_options]) if options[:body_options]

      # run block
      options[:block].call(payload) if options[:block]

      # scroll optimization when interating over all docs
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-scroll.html
      if options[:scroll] && payload[:query] == {match_all: {}}
        payload[:sort] ||= ["_doc"]
      end

      @body = payload
      @page = page
      @per_page = original_per_page
      @padding = padding
      @load = load
      @scroll = scroll
    end

    def set_fields
      boost_fields = {}
      fields = options[:fields] || searchkick_options[:default_fields] || searchkick_options[:searchable]
      all = searchkick_options.key?(:_all) ? searchkick_options[:_all] : false
      default_match = options[:match] || searchkick_options[:match] || :word
      fields =
        if fields
          fields.map do |value|
            k, v = value.is_a?(Hash) ? value.to_a.first : [value, default_match]
            k2, boost = k.to_s.split("^", 2)
            field = "#{k2}.#{v == :word ? 'analyzed' : v}"
            boost_fields[field] = boost.to_f if boost
            field
          end
        elsif all && default_match == :word
          ["_all"]
        elsif all && default_match == :phrase
          ["_all.phrase"]
        elsif term != "*" && default_match == :exact
          raise ArgumentError, "Must specify fields to search"
        else
          [default_match == :word ? "*.analyzed" : "*.#{default_match}"]
        end
      [boost_fields, fields]
    end

    def build_query(query, filters, should, must_not, custom_filters, multiply_filters)
      if filters.any? || must_not.any? || should.any?
        bool = {}
        bool[:must] = query if query
        bool[:filter] = filters if filters.any?      # where
        bool[:must_not] = must_not if must_not.any?  # exclude
        bool[:should] = should if should.any?        # conversions
        query = {bool: bool}
      end

      if custom_filters.any?
        query = {
          function_score: {
            functions: custom_filters,
            query: query,
            score_mode: "sum"
          }
        }
      end

      if multiply_filters.any?
        query = {
          function_score: {
            functions: multiply_filters,
            query: query,
            score_mode: "multiply"
          }
        }
      end

      query
    end

    def set_conversions
      conversions_fields = Array(options[:conversions] || searchkick_options[:conversions]).map(&:to_s)
      if conversions_fields.present? && options[:conversions] != false
        conversions_fields.map do |conversions_field|
          {
            nested: {
              path: conversions_field,
              score_mode: "sum",
              query: {
                function_score: {
                  boost_mode: "replace",
                  query: {
                    match: {
                      "#{conversions_field}.query" => options[:conversions_term] || term
                    }
                  },
                  field_value_factor: {
                    field: "#{conversions_field}.count"
                  }
                }
              }
            }
          }
        end
      else
        []
      end
    end

    def set_exclude(field, analyzer)
      Array(options[:exclude]).map do |phrase|
        {
          multi_match: {
            fields: [field],
            query: phrase,
            analyzer: analyzer,
            type: "phrase"
          }
        }
      end
    end

    def set_boost_by_distance(custom_filters)
      boost_by_distance = options[:boost_by_distance] || {}

      # legacy format
      if boost_by_distance[:field]
        boost_by_distance = {boost_by_distance[:field] => boost_by_distance.except(:field)}
      end

      boost_by_distance.each do |field, attributes|
        attributes = {function: :gauss, scale: "5mi"}.merge(attributes)
        unless attributes[:origin]
          raise ArgumentError, "boost_by_distance requires :origin"
        end

        function_params = attributes.except(:factor, :function)
        function_params[:origin] = location_value(function_params[:origin])
        custom_filters << {
          weight: attributes[:factor] || 1,
          attributes[:function] => {
            field => function_params
          }
        }
      end
    end

    def set_boost_by_recency(custom_filters)
      options[:boost_by_recency].each do |field, attributes|
        attributes = {function: :gauss, origin: Time.now}.merge(attributes)

        custom_filters << {
          weight: attributes[:factor] || 1,
          attributes[:function] => {
            field => attributes.except(:factor, :function)
          }
        }
      end
    end

    def set_boost_by(multiply_filters, custom_filters)
      boost_by = options[:boost_by] || {}
      if boost_by.is_a?(Array)
        boost_by = boost_by.to_h { |f| [f, {factor: 1}] }
      elsif boost_by.is_a?(Hash)
        multiply_by, boost_by = boost_by.partition { |_, v| v.delete(:boost_mode) == "multiply" }.map(&:to_h)
      end
      boost_by[options[:boost]] = {factor: 1} if options[:boost]

      custom_filters.concat boost_filters(boost_by, modifier: "ln2p")
      multiply_filters.concat boost_filters(multiply_by || {})
    end

    def set_boost_where(custom_filters)
      boost_where = options[:boost_where] || {}
      boost_where.each do |field, value|
        if value.is_a?(Array) && value.first.is_a?(Hash)
          value.each do |value_factor|
            custom_filters << custom_filter(field, value_factor[:value], value_factor[:factor])
          end
        elsif value.is_a?(Hash)
          custom_filters << custom_filter(field, value[:value], value[:factor])
        else
          factor = 1000
          custom_filters << custom_filter(field, value, factor)
        end
      end
    end

    def set_boost_by_indices(payload)
      return unless options[:indices_boost]

      indices_boost = options[:indices_boost].map do |key, boost|
        index = key.respond_to?(:searchkick_index) ? key.searchkick_index.name : key
        {index => boost}
      end

      payload[:indices_boost] = indices_boost
    end

    def set_suggestions(payload, suggest)
      suggest_fields = nil

      if suggest.is_a?(Array)
        suggest_fields = suggest
      else
        suggest_fields = (searchkick_options[:suggest] || []).map(&:to_s)

        # intersection
        if options[:fields]
          suggest_fields &= options[:fields].map { |v| (v.is_a?(Hash) ? v.keys.first : v).to_s.split("^", 2).first }
        end
      end

      if suggest_fields.any?
        payload[:suggest] = {text: term}
        suggest_fields.each do |field|
          payload[:suggest][field] = {
            phrase: {
              field: "#{field}.suggest"
            }
          }
        end
      else
        raise ArgumentError, "Must pass fields to suggest option"
      end
    end

    def set_highlights(payload, fields)
      payload[:highlight] = {
        fields: fields.to_h { |f| [f, {}] },
        fragment_size: 0
      }

      if options[:highlight].is_a?(Hash)
        if (tag = options[:highlight][:tag])
          payload[:highlight][:pre_tags] = [tag]
          payload[:highlight][:post_tags] = [tag.to_s.gsub(/\A<(\w+).+/, "</\\1>")]
        end

        if (fragment_size = options[:highlight][:fragment_size])
          payload[:highlight][:fragment_size] = fragment_size
        end
        if (encoder = options[:highlight][:encoder])
          payload[:highlight][:encoder] = encoder
        end

        highlight_fields = options[:highlight][:fields]
        if highlight_fields
          payload[:highlight][:fields] = {}

          highlight_fields.each do |name, opts|
            payload[:highlight][:fields]["#{name}.#{@match_suffix}"] = opts || {}
          end
        end
      end

      @highlighted_fields = payload[:highlight][:fields].keys
    end

    def set_aggregations(payload, filters, post_filters)
      aggs = options[:aggs]
      payload[:aggs] = {}

      aggs = aggs.to_h { |f| [f, {}] } if aggs.is_a?(Array) # convert to more advanced syntax
      aggs.each do |field, agg_options|
        size = agg_options[:limit] ? agg_options[:limit] : 1_000
        shared_agg_options = agg_options.except(:limit, :field, :ranges, :date_ranges, :where)

        if agg_options[:ranges]
          payload[:aggs][field] = {
            range: {
              field: agg_options[:field] || field,
              ranges: agg_options[:ranges]
            }.merge(shared_agg_options)
          }
        elsif agg_options[:date_ranges]
          payload[:aggs][field] = {
            date_range: {
              field: agg_options[:field] || field,
              ranges: agg_options[:date_ranges]
            }.merge(shared_agg_options)
          }
        elsif (histogram = agg_options[:date_histogram])
          payload[:aggs][field] = {
            date_histogram: histogram
          }.merge(shared_agg_options)
        elsif (metric = @@metric_aggs.find { |k| agg_options.has_key?(k) })
          payload[:aggs][field] = {
            metric => {
              field: agg_options[metric][:field] || field
            }
          }.merge(shared_agg_options)
        else
          payload[:aggs][field] = {
            terms: {
              field: agg_options[:field] || field,
              size: size
            }.merge(shared_agg_options)
          }
        end

        where = {}
        where = ensure_permitted(options[:where] || {}).reject { |k| k == field } unless options[:smart_aggs] == false
        agg_where = ensure_permitted(agg_options[:where] || {})
        agg_filters = where_filters(where.merge(agg_where))

        # only do one level comparison for simplicity
        filters.select! do |filter|
          if agg_filters.include?(filter)
            true
          else
            post_filters << filter
            false
          end
        end

        if agg_filters.any?
          payload[:aggs][field] = {
            filter: {
              bool: {
                must: agg_filters
              }
            },
            aggs: {
              field => payload[:aggs][field]
            }
          }
        end
      end
    end

    def set_knn(payload, knn, per_page, offset)
      if term != "*"
        raise ArgumentError, "Use Searchkick.multi_search for hybrid search"
      end

      field = knn[:field]
      field_options = searchkick_options.dig(:knn, field.to_sym) || searchkick_options.dig(:knn, field.to_s) || {}
      vector = knn[:vector]
      distance = knn[:distance] || field_options[:distance]
      exact = knn[:exact]
      exact = field_options[:distance].nil? || distance != field_options[:distance] if exact.nil?
      k = per_page + offset
      ef_search = knn[:ef_search]
      filter = payload.delete(:query)

      if distance.nil?
        raise ArgumentError, "distance required"
      elsif !exact && distance != field_options[:distance]
        raise ArgumentError, "distance must match searchkick options for approximate search"
      end

      if Searchkick.opensearch?
        if exact
          # https://opensearch.org/docs/latest/search-plugins/knn/knn-score-script/#spaces
          space_type =
            case distance
            when "cosine"
              "cosinesimil"
            when "euclidean"
              "l2"
            when "taxicab"
              "l1"
            when "inner_product"
              "innerproduct"
            when "chebyshev"
              "linf"
            else
              raise ArgumentError, "Unknown distance: #{distance}"
            end

          payload[:query] = {
            script_score: {
              query: {
                bool: {
                  must: [filter, {exists: {field: field}}]
                }
              },
              script: {
                source: "knn_score",
                lang: "knn",
                params: {
                  field: field,
                  query_value: vector,
                  space_type: space_type
                }
              },
              boost: distance == "cosine" && Searchkick.server_below?("2.19.0", true) ? 0.5 : 1.0
            }
          }
        else
          if ef_search && Searchkick.server_below?("2.16.0", true)
            raise Error, "ef_search requires OpenSearch 2.16+"
          end

          payload[:query] = {
            knn: {
              field.to_sym => {
                vector: vector,
                k: k,
                filter: filter
              }.merge(ef_search ? {method_parameters: {ef_search: ef_search}} : {})
            }
          }
        end
      else
        if exact
          # prevent incorrect distances/results with Elasticsearch 9.0.0-rc1
          if !below90? && field_options[:distance] == "cosine" && distance != "cosine"
            raise ArgumentError, "distance must match searchkick options"
          end

          # https://github.com/elastic/elasticsearch/blob/main/docs/reference/vectors/vector-functions.asciidoc
          source =
            case distance
            when "cosine"
              "(cosineSimilarity(params.query_vector, params.field) + 1.0) * 0.5"
            when "euclidean"
              "double l2 = l2norm(params.query_vector, params.field); 1 / (1 + l2 * l2)"
            when "taxicab"
              "1 / (1 + l1norm(params.query_vector, params.field))"
            when "inner_product"
              "double dot = dotProduct(params.query_vector, params.field); dot > 0 ? dot + 1 : 1 / (1 - dot)"
            else
              raise ArgumentError, "Unknown distance: #{distance}"
            end

          payload[:query] = {
            script_score: {
              query: {
                bool: {
                  must: [filter, {exists: {field: field}}]
                }
              },
              script: {
                source: source,
                params: {
                  field: field,
                  query_vector: vector
                }
              }
            }
          }
        else
          payload[:knn] = {
            field: field,
            query_vector: vector,
            k: k,
            filter: filter
          }.merge(ef_search ? {num_candidates: ef_search} : {})
        end
      end
    end

    def set_post_filters(payload, post_filters)
      payload[:post_filter] = {
        bool: {
          filter: post_filters
        }
      }
    end

    def set_order(payload)
      value = options[:order]
      payload[:sort] = value.is_a?(Enumerable) ? value : {value => :asc}
    end

    # provides *very* basic protection from unfiltered parameters
    # this is not meant to be comprehensive and may be expanded in the future
    def ensure_permitted(obj)
      obj.to_h
    end

    def where_filters(where)
      filters = []
      (where || {}).each do |field, value|
        field = :_id if field.to_s == "id"

        if field == :or
          value.each do |or_clause|
            filters << {bool: {should: or_clause.map { |or_statement| {bool: {filter: where_filters(or_statement)}} }}}
          end
        elsif field == :_or
          filters << {bool: {should: value.map { |or_statement| {bool: {filter: where_filters(or_statement)}} }}}
        elsif field == :_not
          filters << {bool: {must_not: where_filters(value)}}
        elsif field == :_and
          filters << {bool: {must: value.map { |or_statement| {bool: {filter: where_filters(or_statement)}} }}}
        elsif field == :_script
          unless value.is_a?(Script)
            raise TypeError, "expected Searchkick::Script"
          end

          filters << {script: {script: {source: value.source, lang: value.lang, params: value.params}}}
        else
          # expand ranges
          if value.is_a?(Range)
            value = expand_range(value)
          end

          value = {in: value} if value.is_a?(Array)

          if value.is_a?(Hash)
            value.each do |op, op_value|
              case op
              when :within, :bottom_right, :bottom_left
                # do nothing
              when :near
                filters << {
                  geo_distance: {
                    field => location_value(op_value),
                    distance: value[:within] || "50mi"
                  }
                }
              when :geo_polygon
                filters << {
                  geo_polygon: {
                    field => op_value
                  }
                }
              when :geo_shape
                shape = op_value.except(:relation)
                shape[:coordinates] = coordinate_array(shape[:coordinates]) if shape[:coordinates]
                filters << {
                  geo_shape: {
                    field => {
                      relation: op_value[:relation] || "intersects",
                      shape: shape
                    }
                  }
                }
              when :top_left
                filters << {
                  geo_bounding_box: {
                    field => {
                      top_left: location_value(op_value),
                      bottom_right: location_value(value[:bottom_right])
                    }
                  }
                }
              when :top_right
                filters << {
                  geo_bounding_box: {
                    field => {
                      top_right: location_value(op_value),
                      bottom_left: location_value(value[:bottom_left])
                    }
                  }
                }
              when :like, :ilike
                # based on Postgres
                # https://www.postgresql.org/docs/current/functions-matching.html
                # % matches zero or more characters
                # _ matches one character
                # \ is escape character
                # escape Lucene reserved characters
                # https://www.elastic.co/guide/en/elasticsearch/reference/current/regexp-syntax.html#regexp-optional-operators
                reserved = %w(\\ . ? + * | { } [ ] ( ) ")
                regex = op_value.dup
                reserved.each do |v|
                  regex.gsub!(v, "\\\\" + v)
                end
                regex = regex.gsub(/(?<!\\)%/, ".*").gsub(/(?<!\\)_/, ".").gsub("\\%", "%").gsub("\\_", "_")

                if op == :ilike
                  if below710?
                    raise ArgumentError, "ilike requires Elasticsearch 7.10+"
                  else
                    filters << {regexp: {field => {value: regex, flags: "NONE", case_insensitive: true}}}
                  end
                else
                  filters << {regexp: {field => {value: regex, flags: "NONE"}}}
                end
              when :prefix
                filters << {prefix: {field => {value: op_value}}}
              when :regexp # support for regexp queries without using a regexp ruby object
                filters << {regexp: {field => {value: op_value}}}
              when :not, :_not # not equal
                filters << {bool: {must_not: term_filters(field, op_value)}}
              when :all
                op_value.each do |val|
                  filters << term_filters(field, val)
                end
              when :in
                filters << term_filters(field, op_value)
              when :exists
                # TODO add support for false in Searchkick 6
                if op_value != true
                  # TODO raise error in Searchkick 6
                  Searchkick.warn("Passing a value other than true to exists is not supported")
                end
                filters << {exists: {field: field}}
              else
                range_query =
                  case op
                  when :gt
                    # TODO always use gt in Searchkick 6
                    below90? ? {from: op_value, include_lower: false} : {gt: op_value}
                  when :gte
                    # TODO always use gte in Searchkick 6
                    below90? ? {from: op_value, include_lower: true} : {gte: op_value}
                  when :lt
                    # TODO always use lt in Searchkick 6
                    below90? ? {to: op_value, include_upper: false} : {lt: op_value}
                  when :lte
                    # TODO always use lte in Searchkick 6
                    below90? ? {to: op_value, include_upper: true} : {lte: op_value}
                  else
                    raise ArgumentError, "Unknown where operator: #{op.inspect}"
                  end
                # issue 132
                if (existing = filters.find { |f| f[:range] && f[:range][field] })
                  existing[:range][field].merge!(range_query)
                else
                  filters << {range: {field => range_query}}
                end
              end
            end
          else
            filters << term_filters(field, value)
          end
        end
      end
      filters
    end

    def term_filters(field, value)
      if value.is_a?(Array) # in query
        if value.any?(&:nil?)
          {bool: {should: [term_filters(field, nil), term_filters(field, value.compact)]}}
        else
          {terms: {field => value}}
        end
      elsif value.nil?
        {bool: {must_not: {exists: {field: field}}}}
      elsif value.is_a?(Regexp)
        source = value.source

        # TODO handle other regexp options

        # TODO handle other anchor characters, like ^, $, \Z
        if source.start_with?("\\A")
          source = source[2..-1]
        else
          source = ".*#{source}"
        end

        if source.end_with?("\\z")
          source = source[0..-3]
        else
          source = "#{source}.*"
        end

        if below710?
          if value.casefold?
            raise ArgumentError, "Case-insensitive flag does not work with Elasticsearch < 7.10"
          end
          {regexp: {field => {value: source, flags: "NONE"}}}
        else
          {regexp: {field => {value: source, flags: "NONE", case_insensitive: value.casefold?}}}
        end
      else
        # TODO add this for other values
        if value.as_json.is_a?(Enumerable)
          # query will fail, but this is better
          # same message as Active Record
          raise TypeError, "can't cast #{value.class.name}"
        end

        {term: {field => {value: value}}}
      end
    end

    def custom_filter(field, value, factor)
      {
        filter: where_filters(field => value),
        weight: factor
      }
    end

    def boost_filter(field, factor: 1, modifier: nil, missing: nil)
      script_score = {
        field_value_factor: {
          field: field,
          factor: factor.to_f,
          modifier: modifier
        }
      }

      if missing
        script_score[:field_value_factor][:missing] = missing.to_f
      else
        script_score[:filter] = {
          exists: {
            field: field
          }
        }
      end

      script_score
    end

    def boost_filters(boost_by, modifier: nil)
      boost_by.map do |field, value|
        boost_filter(field, modifier: modifier, **value)
      end
    end

    # Recursively descend through nesting of arrays until we reach either a lat/lon object or an array of numbers,
    # eventually returning the same structure with all values transformed to [lon, lat].
    #
    def coordinate_array(value)
      if value.is_a?(Hash)
        [value[:lon], value[:lat]]
      elsif value.is_a?(Array) and !value[0].is_a?(Numeric)
        value.map { |a| coordinate_array(a) }
      else
        value
      end
    end

    def location_value(value)
      if value.is_a?(Array)
        value.map(&:to_f).reverse
      else
        value
      end
    end

    def expand_range(range)
      expanded = {}
      expanded[:gte] = range.begin if range.begin

      if range.end && !(range.end.respond_to?(:infinite?) && range.end.infinite?)
        expanded[range.exclude_end? ? :lt : :lte] = range.end
      end

      expanded
    end

    def base_field(k)
      k.sub(/\.(analyzed|word_start|word_middle|word_end|text_start|text_middle|text_end|exact)\z/, "")
    end

    def track_total_hits?
      searchkick_options[:deep_paging] || body_options[:track_total_hits]
    end

    def body_options
      options[:body_options] || {}
    end

    def below73?
      Searchkick.server_below?("7.3.0")
    end

    def below75?
      Searchkick.server_below?("7.5.0")
    end

    def below710?
      Searchkick.server_below?("7.10.0")
    end

    def below80?
      Searchkick.server_below?("8.0.0")
    end

    def below90?
      Searchkick.server_below?("9.0.0")
    end
  end
end
