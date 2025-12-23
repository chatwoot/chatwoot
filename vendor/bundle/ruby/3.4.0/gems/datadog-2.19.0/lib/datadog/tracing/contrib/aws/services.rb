# frozen_string_literal: true

require_relative './service/sqs'
require_relative './service/sns'
require_relative './service/dynamodb'
require_relative './service/kinesis'
require_relative './service/eventbridge'
require_relative './service/states'
require_relative './service/s3'

module Datadog
  module Tracing
    module Contrib
      module Aws
        SERVICES = %w[
          ACM
          APIGateway
          AppStream
          ApplicationAutoScaling
          ApplicationDiscoveryService
          Athena
          AutoScaling
          Batch
          Budgets
          CloudDirectory
          CloudFormation
          CloudFront
          CloudHSM
          CloudHSMV2
          CloudSearch
          CloudSearchDomain
          CloudTrail
          CloudWatch
          CloudWatchEvents
          CloudWatchLogs
          CodeBuild
          CodeCommit
          CodeDeploy
          CodePipeline
          CodeStar
          CognitoIdentity
          CognitoIdentityProvider
          CognitoSync
          ConfigService
          CostandUsageReportService
          DAX
          DataPipeline
          DatabaseMigrationService
          DeviceFarm
          DirectConnect
          DirectoryService
          DynamoDB
          DynamoDBStreams
          EC2
          ECR
          ECS
          EFS
          EMR
          ElastiCache
          ElasticBeanstalk
          ElasticLoadBalancing
          ElasticLoadBalancingV2
          ElasticTranscoder
          ElasticsearchService
          EventBridge
          Firehose
          GameLift
          Glacier
          Glue
          Greengrass
          Health
          IAM
          ImportExport
          Inspector
          IoT
          IoTDataPlane
          KMS
          Kinesis
          KinesisAnalytics
          Lambda
          LambdaPreview
          Lex
          LexModelBuildingService
          Lightsail
          MTurk
          MachineLearning
          MarketplaceCommerceAnalytics
          MarketplaceEntitlementService
          MarketplaceMetering
          MigrationHub
          Mobile
          OpsWorks
          OpsWorksCM
          Organizations
          Pinpoint
          Polly
          RDS
          Redshift
          Rekognition
          ResourceGroupsTaggingAPI
          Route53
          Route53Domains
          S3
          SES
          SMS
          SNS
          SQS
          SSM
          STS
          SWF
          ServiceCatalog
          Schemas
          Shield
          SimpleDB
          Snowball
          States
          StorageGateway
          Support
          Textract
          WAF
          WAFRegional
          WorkDocs
          WorkSpaces
          XRay
        ].freeze

        SERVICE_HANDLERS = {
          'sqs' => Service::SQS.new,
          'sns' => Service::SNS.new,
          'dynamodb' => Service::DynamoDB.new,
          'kinesis' => Service::Kinesis.new,
          'eventbridge' => Service::EventBridge.new,
          'states' => Service::States.new,
          's3' => Service::S3.new
        }.freeze
      end
    end
  end
end
