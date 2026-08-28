class DataImports::PlaceholderInboxBuilder
  AGENT_REPLY_TIME_WINDOW_HOURS = 1

  def initialize(account:, provider:, source_bucket:)
    @account = account
    @provider = provider
    @source_bucket = source_bucket
  end

  def inbox_for(source_type)
    bucket = @source_bucket.for(source_type)
    placeholder_inboxes[bucket[:key]] ||= create_placeholder_inbox(bucket)
  end

  private

  def placeholder_inboxes
    @placeholder_inboxes ||= @account.inboxes.includes(:channel).where(channel_type: 'Channel::Api').each_with_object({}) do |inbox, inboxes|
      attrs = inbox.channel.additional_attributes || {}
      next unless attrs['source_provider'] == @provider && attrs['import_placeholder'] == true

      inboxes[attrs['source_bucket']] = inbox
    end
  end

  def create_placeholder_inbox(bucket)
    Inbox.transaction do
      channel = create_placeholder_channel(bucket)
      now = Time.current
      result = Inbox.insert_all!( # rubocop:disable Rails/SkipsModelValidations
        [placeholder_inbox_attributes(channel, bucket, now)],
        returning: %w[id]
      )
      Inbox.find(result.rows.first.first).tap { |inbox| create_default_working_hours(inbox) }
    end
  end

  def create_placeholder_channel(bucket)
    @account.api_channels.create!(
      additional_attributes: {
        source_provider: @provider,
        source_bucket: bucket[:key],
        import_placeholder: true,
        agent_reply_time_window: AGENT_REPLY_TIME_WINDOW_HOURS
      }
    )
  end

  def placeholder_inbox_attributes(channel, bucket, timestamp)
    {
      account_id: @account.id,
      channel_id: channel.id,
      channel_type: channel.class.name,
      name: "#{@provider.titleize} Import - #{bucket[:name]}",
      enable_auto_assignment: false,
      allow_messages_after_resolved: false,
      created_at: timestamp,
      updated_at: timestamp
    }
  end

  def create_default_working_hours(inbox)
    OutOfOffisable::DEFAULT_WORKING_HOURS.each { |attributes| inbox.working_hours.create!(attributes) }
  end
end
