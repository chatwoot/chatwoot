# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/utilization/aws'
require 'new_relic/agent/utilization/gcp'
require 'new_relic/agent/utilization/azure'
require 'new_relic/agent/utilization/pcf'

module NewRelic
  module Agent
    class UtilizationData
      METADATA_VERSION = 5

      VENDORS = {
        Utilization::AWS => :'utilization.detect_aws',
        Utilization::GCP => :'utilization.detect_gcp',
        Utilization::Azure => :'utilization.detect_azure',
        Utilization::PCF => :'utilization.detect_pcf'
      }

      def hostname
        NewRelic::Agent::Hostname.get
      end

      def fqdn
        NewRelic::Agent::Hostname.get_fqdn
      end

      def ip_addresses
        ::NewRelic::Agent::SystemInfo.ip_addresses
      end

      def container_id
        ::NewRelic::Agent::SystemInfo.docker_container_id
      end

      def cpu_count
        ::NewRelic::Agent::SystemInfo.clear_processor_info
        ::NewRelic::Agent::SystemInfo.num_logical_processors
      end

      def ram_in_mib
        ::NewRelic::Agent::SystemInfo.ram_in_mib
      end

      def configured_hostname
        Agent.config[:'utilization.billing_hostname']
      end

      # this is slightly ugly, but if a string value is passed in
      # for the env var: NEW_RELIC_UTILIZATION_LOGICAL_PROCESSORS the
      # coercion from EnvironmentSource will turn that into a numerical 0,
      # which is not a reasonable value for logical_processes and should
      # not be sent up
      def configured_logical_processors
        logical_processors = Agent.config[:'utilization.logical_processors']
        logical_processors unless logical_processors == 0
      end

      # see comment above as the situation is the same for:
      # NEW_RELIC_UTILIZATION_TOTAL_RAM_MIB
      def configured_total_ram_mib
        total_ram = Agent.config[:'utilization.total_ram_mib']
        total_ram unless total_ram == 0
      end

      def to_collector_hash
        result = {
          :metadata_version => METADATA_VERSION,
          :logical_processors => cpu_count,
          :total_ram_mib => ram_in_mib,
          :hostname => hostname
        }

        append_vendor_info(result)
        append_docker_info(result)
        append_configured_values(result)
        append_boot_id(result)
        append_ip_address(result)
        append_full_hostname(result)
        append_kubernetes_info(result)

        result
      end

      def append_vendor_info(collector_hash)
        VENDORS.each_pair do |klass, config_option|
          next unless Agent.config[config_option]

          vendor = klass.new

          if vendor.detect
            collector_hash[:vendors] ||= {}
            collector_hash[:vendors][vendor.vendor_name.to_sym] = vendor.metadata
            break
          end
        end
      end

      def append_docker_info(collector_hash)
        return unless Agent.config[:'utilization.detect_docker']

        if docker_container_id = container_id
          collector_hash[:vendors] ||= {}
          collector_hash[:vendors][:docker] = {:id => docker_container_id}
        end
      end

      def append_configured_values(collector_hash)
        collector_hash[:config] = config_hash unless config_hash.empty?
      end

      def append_boot_id(collector_hash)
        if bid = ::NewRelic::Agent::SystemInfo.boot_id
          collector_hash[:boot_id] = bid
        end
      end

      def append_ip_address(collector_hash)
        ips = ip_addresses
        collector_hash[:ip_address] = ips unless ips.empty?
      end

      KUBERNETES_SERVICE_HOST = 'KUBERNETES_SERVICE_HOST'.freeze

      def append_kubernetes_info(collector_hash)
        return unless Agent.config[:'utilization.detect_kubernetes']

        if host = ENV[KUBERNETES_SERVICE_HOST]
          collector_hash[:vendors] ||= {}
          collector_hash[:vendors][:kubernetes] = {
            kubernetes_service_host: host
          }
        end
      end

      def append_full_hostname(collector_hash)
        full_hostname = fqdn
        return if full_hostname.nil? || full_hostname.empty?

        collector_hash[:full_hostname] = full_hostname
      end

      def config_hash
        config_hash = {}

        if hostname = configured_hostname
          config_hash[:hostname] = hostname
        end

        if logical_processors = configured_logical_processors
          config_hash[:logical_processors] = logical_processors
        end

        if total_ram_mib = configured_total_ram_mib
          config_hash[:total_ram_mib] = total_ram_mib
        end

        config_hash
      end
    end
  end
end
