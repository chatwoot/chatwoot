# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Aws
        # AWS integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_AWS_ENABLED'
          ENV_SERVICE_NAME = 'DD_TRACE_AWS_SERVICE_NAME'
          ENV_PEER_SERVICE = 'DD_TRACE_AWS_PEER_SERVICE'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_AWS_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_AWS_ANALYTICS_SAMPLE_RATE'
          DEFAULT_PEER_SERVICE_NAME = 'aws'
          SPAN_COMMAND = 'aws.command'
          TAG_AGENT = 'aws.agent'
          TAG_COMPONENT = 'aws'
          TAG_DEFAULT_AGENT = 'aws-sdk-ruby'
          TAG_HOST = 'host'
          TAG_OPERATION = 'aws.operation'
          TAG_OPERATION_COMMAND = 'command'
          TAG_PATH = 'path'
          TAG_AWS_REGION = 'aws.region'
          TAG_REGION = 'region'
          TAG_AWS_SERVICE = 'aws_service'
          TAG_AWS_ACCOUNT = 'aws_account'
          TAG_QUEUE_NAME = 'queuename'
          TAG_TOPIC_NAME = 'topicname'
          TAG_TABLE_NAME = 'tablename'
          TAG_STREAM_NAME = 'streamname'
          TAG_RULE_NAME = 'rulename'
          TAG_STATE_MACHINE_NAME = 'statemachinename'
          TAG_BUCKET_NAME = 'bucketname'
          PEER_SERVICE_SOURCES = Array[TAG_QUEUE_NAME,
            TAG_TOPIC_NAME,
            TAG_STREAM_NAME,
            TAG_TABLE_NAME,
            TAG_BUCKET_NAME,
            TAG_RULE_NAME,
            TAG_STATE_MACHINE_NAME,
            Tracing::Metadata::Ext::TAG_PEER_HOSTNAME,
            Tracing::Metadata::Ext::NET::TAG_DESTINATION_NAME,
            Tracing::Metadata::Ext::NET::TAG_TARGET_HOST,].freeze
        end
      end
    end
  end
end
