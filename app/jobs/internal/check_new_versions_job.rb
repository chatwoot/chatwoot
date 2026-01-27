class Internal::CheckNewVersionsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    return unless Rails.env.production?
    return unless should_run_check?

    add_jitter

    @instance_info = ChatwootHub.sync_with_hub
    update_version_info
  end

  private

  def should_run_check?
    current_hour = Time.current.utc.hour
    last_check = ::Redis::Alfred.get(last_check_key)
    today = Date.current.to_s

    if current_hour == designated_hour && last_check != today
      ::Redis::Alfred.set(last_check_key, today)
      return true
    end

    false
  end

  def designated_hour
    @designated_hour ||= Digest::MD5.hexdigest(ChatwootHub.installation_identifier).hex % 24
  end

  def last_check_key
    'internal::last_version_check_date'
  end

  def add_jitter
    jitter_seconds = rand(0..30)
    sleep(jitter_seconds)
  end

  def update_version_info
    return if @instance_info['version'].blank?

    ::Redis::Alfred.set(::Redis::Alfred::LATEST_CHATWOOT_VERSION, @instance_info['version'])
  end
end

Internal::CheckNewVersionsJob.prepend_mod_with('Internal::CheckNewVersionsJob')
