# frozen_string_literal: true

require "uri"
require "set"
require "yaml"
require "cgi"

module Sidekiq
  # These methods are available to pages within the Web UI and UI extensions.
  # They are not public APIs for applications to use.
  module WebHelpers
    def style_tag(location, **kwargs)
      global = location.match?(/:\/\//)
      location = root_path + location if !global && !location.start_with?(root_path)
      attrs = {
        type: "text/css",
        media: "screen",
        rel: "stylesheet",
        nonce: csp_nonce,
        href: location
      }
      html_tag(:link, attrs.merge(kwargs))
    end

    def script_tag(location, **kwargs)
      global = location.match?(/:\/\//)
      location = root_path + location if !global && !location.start_with?(root_path)
      attrs = {
        type: "text/javascript",
        nonce: csp_nonce,
        src: location
      }
      html_tag(:script, attrs.merge(kwargs)) {}
    end

    # NB: keys and values are not escaped; do not allow user input
    # in the attributes
    private def html_tag(tagname, attrs)
      s = +"<#{tagname}"
      attrs.each_pair do |k, v|
        next unless v
        s << " #{k}=\"#{v}\""
      end
      if block_given?
        s << ">"
        yield s
        s << "</#{tagname}>"
      else
        s << " />"
      end
      s
    end

    def strings(lang)
      @strings ||= {}

      # Allow sidekiq-web extensions to add locale paths
      # so extensions can be localized
      @strings[lang] ||= settings.locales.each_with_object({}) do |path, global|
        find_locale_files(lang).each do |file|
          strs = YAML.safe_load(File.read(file))
          global.merge!(strs[lang])
        end
      end
    end

    def to_json(x)
      Sidekiq.dump_json(x)
    end

    def singularize(str, count)
      if count == 1 && str.respond_to?(:singularize) # rails
        str.singularize
      else
        str
      end
    end

    def clear_caches
      @strings = nil
      @locale_files = nil
      @available_locales = nil
    end

    def locale_files
      @locale_files ||= settings.locales.flat_map { |path|
        Dir["#{path}/*.yml"]
      }
    end

    def available_locales
      @available_locales ||= Set.new(locale_files.map { |path| File.basename(path, ".yml") })
    end

    def find_locale_files(lang)
      locale_files.select { |file| file =~ /\/#{lang}\.yml$/ }
    end

    def search(jobset, substr)
      resultset = jobset.scan(substr).to_a
      @current_page = 1
      @count = @total_size = resultset.size
      resultset
    end

    def filtering(which)
      erb(:filtering, locals: {which: which})
    end

    def filter_link(jid, within = "retries")
      if within.nil?
        ::Rack::Utils.escape_html(jid)
      else
        "<a href='#{root_path}filter/#{within}?substr=#{jid}'>#{::Rack::Utils.escape_html(jid)}</a>"
      end
    end

    def display_tags(job, within = "retries")
      job.tags.map { |tag|
        "<span class='label label-info jobtag'>#{filter_link(tag, within)}</span>"
      }.join(" ")
    end

    # This view helper provide ability display you html code in
    # to head of page. Example:
    #
    #   <% add_to_head do %>
    #     <link rel="stylesheet" .../>
    #     <meta .../>
    #   <% end %>
    #
    def add_to_head
      @head_html ||= []
      @head_html << yield.dup if block_given?
    end

    def display_custom_head
      @head_html.join if defined?(@head_html)
    end

    def text_direction
      get_locale["TextDirection"] || "ltr"
    end

    def rtl?
      text_direction == "rtl"
    end

    # See https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
    def user_preferred_languages
      languages = env["HTTP_ACCEPT_LANGUAGE"]
      languages.to_s.downcase.gsub(/\s+/, "").split(",").map { |language|
        locale, quality = language.split(";q=", 2)
        locale = nil if locale == "*" # Ignore wildcards
        quality = quality ? quality.to_f : 1.0
        [locale, quality]
      }.sort { |(_, left), (_, right)|
        right <=> left
      }.map(&:first).compact
    end

    # Given an Accept-Language header like "fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4,ru;q=0.2"
    # this method will try to best match the available locales to the user's preferred languages.
    #
    # Inspiration taken from https://github.com/iain/http_accept_language/blob/master/lib/http_accept_language/parser.rb
    def locale
      # session[:locale] is set via the locale selector from the footer
      @locale ||= if (l = session&.fetch(:locale, nil)) && available_locales.include?(l)
        l
      else
        matched_locale = user_preferred_languages.map { |preferred|
          preferred_language = preferred.split("-", 2).first

          lang_group = available_locales.select { |available|
            preferred_language == available.split("-", 2).first
          }

          lang_group.find { |lang| lang == preferred } || lang_group.min_by(&:length)
        }.compact.first

        matched_locale || "en"
      end
    end

    # sidekiq/sidekiq#3243
    def unfiltered?
      yield unless env["PATH_INFO"].start_with?("/filter/")
    end

    def get_locale
      strings(locale)
    end

    def t(msg, options = {})
      string = get_locale[msg] || strings("en")[msg] || msg
      if options.empty?
        string
      else
        string % options
      end
    end

    def sort_direction_label
      (params[:direction] == "asc") ? "&uarr;" : "&darr;"
    end

    def workset
      @work ||= Sidekiq::WorkSet.new
    end

    def processes
      @processes ||= Sidekiq::ProcessSet.new
    end

    # Sorts processes by hostname following the natural sort order
    def sorted_processes
      @sorted_processes ||= begin
        return processes unless processes.all? { |p| p["hostname"] }

        processes.to_a.sort_by do |process|
          # Kudos to `shurikk` on StackOverflow
          # https://stackoverflow.com/a/15170063/575547
          process["hostname"].split(/(\d+)/).map { |a| /\d+/.match?(a) ? a.to_i : a }
        end
      end
    end

    def busy_weights(capsule_weights)
      # backwards compat with 7.0.0, remove in 7.1
      cw = [capsule_weights].flatten
      cw.map { |hash|
        hash.map { |name, weight| (weight > 0) ? +name << ": " << weight.to_s : name }.join(", ")
      }.join("; ")
    end

    def stats
      @stats ||= Sidekiq::Stats.new
    end

    def redis_url
      Sidekiq.redis do |conn|
        conn.config.server_url
      end
    end

    def redis_info
      Sidekiq.default_configuration.redis_info
    end

    def root_path
      "#{env["SCRIPT_NAME"]}/"
    end

    def current_path
      @current_path ||= request.path_info.gsub(/^\//, "")
    end

    def current_status
      (workset.size == 0) ? "idle" : "active"
    end

    def relative_time(time)
      stamp = time.getutc.iso8601
      %(<time class="ltr" dir="ltr" title="#{stamp}" datetime="#{stamp}">#{time}</time>)
    end

    def job_params(job, score)
      "#{score}-#{job["jid"]}"
    end

    def parse_params(params)
      score, jid = params.split("-", 2)
      [score.to_f, jid]
    end

    SAFE_QPARAMS = %w[page direction]

    # Merge options with current params, filter safe params, and stringify to query string
    def qparams(options)
      stringified_options = options.transform_keys(&:to_s)

      to_query_string(params.merge(stringified_options))
    end

    def to_query_string(params)
      params.map { |key, value|
        SAFE_QPARAMS.include?(key) ? "#{key}=#{CGI.escape(value.to_s)}" : next
      }.compact.join("&")
    end

    def truncate(text, truncate_after_chars = 2000)
      (truncate_after_chars && text.size > truncate_after_chars) ? "#{text[0..truncate_after_chars]}..." : text
    end

    def display_args(args, truncate_after_chars = 2000)
      return "Invalid job payload, args is nil" if args.nil?
      return "Invalid job payload, args must be an Array, not #{args.class.name}" unless args.is_a?(Array)

      begin
        args.map { |arg|
          h(truncate(to_display(arg), truncate_after_chars))
        }.join(", ")
      rescue
        "Illegal job arguments: #{h args.inspect}"
      end
    end

    def csrf_tag
      "<input type='hidden' name='authenticity_token' value='#{env[:csrf_token]}'/>"
    end

    def csp_nonce
      env[:csp_nonce]
    end

    def to_display(arg)
      arg.inspect
    rescue
      begin
        arg.to_s
      rescue => ex
        "Cannot display argument: [#{ex.class.name}] #{ex.message}"
      end
    end

    RETRY_JOB_KEYS = Set.new(%w[
      queue class args retry_count retried_at failed_at
      jid error_message error_class backtrace
      error_backtrace enqueued_at retry wrapped
      created_at tags display_class
    ])

    def retry_extra_items(retry_job)
      @retry_extra_items ||= {}.tap do |extra|
        retry_job.item.each do |key, value|
          extra[key] = value unless RETRY_JOB_KEYS.include?(key)
        end
      end
    end

    def format_memory(rss_kb)
      return "0" if rss_kb.nil? || rss_kb == 0

      if rss_kb < 100_000
        "#{number_with_delimiter(rss_kb)} KB"
      elsif rss_kb < 10_000_000
        "#{number_with_delimiter((rss_kb / 1024.0).to_i)} MB"
      else
        "#{number_with_delimiter((rss_kb / (1024.0 * 1024.0)), precision: 1)} GB"
      end
    end

    def number_with_delimiter(number, options = {})
      precision = options[:precision] || 0
      %(<span data-nwp="#{precision}">#{number.round(precision)}</span>)
    end

    def h(text)
      ::Rack::Utils.escape_html(text.to_s)
    rescue ArgumentError => e
      raise unless e.message.eql?("invalid byte sequence in UTF-8")
      text.encode!("UTF-16", "UTF-8", invalid: :replace, replace: "").encode!("UTF-8", "UTF-16")
      retry
    end

    # Any paginated list that performs an action needs to redirect
    # back to the proper page after performing that action.
    def redirect_with_query(url)
      r = request.referer
      if r && r =~ /\?/
        ref = URI(r)
        redirect("#{url}?#{ref.query}")
      else
        redirect url
      end
    end

    def environment_title_prefix
      environment = Sidekiq.default_configuration[:environment] || ENV["APP_ENV"] || ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"

      "[#{environment.upcase}] " unless environment == "production"
    end

    def product_version
      "Sidekiq v#{Sidekiq::VERSION}"
    end

    def server_utc_time
      Time.now.utc.strftime("%H:%M:%S UTC")
    end

    def pollable?
      # there's no point to refreshing the metrics pages every N seconds
      !(current_path == "" || current_path.index("metrics"))
    end

    def retry_or_delete_or_kill(job, params)
      if params["retry"]
        job.retry
      elsif params["delete"]
        job.delete
      elsif params["kill"]
        job.kill
      end
    end

    def delete_or_add_queue(job, params)
      if params["delete"]
        job.delete
      elsif params["add_to_queue"]
        job.add_to_queue
      end
    end
  end
end
