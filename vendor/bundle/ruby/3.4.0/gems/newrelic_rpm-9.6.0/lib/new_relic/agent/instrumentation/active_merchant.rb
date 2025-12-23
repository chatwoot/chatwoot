# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

DependencyDetection.defer do
  @name = :active_merchant

  depends_on do
    defined?(ActiveMerchant) && defined?(ActiveMerchant::Billing) &&
      defined?(ActiveMerchant::Billing::Gateway) &&
      ActiveMerchant::Billing::Gateway.respond_to?(:implementations)
  end

  executes do
    NewRelic::Agent.logger.info('Installing ActiveMerchant instrumentation')
  end

  executes do
    class ActiveMerchant::Billing::Gateway
      include NewRelic::Agent::MethodTracer
    end

    ActiveMerchant::Billing::Gateway.implementations.each do |gateway|
      gateway.class_eval do
        implemented_methods = public_instance_methods(false).map(&:to_sym)
        gateway_name = self.name.split('::').last
        actions = [:authorize, :purchase, :credit, :void, :capture, :recurring, :store, :unstore, :update]
        actions.each do |operation|
          if implemented_methods.include?(operation)
            add_method_tracer operation, [->(*) { "ActiveMerchant/gateway/#{gateway_name}/#{operation}" },
              ->(*) { "ActiveMerchant/gateway/#{gateway_name}" },
              ->(*) { "ActiveMerchant/operation/#{operation}" }]
          end
        end
      end
    end
  end

  executes do
    next unless Gem::Version.new(ActiveMerchant::VERSION) < Gem::Version.new('1.65.0')

    deprecation_msg = 'The Ruby Agent is dropping support for ActiveMerchant versions below 1.65.0 ' \
      'in version 9.0.0. Please upgrade your ActiveMerchant version to continue receiving full support. ' \

    NewRelic::Agent.logger.log_once(
      :warn,
      :deprecated_active_merchant_version,
      deprecation_msg
    )
  end
end
