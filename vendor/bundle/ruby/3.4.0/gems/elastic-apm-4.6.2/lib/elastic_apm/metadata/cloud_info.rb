# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

require "http"

module ElasticAPM
  class Metadata
    # @api private
    class CloudInfo
      include Logging

      AWS_URI = "http://169.254.169.254/latest/dynamic/instance-identity/document"
      GCP_URI = "http://metadata.google.internal/computeMetadata/v1/?recursive=true"
      AZURE_URI = "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15"

      def initialize(config)
        @config = config
        @client = HTTP.timeout(connect: 0.1, read: 0.1)
      end

      attr_reader :config

      attr_accessor(
        :account_id,
        :account_name,
        :instance_id,
        :instance_name,
        :machine_type,
        :project_id,
        :project_name,
        :availability_zone,
        :provider,
        :region
      )

      # rubocop:disable Metrics/CyclomaticComplexity
      def fetch!
        case config.cloud_provider
        when "aws"
          fetch_aws
        when "gcp"
          fetch_gcp
        when "azure"
          fetch_azure || read_azure_app_services
        when "auto"
          fetch_aws || fetch_gcp || fetch_azure || read_azure_app_services
        when "none"
          nil
        else
          error("Unknown setting for cloud_provider '#{config.cloud_provider}'")
        end

        self
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      private

      def fetch_aws
        resp = @client.get(AWS_URI)

        return unless resp.status == 200
        return unless (metadata = JSON.parse(resp.body.to_s))

        self.provider = "aws"
        self.account_id = metadata["accountId"]
        self.instance_id = metadata["instanceId"]
        self.availability_zone = metadata["availabilityZone"]
        self.machine_type = metadata["instanceType"]
        self.region = metadata["region"]
      rescue HTTP::TimeoutError, HTTP::ConnectionError
        nil
      end

      def fetch_gcp
        resp = @client.headers("Metadata-Flavor" => "Google").get(GCP_URI)

        return unless resp.status == 200
        return unless (metadata = JSON.parse(resp.body.to_s))

        zone = metadata["instance"]["zone"]&.split("/")&.at(-1)

        self.provider = "gcp"
        self.instance_id = metadata["instance"]["id"]
        self.instance_name = metadata["instance"]["name"]
        self.project_id = metadata["project"]["numericProjectId"]
        self.project_name = metadata["project"]["projectId"]
        self.availability_zone = zone
        self.region = zone.split("-")[0..-2].join("-")
        self.machine_type = metadata["instance"]["machineType"]
      rescue HTTP::TimeoutError, HTTP::ConnectionError
        nil
      end

      def fetch_azure
        resp = @client.headers("Metadata" => "true").get(AZURE_URI)

        return unless resp.status == 200
        return unless (metadata = JSON.parse(resp.body.to_s))

        self.provider = 'azure'
        self.account_id = metadata["subscriptionId"]
        self.instance_id = metadata["vmId"]
        self.instance_name = metadata["name"]
        self.project_name = metadata["resourceGroupName"]
        self.availability_zone = metadata["zone"]
        self.machine_type = metadata["vmSize"]
        self.region = metadata["location"]
      rescue HTTP::TimeoutError, HTTP::ConnectionError
        nil
      end

      def read_azure_app_services
        owner_name, instance_id, site_name, resource_group =
          ENV.values_at(
            'WEBSITE_OWNER_NAME',
            'WEBSITE_INSTANCE_ID',
            'WEBSITE_SITE_NAME',
            'WEBSITE_RESOURCE_GROUP'
          )

        return unless owner_name && instance_id && site_name && resource_group

        self.provider = 'azure'
        self.instance_id = instance_id
        self.instance_name = site_name
        self.project_name = resource_group
        self.account_id, self.region = parse_azure_app_services_owner_name(owner_name)
      end

      private

      def parse_azure_app_services_owner_name(owner_name)
        id, rest = owner_name.split('+')
        *_, region = rest.split('-')
        region.gsub!(/webspace.*$/, '')
        [id, region]
      end
    end
  end
end
