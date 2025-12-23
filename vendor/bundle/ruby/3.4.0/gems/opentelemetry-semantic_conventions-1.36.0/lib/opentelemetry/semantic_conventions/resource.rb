# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SemanticConventions
    # OpenTelemetry semantic conventions from v1.10.
    #
    # @deprecated This module is deprecated in favor of the namespaced modules under
    #   {OpenTelemetry::SemConv::Incubating} (all experimental and stable) and
    #   {OpenTelemetry::SemConv} (stable)
    module Resource
      # Name of the cloud provider
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CLOUD::CLOUD_PROVIDER} for its replacement.
      CLOUD_PROVIDER = 'cloud.provider'

      # The cloud account ID the resource is assigned to
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CLOUD::CLOUD_ACCOUNT_ID} for its replacement.
      CLOUD_ACCOUNT_ID = 'cloud.account.id'

      # The geographical region the resource is running
      # @note Refer to your provider's docs to see the available regions, for example [Alibaba Cloud regions](https://www.alibabacloud.com/help/doc-detail/40654.htm), [AWS regions](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/), [Azure regions](https://azure.microsoft.com/en-us/global-infrastructure/geographies/), [Google Cloud regions](https://cloud.google.com/about/locations), or [Tencent Cloud regions](https://intl.cloud.tencent.com/document/product/213/6091)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CLOUD::CLOUD_REGION} for its replacement.
      CLOUD_REGION = 'cloud.region'

      # Cloud regions often have multiple, isolated locations known as zones to increase availability. Availability zone represents the zone where the resource is running
      # @note Availability zones are called "zones" on Alibaba Cloud and Google Cloud
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CLOUD::CLOUD_AVAILABILITY_ZONE} for its replacement.
      CLOUD_AVAILABILITY_ZONE = 'cloud.availability_zone'

      # The cloud platform in use
      # @note The prefix of the service SHOULD match the one specified in `cloud.provider`
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CLOUD::CLOUD_PLATFORM} for its replacement.
      CLOUD_PLATFORM = 'cloud.platform'

      # The Amazon Resource Name (ARN) of an [ECS container instance](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_instances.html)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_ECS_CONTAINER_ARN} for its replacement.
      AWS_ECS_CONTAINER_ARN = 'aws.ecs.container.arn'

      # The ARN of an [ECS cluster](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_ECS_CLUSTER_ARN} for its replacement.
      AWS_ECS_CLUSTER_ARN = 'aws.ecs.cluster.arn'

      # The [launch type](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html) for an ECS task
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_ECS_LAUNCHTYPE} for its replacement.
      AWS_ECS_LAUNCHTYPE = 'aws.ecs.launchtype'

      # The ARN of an [ECS task definition](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_ECS_TASK_ARN} for its replacement.
      AWS_ECS_TASK_ARN = 'aws.ecs.task.arn'

      # The task definition family this task definition is a member of
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_ECS_TASK_FAMILY} for its replacement.
      AWS_ECS_TASK_FAMILY = 'aws.ecs.task.family'

      # The revision for this task definition
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_ECS_TASK_REVISION} for its replacement.
      AWS_ECS_TASK_REVISION = 'aws.ecs.task.revision'

      # The ARN of an EKS cluster
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_EKS_CLUSTER_ARN} for its replacement.
      AWS_EKS_CLUSTER_ARN = 'aws.eks.cluster.arn'

      # The name(s) of the AWS log group(s) an application is writing to
      # @note Multiple log groups must be supported for cases like multi-container applications, where a single application has sidecar containers, and each write to their own log group
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_LOG_GROUP_NAMES} for its replacement.
      AWS_LOG_GROUP_NAMES = 'aws.log.group.names'

      # The Amazon Resource Name(s) (ARN) of the AWS log group(s)
      # @note See the [log group ARN format documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/iam-access-control-overview-cwl.html#CWL_ARN_Format)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_LOG_GROUP_ARNS} for its replacement.
      AWS_LOG_GROUP_ARNS = 'aws.log.group.arns'

      # The name(s) of the AWS log stream(s) an application is writing to
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_LOG_STREAM_NAMES} for its replacement.
      AWS_LOG_STREAM_NAMES = 'aws.log.stream.names'

      # The ARN(s) of the AWS log stream(s)
      # @note See the [log stream ARN format documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/iam-access-control-overview-cwl.html#CWL_ARN_Format). One log group can contain several log streams, so these ARNs necessarily identify both a log group and a log stream
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::AWS::AWS_LOG_STREAM_ARNS} for its replacement.
      AWS_LOG_STREAM_ARNS = 'aws.log.stream.arns'

      # Container name used by container runtime
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CONTAINER::CONTAINER_NAME} for its replacement.
      CONTAINER_NAME = 'container.name'

      # Container ID. Usually a UUID, as for example used to [identify Docker containers](https://docs.docker.com/engine/reference/run/#container-identification). The UUID might be abbreviated
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CONTAINER::CONTAINER_ID} for its replacement.
      CONTAINER_ID = 'container.id'

      # The container runtime managing this container
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CONTAINER::CONTAINER_RUNTIME} for its replacement.
      CONTAINER_RUNTIME = 'container.runtime'

      # Name of the image the container was built on
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CONTAINER::CONTAINER_IMAGE_NAME} for its replacement.
      CONTAINER_IMAGE_NAME = 'container.image.name'

      # Container image tag
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CONTAINER::CONTAINER_IMAGE_TAGS} for its replacement.
      CONTAINER_IMAGE_TAG = 'container.image.tag'

      # Name of the [deployment environment](https://en.wikipedia.org/wiki/Deployment_environment) (aka deployment tier)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DEPLOYMENT::DEPLOYMENT_ENVIRONMENT} for its replacement.
      DEPLOYMENT_ENVIRONMENT = 'deployment.environment'

      # A unique identifier representing the device
      # @note The device identifier MUST only be defined using the values outlined below. This value is not an advertising identifier and MUST NOT be used as such. On iOS (Swift or Objective-C), this value MUST be equal to the [vendor identifier](https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor). On Android (Java or Kotlin), this value MUST be equal to the Firebase Installation ID or a globally unique UUID which is persisted across sessions in your application. More information can be found [here](https://developer.android.com/training/articles/user-data-ids) on best practices and exact implementation details. Caution should be taken when storing personal data or anything which can identify a user. GDPR and data protection laws may apply, ensure you do your own due diligence
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DEVICE::DEVICE_ID} for its replacement.
      DEVICE_ID = 'device.id'

      # The model identifier for the device
      # @note It's recommended this value represents a machine readable version of the model identifier rather than the market or consumer-friendly name of the device
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DEVICE::DEVICE_MODEL_IDENTIFIER} for its replacement.
      DEVICE_MODEL_IDENTIFIER = 'device.model.identifier'

      # The marketing name for the device model
      # @note It's recommended this value represents a human readable version of the device model rather than a machine readable alternative
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DEVICE::DEVICE_MODEL_NAME} for its replacement.
      DEVICE_MODEL_NAME = 'device.model.name'

      # The name of the device manufacturer
      # @note The Android OS provides this field via [Build](https://developer.android.com/reference/android/os/Build#MANUFACTURER). iOS apps SHOULD hardcode the value `Apple`
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::DEVICE::DEVICE_MANUFACTURER} for its replacement.
      DEVICE_MANUFACTURER = 'device.manufacturer'

      # The name of the single function that this runtime instance executes
      # @note This is the name of the function as configured/deployed on the FaaS platform and is usually different from the name of the callback function (which may be stored in the [`code.namespace`/`code.function`](../../trace/semantic_conventions/span-general.md#source-code-attributes) span attributes)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_NAME} for its replacement.
      FAAS_NAME = 'faas.name'

      # The unique ID of the single function that this runtime instance executes
      # @note Depending on the cloud provider, use:
      #
      #  * **AWS Lambda:** The function [ARN](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html).
      #  Take care not to use the "invoked ARN" directly but replace any
      #  [alias suffix](https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html) with the resolved function version, as the same runtime instance may be invocable with multiple
      #  different aliases.
      #  * **GCP:** The [URI of the resource](https://cloud.google.com/iam/docs/full-resource-names)
      #  * **Azure:** The [Fully Qualified Resource ID](https://docs.microsoft.com/en-us/rest/api/resources/resources/get-by-id).
      #
      #  On some providers, it may not be possible to determine the full ID at startup,
      #  which is why this field cannot be made required. For example, on AWS the account ID
      #  part of the ARN is not available without calling another AWS API
      #  which may be deemed too slow for a short-running lambda function.
      #  As an alternative, consider setting `faas.id` as a span attribute instead
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::CLOUD::CLOUD_RESOURCE_ID} for its replacement.
      FAAS_ID = 'faas.id'

      # The immutable version of the function being executed
      # @note Depending on the cloud provider and platform, use:
      #
      #  * **AWS Lambda:** The [function version](https://docs.aws.amazon.com/lambda/latest/dg/configuration-versions.html)
      #    (an integer represented as a decimal string).
      #  * **Google Cloud Run:** The [revision](https://cloud.google.com/run/docs/managing/revisions)
      #    (i.e., the function name plus the revision suffix).
      #  * **Google Cloud Functions:** The value of the
      #    [`K_REVISION` environment variable](https://cloud.google.com/functions/docs/env-var#runtime_environment_variables_set_automatically).
      #  * **Azure Functions:** Not applicable. Do not set this attribute
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_VERSION} for its replacement.
      FAAS_VERSION = 'faas.version'

      # The execution environment ID as a string, that will be potentially reused for other invocations to the same function/function version
      # @note * **AWS Lambda:** Use the (full) log stream name
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_INSTANCE} for its replacement.
      FAAS_INSTANCE = 'faas.instance'

      # The amount of memory available to the serverless function in MiB
      # @note It's recommended to set this attribute since e.g. too little memory can easily stop a Java AWS Lambda function from working correctly. On AWS Lambda, the environment variable `AWS_LAMBDA_FUNCTION_MEMORY_SIZE` provides this information
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::FAAS::FAAS_MAX_MEMORY} for its replacement.
      FAAS_MAX_MEMORY = 'faas.max_memory'

      # Unique host ID. For Cloud, this must be the instance_id assigned by the cloud provider
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HOST::HOST_ID} for its replacement.
      HOST_ID = 'host.id'

      # Name of the host. On Unix systems, it may contain what the hostname command returns, or the fully qualified hostname, or another name specified by the user
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HOST::HOST_NAME} for its replacement.
      HOST_NAME = 'host.name'

      # Type of host. For Cloud, this must be the machine type
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HOST::HOST_TYPE} for its replacement.
      HOST_TYPE = 'host.type'

      # The CPU architecture the host system is running on
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HOST::HOST_ARCH} for its replacement.
      HOST_ARCH = 'host.arch'

      # Name of the VM image or OS install the host was instantiated from
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HOST::HOST_IMAGE_NAME} for its replacement.
      HOST_IMAGE_NAME = 'host.image.name'

      # VM image ID. For Cloud, this value is from the provider
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HOST::HOST_IMAGE_ID} for its replacement.
      HOST_IMAGE_ID = 'host.image.id'

      # The version string of the VM image as defined in [Version Attributes](README.md#version-attributes)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::HOST::HOST_IMAGE_VERSION} for its replacement.
      HOST_IMAGE_VERSION = 'host.image.version'

      # The name of the cluster
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_CLUSTER_NAME} for its replacement.
      K8S_CLUSTER_NAME = 'k8s.cluster.name'

      # The name of the Node
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_NODE_NAME} for its replacement.
      K8S_NODE_NAME = 'k8s.node.name'

      # The UID of the Node
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_NODE_UID} for its replacement.
      K8S_NODE_UID = 'k8s.node.uid'

      # The name of the namespace that the pod is running in
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_NAMESPACE_NAME} for its replacement.
      K8S_NAMESPACE_NAME = 'k8s.namespace.name'

      # The UID of the Pod
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_POD_UID} for its replacement.
      K8S_POD_UID = 'k8s.pod.uid'

      # The name of the Pod
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_POD_NAME} for its replacement.
      K8S_POD_NAME = 'k8s.pod.name'

      # The name of the Container from Pod specification, must be unique within a Pod. Container runtime usually uses different globally unique name (`container.name`)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_CONTAINER_NAME} for its replacement.
      K8S_CONTAINER_NAME = 'k8s.container.name'

      # Number of times the container was restarted. This attribute can be used to identify a particular container (running or stopped) within a container spec
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_CONTAINER_RESTART_COUNT} for its replacement.
      K8S_CONTAINER_RESTART_COUNT = 'k8s.container.restart_count'

      # The UID of the ReplicaSet
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_REPLICASET_UID} for its replacement.
      K8S_REPLICASET_UID = 'k8s.replicaset.uid'

      # The name of the ReplicaSet
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_REPLICASET_NAME} for its replacement.
      K8S_REPLICASET_NAME = 'k8s.replicaset.name'

      # The UID of the Deployment
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_DEPLOYMENT_UID} for its replacement.
      K8S_DEPLOYMENT_UID = 'k8s.deployment.uid'

      # The name of the Deployment
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_DEPLOYMENT_NAME} for its replacement.
      K8S_DEPLOYMENT_NAME = 'k8s.deployment.name'

      # The UID of the StatefulSet
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_STATEFULSET_UID} for its replacement.
      K8S_STATEFULSET_UID = 'k8s.statefulset.uid'

      # The name of the StatefulSet
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_STATEFULSET_NAME} for its replacement.
      K8S_STATEFULSET_NAME = 'k8s.statefulset.name'

      # The UID of the DaemonSet
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_DAEMONSET_UID} for its replacement.
      K8S_DAEMONSET_UID = 'k8s.daemonset.uid'

      # The name of the DaemonSet
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_DAEMONSET_NAME} for its replacement.
      K8S_DAEMONSET_NAME = 'k8s.daemonset.name'

      # The UID of the Job
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_JOB_UID} for its replacement.
      K8S_JOB_UID = 'k8s.job.uid'

      # The name of the Job
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_JOB_NAME} for its replacement.
      K8S_JOB_NAME = 'k8s.job.name'

      # The UID of the CronJob
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_CRONJOB_UID} for its replacement.
      K8S_CRONJOB_UID = 'k8s.cronjob.uid'

      # The name of the CronJob
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::K8S::K8S_CRONJOB_NAME} for its replacement.
      K8S_CRONJOB_NAME = 'k8s.cronjob.name'

      # The operating system type
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::OS::OS_TYPE} for its replacement.
      OS_TYPE = 'os.type'

      # Human readable (not intended to be parsed) OS version information, like e.g. reported by `ver` or `lsb_release -a` commands
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::OS::OS_DESCRIPTION} for its replacement.
      OS_DESCRIPTION = 'os.description'

      # Human readable operating system name
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::OS::OS_NAME} for its replacement.
      OS_NAME = 'os.name'

      # The version string of the operating system as defined in [Version Attributes](../../resource/semantic_conventions/README.md#version-attributes)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::OS::OS_VERSION} for its replacement.
      OS_VERSION = 'os.version'

      # Process identifier (PID)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::PROCESS::PROCESS_PID} for its replacement.
      PROCESS_PID = 'process.pid'

      # The name of the process executable. On Linux based systems, can be set to the `Name` in `proc/[pid]/status`. On Windows, can be set to the base name of `GetProcessImageFileNameW`
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::PROCESS::PROCESS_EXECUTABLE_NAME} for its replacement.
      PROCESS_EXECUTABLE_NAME = 'process.executable.name'

      # The full path to the process executable. On Linux based systems, can be set to the target of `proc/[pid]/exe`. On Windows, can be set to the result of `GetProcessImageFileNameW`
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::PROCESS::PROCESS_EXECUTABLE_PATH} for its replacement.
      PROCESS_EXECUTABLE_PATH = 'process.executable.path'

      # The command used to launch the process (i.e. the command name). On Linux based systems, can be set to the zeroth string in `proc/[pid]/cmdline`. On Windows, can be set to the first parameter extracted from `GetCommandLineW`
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::PROCESS::PROCESS_COMMAND} for its replacement.
      PROCESS_COMMAND = 'process.command'

      # The full command used to launch the process as a single string representing the full command. On Windows, can be set to the result of `GetCommandLineW`. Do not set this if you have to assemble it just for monitoring; use `process.command_args` instead
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::PROCESS::PROCESS_COMMAND_LINE} for its replacement.
      PROCESS_COMMAND_LINE = 'process.command_line'

      # All the command arguments (including the command/executable itself) as received by the process. On Linux-based systems (and some other Unixoid systems supporting procfs), can be set according to the list of null-delimited strings extracted from `proc/[pid]/cmdline`. For libc-based executables, this would be the full argv vector passed to `main`
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::PROCESS::PROCESS_COMMAND_ARGS} for its replacement.
      PROCESS_COMMAND_ARGS = 'process.command_args'

      # The username of the user that owns the process
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::PROCESS::PROCESS_OWNER} for its replacement.
      PROCESS_OWNER = 'process.owner'

      # The name of the runtime of this process. For compiled native binaries, this SHOULD be the name of the compiler
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::PROCESS::PROCESS_RUNTIME_NAME} for its replacement.
      PROCESS_RUNTIME_NAME = 'process.runtime.name'

      # The version of the runtime of this process, as returned by the runtime without modification
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::PROCESS::PROCESS_RUNTIME_VERSION} for its replacement.
      PROCESS_RUNTIME_VERSION = 'process.runtime.version'

      # An additional description about the runtime of the process, for example a specific vendor customization of the runtime environment
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::PROCESS::PROCESS_RUNTIME_DESCRIPTION} for its replacement.
      PROCESS_RUNTIME_DESCRIPTION = 'process.runtime.description'

      # Logical name of the service
      # @note MUST be the same for all instances of horizontally scaled services. If the value was not specified, SDKs MUST fallback to `unknown_service:` concatenated with [`process.executable.name`](process.md#process), e.g. `unknown_service:bash`. If `process.executable.name` is not available, the value MUST be set to `unknown_service`
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::SERVICE::SERVICE_NAME} for its replacement.
      SERVICE_NAME = 'service.name'

      # A namespace for `service.name`
      # @note A string value having a meaning that helps to distinguish a group of services, for example the team name that owns a group of services. `service.name` is expected to be unique within the same namespace. If `service.namespace` is not specified in the Resource then `service.name` is expected to be unique for all services that have no explicit namespace defined (so the empty/unspecified namespace is simply one more valid namespace). Zero-length namespace string is assumed equal to unspecified namespace
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::SERVICE::SERVICE_NAMESPACE} for its replacement.
      SERVICE_NAMESPACE = 'service.namespace'

      # The string ID of the service instance
      # @note MUST be unique for each instance of the same `service.namespace,service.name` pair (in other words `service.namespace,service.name,service.instance.id` triplet MUST be globally unique). The ID helps to distinguish instances of the same service that exist at the same time (e.g. instances of a horizontally scaled service). It is preferable for the ID to be persistent and stay the same for the lifetime of the service instance, however it is acceptable that the ID is ephemeral and changes during important lifetime events for the service (e.g. service restarts). If the service has no inherent unique ID that can be used as the value of this attribute it is recommended to generate a random Version 1 or Version 4 RFC 4122 UUID (services aiming for reproducible UUIDs may also use Version 5, see RFC 4122 for more recommendations)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::SERVICE::SERVICE_INSTANCE_ID} for its replacement.
      SERVICE_INSTANCE_ID = 'service.instance.id'

      # The version string of the service API or implementation
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::SERVICE::SERVICE_VERSION} for its replacement.
      SERVICE_VERSION = 'service.version'

      # The name of the telemetry SDK as defined above
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::TELEMETRY::TELEMETRY_SDK_NAME} for its replacement.
      TELEMETRY_SDK_NAME = 'telemetry.sdk.name'

      # The language of the telemetry SDK
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::TELEMETRY::TELEMETRY_SDK_LANGUAGE} for its replacement.
      TELEMETRY_SDK_LANGUAGE = 'telemetry.sdk.language'

      # The version string of the telemetry SDK
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::TELEMETRY::TELEMETRY_SDK_VERSION} for its replacement.
      TELEMETRY_SDK_VERSION = 'telemetry.sdk.version'

      # The version string of the auto instrumentation agent, if used
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::TELEMETRY::TELEMETRY_DISTRO_VERSION} for its replacement.
      TELEMETRY_AUTO_VERSION = 'telemetry.auto.version'

      # The name of the web engine
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::WEBENGINE::WEBENGINE_NAME} for its replacement.
      WEBENGINE_NAME = 'webengine.name'

      # The version of the web engine
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::WEBENGINE::WEBENGINE_VERSION} for its replacement.
      WEBENGINE_VERSION = 'webengine.version'

      # Additional description of the web engine (e.g. detailed version and edition information)
      #
      # @deprecated The \{OpenTelemetry::SemanticConventions::Resource\} module is deprecated.
      #   See {OpenTelemetry::SemConv::Incubating::WEBENGINE::WEBENGINE_DESCRIPTION} for its replacement.
      WEBENGINE_DESCRIPTION = 'webengine.description'

    end
  end
end
