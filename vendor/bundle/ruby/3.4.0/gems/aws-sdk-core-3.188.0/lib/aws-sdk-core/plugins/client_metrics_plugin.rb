# frozen_string_literal: true

require 'date'
require_relative 'retries/error_inspector'

module Aws
  module Plugins
    class ClientMetricsPlugin < Seahorse::Client::Plugin

      option(:client_side_monitoring,
        default: false,
        doc_type: 'Boolean',
        docstring: <<-DOCS) do |cfg|
When `true`, client-side metrics will be collected for all API requests from
this client.
      DOCS
        resolve_client_side_monitoring(cfg)
      end

      option(:client_side_monitoring_port,
        default: 31000,
        doc_type: Integer,
        docstring: <<-DOCS) do |cfg|
Required for publishing client metrics. The port that the client side monitoring
agent is running on, where client metrics will be published via UDP.
      DOCS
        resolve_client_side_monitoring_port(cfg)
      end

      option(:client_side_monitoring_host,
        default: "127.0.0.1",
        doc_type: String,
        docstring: <<-DOCS) do |cfg|
Allows you to specify the DNS hostname or IPv4 or IPv6 address that the client
side monitoring agent is running on, where client metrics will be published via UDP.
      DOCS
        resolve_client_side_monitoring_host(cfg)
      end

      option(:client_side_monitoring_publisher,
        default: ClientSideMonitoring::Publisher,
        doc_type: Aws::ClientSideMonitoring::Publisher,
        docstring: <<-DOCS) do |cfg|
Allows you to provide a custom client-side monitoring publisher class. By default,
will use the Client Side Monitoring Agent Publisher.
      DOCS
        resolve_publisher(cfg)
      end

      option(:client_side_monitoring_client_id,
        default: "",
        doc_type: String,
        docstring: <<-DOCS) do |cfg|
