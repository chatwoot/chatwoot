module ReadReplicaRoutable
  extend ActiveSupport::Concern

  included do
    class_attribute :read_replica_action_config, instance_writer: false, default: {}
  end

  class_methods do
    def reads_from_replica(*actions, max_lag:, access_context: false)
      action_config = actions.index_with { { max_lag: max_lag.to_f, access_context: access_context } }
      self.read_replica_action_config = read_replica_action_config.merge(action_config)

      before_action :prepare_read_replica_access_context, only: actions if access_context
      around_action :route_read_from_replica, only: actions
    end
  end

  private

  def prepare_read_replica_access_context
    @read_replica_access_context = ReadReplica::AccessContext.build(
      account: Current.account,
      user: Current.user,
      account_user: Current.account_user,
      params: params
    )
  end

  def route_read_from_replica(&action)
    config = read_replica_action_config.fetch(action_name.to_sym)
    selection = ReadReplica::Selector.new(actor_key: read_replica_actor_key, max_lag: config[:max_lag]).select
    execution = if selection.reader?
                  proc { ApplicationRecord.connected_to(role: :reading, prevent_writes: true, &action) }
                else
                  action
                end

    ReadReplica::Instrumentation.instrument(controller: controller_path, action: action_name, selection: selection, &execution)
  end

  def read_replica_routed_action?
    read_replica_action_config.key?(action_name.to_sym)
  end

  def read_replica_actor_key
    if Current.user && Current.account
      "account:#{Current.account.id}:user:#{Current.user.id}"
    elsif defined?(@contact_inbox) && @contact_inbox
      "contact-inbox:#{@contact_inbox.id}"
    end
  end
end
