# frozen_string_literal: true

module MetaRequest
  class AppNotifications
    # these are the specific keys in the cache payload that we display in the
    # panel view
    CACHE_KEY_COLUMNS = %i[key hit options type].freeze

    # define this here so we can pass it in to all of our cache subscribe calls
    CACHE_BLOCK = proc { |*args|
      name, start, ending, transaction_id, payload = args

      # from http://edgeguides.rubyonrails.org/active_support_instrumentation.html#cache-fetch-hit-active-support
      #
      # :super_operation  :fetch is added when a read is used with #fetch
      #
      # so if :super_operation is present, we'll use it for the type. otherwise
      # strip (say) 'cache_delete.active_support' down to 'delete'
      payload[:type] = payload.delete(:super_operation) || name.sub(/cache_(.*?)\..*$/, '\1')

      # anything that isn't in CACHE_KEY_COLUMNS gets shoved into :options
      # instead
      payload[:options] = {}
      payload.keys.each do |k|
        payload[:options][k] = payload.delete(k) unless k.in? CACHE_KEY_COLUMNS
      end

      callsite = Utils.dev_callsite(caller)
      payload.merge!(callsite) if callsite

      Event.new(name, start, ending, transaction_id, payload)
    }

    # sql processing block - used for sql.active_record and sql.sequel

    # HACK: we hardcode the event name to 'sql.active_record' so that the ui will
    # display sequel events without modification. otherwise the ui would need to
    # be modified to support a sequel tab (or to change the display name on the
    # active_record tab when necessary - which maybe makes more sense?)
    SQL_EVENT_NAME = 'sql.active_record'

    SQL_BLOCK = proc { |*args|
      _name, start, ending, transaction_id, payload = args
      callsite = Utils.dev_callsite(caller)
      payload.merge!(callsite) if callsite

      Event.new(SQL_EVENT_NAME, start, ending, transaction_id, payload)
    }

    VIEW_BLOCK = proc { |*args|
      name, start, ending, transaction_id, payload = args
      payload[:identifier] = MetaRequest::Utils.sub_source_path(payload[:identifier])

      Event.new(name, start, ending, transaction_id, payload)
    }

    # Subscribe to all events relevant to RailsPanel
    #
    def self.subscribe
      new
        .subscribe('meta_request.log')
        .subscribe('sql.active_record', &SQL_BLOCK)
        .subscribe('sql.sequel', &SQL_BLOCK)
        .subscribe('render_partial.action_view', &VIEW_BLOCK)
        .subscribe('render_template.action_view', &VIEW_BLOCK)
        .subscribe('process_action.action_controller.exception')
        .subscribe('process_action.action_controller') do |*args|
          name, start, ending, transaction_id, payload = args
          payload[:status] = '500' if payload[:exception]
          Event.new(name, start, ending, transaction_id, payload)
        end
        .subscribe('cache_read.active_support', &CACHE_BLOCK)
        .subscribe('cache_generate.active_support', &CACHE_BLOCK)
        .subscribe('cache_fetch_hit.active_support', &CACHE_BLOCK)
        .subscribe('cache_write.active_support', &CACHE_BLOCK)
        .subscribe('cache_delete.active_support', &CACHE_BLOCK)
        .subscribe('cache_exist?.active_support', &CACHE_BLOCK)
    end

    def subscribe(event_name)
      ActiveSupport::Notifications.subscribe(event_name) do |*args|
        event = block_given? ? yield(*args) : Event.new(*args)
        AppRequest.current.events << event if AppRequest.current
      end
      self
    end
  end
end
