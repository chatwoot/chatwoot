class DataImports::Intercom::PlaceholderInboxBuilder
  AGENT_REPLY_TIME_WINDOW_HOURS = 1

  def initialize(account:)
    @account = account
  end

  def inbox_for(source_type)
    bucket = DataImports::Intercom::SourceBucket.for(source_type)
    placeholder_inboxes[bucket[:key]] ||= create_placeholder_inbox(bucket)
  end

  private

  def placeholder_inboxes
    @placeholder_inboxes ||= @account.inboxes.includes(:channel).where(channel_type: 'Channel::Api').each_with_object({}) do |inbox, inboxes|
      attrs = inbox.channel.additional_attributes || {}
      next unless attrs['source_provider'] == 'intercom' && attrs['import_placeholder'] == true

      inboxes[attrs['source_bucket']] = inbox
    end
  end

  def create_placeholder_inbox(bucket)
    channel = @account.api_channels.create!(
      additional_attributes: {
        source_provider: 'intercom',
        source_bucket: bucket[:key],
        import_placeholder: true,
        agent_reply_time_window: AGENT_REPLY_TIME_WINDOW_HOURS
      }
    )

    @account.inboxes.create!(
      name: "Intercom Import - #{bucket[:name]}",
      channel: channel,
      enable_auto_assignment: false,
      allow_messages_after_resolved: false
    )
  end
end
