# frozen_string_literal: true

require "active_record"

module Audited
  class << self
    attr_accessor \
      :auditing_enabled,
      :current_user_method,
      :ignored_attributes,
      :max_audits,
      :store_synthesized_enums
    attr_writer :audit_class

    def audit_class
      # The audit_class is set as String in the initializer. It can not be constantized during initialization and must
      # be constantized at runtime. See https://github.com/collectiveidea/audited/issues/608
      @audit_class = @audit_class.safe_constantize if @audit_class.is_a?(String)
      @audit_class ||= Audited::Audit
    end

    # remove audit_model in next major version it was only shortly present in 5.1.0
    alias_method :audit_model, :audit_class
    deprecate audit_model: "use Audited.audit_class instead of Audited.audit_model. This method will be removed.",
              deprecator: ActiveSupport::Deprecation.new('6.0.0', 'Audited')

    def store
      Audited::RequestStore.audited_store ||= {}
    end

    def config
      yield(self)
    end
  end

  @ignored_attributes = %w[lock_version created_at updated_at created_on updated_on]

  @current_user_method = :current_user
  @auditing_enabled = true
  @store_synthesized_enums = false
end

require "audited/auditor"
require "audited/request_store"

ActiveSupport.on_load :active_record do
  require "audited/audit"
  include Audited::Auditor
end

require "audited/sweeper"
require "audited/railtie" if Audited.const_defined?(:Rails)
