# frozen_string_literal: true

require 'action_cable/subscription_adapter/redis'

ActionCable::SubscriptionAdapter::Redis.redis_connector = lambda do |config|
  # For supporting GCP Memorystore where `client` command is disabled.
  # You can configure the following ENV variable to get your installation working.
  # ref:
  # https://github.com/mperham/sidekiq/issues/3518#issuecomment-595611673
  # https://github.com/redis/redis-rb/issues/767
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75173
  # https://github.com/rails/rails/blob/4a23cb3415eac03d76623112576559a722d1f23d/actioncable/lib/action_cable/subscription_adapter/base.rb#L30
  config[:id] = nil if ENV['REDIS_DISABLE_CLIENT_COMMAND'].present?
  Redis.new(config.except(:adapter, :channel_prefix))
end