Allows you to provide an identifier for this client which will be attached to
all generated client side metrics. Defaults to an empty string.
        DOCS
        resolve_client_id(cfg)
      end

      def add_handlers(handlers, config)
        if config.client_side_monitoring && config.client_side_monitoring_port
          handlers.add(Handler, step: :initialize)
          publisher = config.client_side_monitoring_publisher
          publisher.agent_port = config.client_side_monitoring_port
          publisher.agent_host = config.client_side_monitoring_host
        end
      end

      private
      def self.resolve_publisher(cfg)
        ClientSideMonitoring::Publisher.new
      end

      def self.resolve_client_side_monitoring_port(cfg)
        env_source = ENV["AWS_CSM_PORT"]
        env_source = nil if env_source == ""
        cfg_source = Aws.shared_config.csm_port(profile: cfg.profile)
        if env_source
          env_source.to_i
        elsif cfg_source
          cfg_source.to_i
        else
          31000
        end
      end

      def self.resolve_client_side_monitoring_host(cfg)
        env_source = ENV["AWS_CSM_HOST"]
        env_source = nil if env_source == ""
        cfg_source = Aws.shared_config.csm_host(profile: cfg.profile)
        if env_source
          env_source
        elsif cfg_source
          cfg_source
        else
          "127.0.0.1"
        end
      end

      def self.resolve_client_side_monitoring(cfg)
        env_source = ENV["AWS_CSM_ENABLED"]
        env_source = nil if env_source == ""
        if env_source.is_a?(String) && (env_source.downcase == "false" || env_source.downcase == "f")
          env_source = false
        end
        cfg_source = Aws.shared_config.csm_enabled(profile: cfg.profile)
        if env_source || cfg_source
          true
        else
          false
        end
      end

      def self.resolve_client_id(cfg)
        default = ""
        env_source = ENV["AWS_CSM_CLIENT_ID"]
        env_source = nil if env_source == ""
        cfg_source = Aws.shared_config.csm_client_id(profile: cfg.profile)
        env_source || cfg_source || default
      end

      class Handler < Seahorse::Client::Handler
        def call(context)
          publisher = context.config.client_side_monitoring_publisher
          service_id = context.config.api.metadata["serviceId"]
          # serviceId not present in all versions, need a fallback
          service_id ||= _calculate_service_id(context)

          request_metrics = ClientSideMonitoring::RequestMetrics.new(
            service: service_id,
            operation: context.operation.name,
            client_id: context.config.client_side_monitoring_client_id,
            region: context.config.region,
            timestamp: DateTime.now.strftime('%Q').to_i,
          )
          context.metadata[:client_metrics] = request_metrics
          start_time = Aws::Util.monotonic_milliseconds
          final_error_retryable = false
          final_aws_exception = nil
          final_aws_exception_message = nil
          final_sdk_exception = nil
          final_sdk_exception_message = nil
          begin
            @handler.call(context)
          rescue StandardError => e
            # Handle SDK Exceptions
            inspector = Retries::ErrorInspector.new(
              e,
              context.http_response.status_code
            )
            if inspector.retryable?(context)
              final_error_retryable = true
            end
            if request_metrics.api_call_attempts.empty?
              attempt = request_metrics.build_call_attempt
              attempt.sdk_exception = e.class.to_s
              attempt.sdk_exception_msg = e.message
              request_metrics.add_call_attempt(attempt)
            elsif request_metrics.api_call_attempts.last.aws_exception.nil?
              # Handle exceptions during response handlers
              attempt = request_metrics.api_call_attempts.last
              attempt.sdk_exception = e.class.to_s
              attempt.sdk_exception_msg = e.message
            elsif !e.class.to_s.match(request_metrics.api_call_attempts.last.aws_exception)
              # Handle response handling exceptions that happened in addition to
              # an AWS exception
              attempt = request_metrics.api_call_attempts.last
              attempt.sdk_exception = e.class.to_s
              attempt.sdk_exception_msg = e.message
            end # Else we don't have an SDK exception and are done.
            final_attempt = request_metrics.api_call_attempts.last
            final_aws_exception = final_attempt.aws_exception
            final_aws_exception_message = final_attempt.aws_exception_msg
            final_sdk_exception = final_attempt.sdk_exception
            final_sdk_exception_message = final_attempt.sdk_exception_msg
            raise e
          ensure
            end_time = Aws::Util.monotonic_milliseconds
            complete_opts = {
              latency: end_time - start_time,
              attempt_count: context.retries + 1,
              user_agent: context.http_request.headers["user-agent"],
              final_error_retryable: final_error_retryable,
              final_http_status_code: context.http_response.status_code,
              final_aws_exception: final_aws_exception,
              final_aws_exception_message: final_aws_exception_message,
              final_sdk_exception: final_sdk_exception,
              final_sdk_exception_message: final_sdk_exception_message
            }
            if context.metadata[:redirect_region]
              complete_opts[:region] = context.metadata[:redirect_region]
            end
            request_metrics.api_call.complete(complete_opts)
            # Report the metrics by passing the complete RequestMetrics object
            if publisher
              publisher.publish(request_metrics)
            end # Else we drop all this on the floor.
          end
        end

        private
        def _calculate_service_id(context)
          class_name = context.client.class.to_s.match(/(.+)::Client/)[1]
          class_name.sub!(/^Aws::/, '')
          _fallback_service_id(class_name)
        end

        def _fallback_service_id(id)
          # Need hard-coded exceptions since information needed to
          # reverse-engineer serviceId is not present in older versions.
          # This list should not need to grow.
          exceptions = {
            "ACMPCA" => "ACM PCA",
            "APIGateway" => "API Gateway",
            "AlexaForBusiness" => "Alexa For Business",
            "ApplicationAutoScaling" => "Application Auto Scaling",
            "ApplicationDiscoveryService" => "Application Discovery Service",
            "AutoScaling" => "Auto Scaling",
            "AutoScalingPlans" => "Auto Scaling Plans",
            "CloudHSMV2" => "CloudHSM V2",
            "CloudSearchDomain" => "CloudSearch Domain",
            "CloudWatchEvents" => "CloudWatch Events",
            "CloudWatchLogs" => "CloudWatch Logs",
            "CognitoIdentity" => "Cognito Identity",
            "CognitoIdentityProvider" => "Cognito Identity Provider",
            "CognitoSync" => "Cognito Sync",
            "ConfigService" => "Config Service",
            "CostExplorer" => "Cost Explorer",
            "CostandUsageReportService" => "Cost and Usage Report Service",
            "DataPipeline" => "Data Pipeline",
            "DatabaseMigrationService" => "Database Migration Service",
            "DeviceFarm" => "Device Farm",
            "DirectConnect" => "Direct Connect",
            "DirectoryService" => "Directory Service",
            "DynamoDBStreams" => "DynamoDB Streams",
            "ElasticBeanstalk" => "Elastic Beanstalk",
            "ElasticLoadBalancing" => "Elastic Load Balancing",
            "ElasticLoadBalancingV2" => "Elastic Load Balancing v2",
            "ElasticTranscoder" => "Elastic Transcoder",
            "ElasticsearchService" => "Elasticsearch Service",
            "IoTDataPlane" => "IoT Data Plane",
            "IoTJobsDataPlane" => "IoT Jobs Data Plane",
            "IoT1ClickDevicesService" => "IoT 1Click Devices Service",
            "IoT1ClickProjects" => "IoT 1Click Projects",
            "KinesisAnalytics" => "Kinesis Analytics",
            "KinesisVideo" => "Kinesis Video",
            "KinesisVideoArchivedMedia" => "Kinesis Video Archived Media",
            "KinesisVideoMedia" => "Kinesis Video Media",
            "LambdaPreview" => "Lambda",
            "Lex" => "Lex Runtime Service",
            "LexModelBuildingService" => "Lex Model Building Service",
            "Lightsail" => "Lightsail",
            "MQ" => "mq",
            "MachineLearning" => "Machine Learning",
            "MarketplaceCommerceAnalytics" => "Marketplace Commerce Analytics",
            "MarketplaceEntitlementService" => "Marketplace Entitlement Service",
            "MarketplaceMetering" => "Marketplace Metering",
            "MediaStoreData" => "MediaStore Data",
            "MigrationHub" => "Migration Hub",
            "ResourceGroups" => "Resource Groups",
            "ResourceGroupsTaggingAPI" => "Resource Groups Tagging API",
            "Route53" => "Route 53",
            "Route53Domains" => "Route 53 Domains",
            "SecretsManager" => "Secrets Manager",
            "SageMakerRuntime" => "SageMaker Runtime",
            "ServiceCatalog" => "Service Catalog",
            "ServiceDiscovery" => "ServiceDiscovery",
            "Signer" => "signer",
            "States" => "SFN",
            "StorageGateway" => "Storage Gateway",
            "TranscribeService" => "Transcribe Service",
            "WAFRegional" => "WAF Regional",
          }
          if exceptions[id]
            exceptions[id]
          else
            id
          end
        end
      end
    end
  end
end
