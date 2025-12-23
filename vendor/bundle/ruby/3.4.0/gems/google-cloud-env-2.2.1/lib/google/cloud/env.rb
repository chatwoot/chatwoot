# Copyright 2017 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "json"

require "google/cloud/env/compute_metadata"
require "google/cloud/env/compute_smbios"
require "google/cloud/env/file_system"
require "google/cloud/env/variables"

##
# Namespace of Google products
#
module Google
  ##
  # Namespace of Google Cloud products
  #
  module Cloud
    ##
    # ## Google Cloud hosting environment
    #
    # This library provides access to information about the application's
    # hosting environment if it is running on Google Cloud Platform. You can
    # use this library to determine which Google Cloud product is hosting your
    # application (e.g. App Engine, Kubernetes Engine), information about the
    # Google Cloud project hosting the application, information about the
    # virtual machine instance, authentication information, and so forth.
    #
    # ### Usage
    #
    # Obtain an instance of the environment info with:
    #
    # ```ruby
    # require "google/cloud/env"
    # env = Google::Cloud.env
    # ```
    #
    # Then you can interrogate any fields using methods on the object.
    #
    # ```ruby
    # if env.app_engine?
    #   # App engine specific logic
    # end
    # ```
    #
    # Any item that does not apply to the current environment will return nil.
    # For example:
    #
    # ```ruby
    # unless env.app_engine?
    #   service = env.app_engine_service_id  # => nil
    # end
    # ```
    #
    class Env
      ##
      # Create a new instance of the environment information.
      # Most clients should not need to call this directly. Obtain a singleton
      # instance of the information from `Google::Cloud.env`.
      #
      def initialize
        @variables = Variables.new
        @file_system = FileSystem.new
        @compute_smbios = ComputeSMBIOS.new
        @compute_metadata = ComputeMetadata.new variables: @variables,
                                                compute_smbios: @compute_smbios
      end

      ##
      # The variables access object. Use this to make direct queries for
      # environment variable information, or to mock out environment variables
      # for testing.
      #
      # @return [Google::Cloud::Env::Variables]
      #
      attr_reader :variables

      ##
      # The variables access object. Use this to make direct queries for
      # information from the file system, or to mock out the file system for
      # testing.
      #
      # @return [Google::Cloud::Env::FileSystem]
      #
      attr_reader :file_system

      ##
      # The compute SMBIOS access object. Use this to make direct queries for
      # compute SMBIOS information, or to mock out the SMBIOS for testing.
      #
      # @return [Google::Cloud::Env::ComputeSMBIOS]
      #
      attr_reader :compute_smbios

      ##
      # The compute metadata access object. Use this to make direct calls to
      # compute metadata or configure how metadata server queries are done, or
      # to mock out the metadata server for testing.
      #
      # @return [Google::Cloud::Env::ComputeMetadata]
      #
      attr_reader :compute_metadata

      ##
      # Determine whether the Google Compute Engine Metadata Service is running.
      #
      # This method is conservative. It may block for a short period (up to
      # about 1.5 seconds) while attempting to contact the server, but if this
      # fails, this method will return false, even though it is possible that a
      # future call could succeed. In particular, this might happen in
      # environments where there is a warmup time for the Metadata Server.
      # Early calls before the Server has warmed up may return false, while
      # later calls return true.
      #
      # @return [boolean]
      #
      def metadata?
        compute_metadata.check_existence == :confirmed
      end

      ##
      # Assert that the Metadata Server should be present, and wait for a
      # confirmed connection to ensure it is up. In general, this will run at
      # most {ComputeMetadata::DEFAULT_WARMUP_TIME} seconds to wait out the
      # expected maximum warmup time, but a shorter timeout can be provided.
      #
      # This method is useful call during application initialization to wait
      # for the Metadata Server to warm up and ensure that subsequent lookups
      # should succeed.
      #
      # @param timeout [Numeric,nil] a timeout in seconds, or nil to wait
      #     until we have conclusively decided one way or the other.
      # @return [:confirmed] if we were able to confirm connection.
      # @raise [MetadataServerNotResponding] if we were unable to confirm
      #     connection with the Metadata Server, either because the timeout
      #     expired or because the server seems to be down
      #
      def ensure_metadata timeout: nil
        compute_metadata.ensure_existence timeout: timeout
      end

      ##
      # Retrieve info from the Google Compute Engine Metadata Service.
      # Returns `nil` if the given data is not present.
      #
      # @param [String] type Type of metadata to look up. Currently supported
      #     values are "project" and "instance".
      # @param [String] entry Metadata entry path to look up.
      # @param query [Hash{String => String}] Any additional query parameters
      #     to send with the request.
      #
      # @return [String] the data
      # @return [nil] if there is no data for the specified type and entry
      # @raise [MetadataServerNotResponding] if the Metadata Server is not
      #     responding. This could either be because the metadata service is
      #     not present in the current environment, or if it is expected to be
      #     present but is overloaded or has not finished initializing.
      #
      def lookup_metadata type, entry, query: nil
        compute_metadata.lookup "#{type}/#{entry}", query: query
      end

      ##
      # Retrieve an HTTP response from the Google Compute Engine Metadata
      # Service. Returns a {ComputeMetadata::Response} with a status code,
      # data, and headers. The response could be 200 for success, 404 if the
      # given entry is not present, or other HTTP result code for authorization
      # or other errors.
      #
      # @param [String] type Type of metadata to look up. Currently supported
      #     values are "project" and "instance".
      # @param [String] entry Metadata entry path to look up.
      # @param query [Hash{String => String}] Any additional query parameters
      #     to send with the request.
      #
      # @return [Google::Cloud::Env::ComputeMetadata::Response] the response
      # @raise [MetadataServerNotResponding] if the Metadata Server is not
      #     responding. This could either be because the metadata service is
      #     not present in the current environment, or if it is expected to be
      #     present but is overloaded or has not finished initializing.
      #
      def lookup_metadata_response type, entry, query: nil
        compute_metadata.lookup_response "#{type}/#{entry}", query: query
      end

      ##
      # Determine whether the application is running on a Knative-based
      # hosting platform, such as Cloud Run or Cloud Functions.
      #
      # @return [boolean]
      #
      def knative?
        variables["K_SERVICE"] ? true : false
      end

      ##
      # Determine whether the application is running on Google App Engine.
      #
      # @return [boolean]
      #
      def app_engine?
        variables["GAE_INSTANCE"] ? true : false
      end

      ##
      # Determine whether the application is running on Google App Engine
      # Flexible Environment.
      #
      # @return [boolean]
      #
      def app_engine_flexible?
        app_engine? && variables["GAE_ENV"] != "standard"
      end

      ##
      # Determine whether the application is running on Google App Engine
      # Standard Environment.
      #
      # @return [boolean]
      #
      def app_engine_standard?
        app_engine? && variables["GAE_ENV"] == "standard"
      end

      ##
      # Determine whether the application is running on Google Kubernetes
      # Engine (GKE).
      #
      # @return [boolean]
      #
      def kubernetes_engine?
        kubernetes_engine_cluster_name ? true : false
      end
      alias container_engine? kubernetes_engine?

      ##
      # Determine whether the application is running on Google Cloud Shell.
      #
      # @return [boolean]
      #
      def cloud_shell?
        variables["GOOGLE_CLOUD_SHELL"] ? true : false
      end

      ##
      # Determine whether the application is running on Google Compute Engine.
      #
      # Note that most other products (e.g. App Engine, Kubernetes Engine,
      # Cloud Shell) themselves use Compute Engine under the hood, so this
      # method will return true for all the above products. If you want to
      # determine whether the application is running on a "raw" Compute Engine
      # VM without using a higher level hosting product, use
      # {Env#raw_compute_engine?}.
      #
      # @return [boolean]
      #
      def compute_engine?
        compute_smbios.google_compute?
      end

      ##
      # Determine whether the application is running on "raw" Google Compute
      # Engine without using a higher level hosting product such as App
      # Engine or Kubernetes Engine.
      #
      # @return [boolean]
      #
      def raw_compute_engine?
        compute_engine? && !knative? && !app_engine? && !cloud_shell? && !kubernetes_engine?
      end

      ##
      # Returns the unique string ID of the project hosting the application,
      # or `nil` if the application is not running on Google Cloud.
      #
      # @return [String,nil]
      #
      def project_id
        variables["GOOGLE_CLOUD_PROJECT"] ||
          variables["GCLOUD_PROJECT"] ||
          variables["DEVSHELL_PROJECT_ID"] ||
          compute_metadata.lookup("project/project-id")
      rescue MetadataServerNotResponding
        nil
      end

      ##
      # Returns the unique numeric ID of the project hosting the application,
      # or `nil` if the application is not running on Google Cloud.
      #
      # Caveat: this method does not work and returns `nil` on CloudShell.
      #
      # @return [Integer,nil]
      #
      def numeric_project_id
        # CloudShell's metadata server seems to run in a dummy project.
        # We can get the user's normal project ID via environment variables,
        # but the numeric ID from the metadata service is not correct. So
        # disable this for CloudShell to avoid confusion.
        return nil if cloud_shell?

        result = begin
          compute_metadata.lookup "project/numeric-project-id"
        rescue MetadataServerNotResponding
          nil
        end
        result&.to_i
      end

      ##
      # Returns the name of the VM instance hosting the application, or `nil`
      # if the application is not running on Google Cloud.
      #
      # @return [String,nil]
      #
      def instance_name
        variables["GAE_INSTANCE"] || compute_metadata.lookup("instance/name")
      rescue MetadataServerNotResponding
        nil
      end

      ##
      # Returns the description field (which may be the empty string) of the
      # VM instance hosting the application, or `nil` if the application is
      # not running on Google Cloud.
      #
      # @return [String,nil]
      #
      def instance_description
        compute_metadata.lookup "instance/description"
      rescue MetadataServerNotResponding
        nil
      end

      ##
      # Returns the zone (for example "`us-central1-c`") in which the instance
      # hosting the application lives. Returns `nil` if the application is
      # not running on Google Cloud.
      #
      # @return [String,nil]
      #
      def instance_zone
        result = compute_metadata.lookup "instance/zone"
        result&.split("/")&.last
      rescue MetadataServerNotResponding
        nil
      end

      ##
      # Returns the machine type of the VM instance hosting the application,
      # or `nil` if the application is not running on Google Cloud.
      #
      # @return [String,nil]
      #
      def instance_machine_type
        result = compute_metadata.lookup "instance/machine-type"
        result&.split("/")&.last
      rescue MetadataServerNotResponding
        nil
      end

      ##
      # Returns an array (which may be empty) of all tags set on the VM
      # instance hosting the  application, or `nil` if the application is not
      # running on Google Cloud.
      #
      # @return [Array<String>,nil]
      #
      def instance_tags
        result = compute_metadata.lookup "instance/tags"
        result.nil? ? nil : JSON.parse(result)
      rescue MetadataServerNotResponding
        nil
      end

      ##
      # Returns an array (which may be empty) of all attribute keys present
      # for the VM instance hosting the  application, or `nil` if the
      # application is not running on Google Cloud.
      #
      # @return [Array<String>,nil]
      #
      def instance_attribute_keys
        result = compute_metadata.lookup "instance/attributes/"
        result&.split
      rescue MetadataServerNotResponding
        nil
      end

      ##
      # Returns the value of the given instance attribute for the VM instance
      # hosting the application, or `nil` if the given key does not exist or
      # application is not running on Google Cloud.
      #
      # @param [String] key Attribute key to look up.
      # @return [String,nil]
      #
      def instance_attribute key
        compute_metadata.lookup "instance/attributes/#{key}"
      rescue MetadataServerNotResponding
        nil
      end

      ##
      # Returns the name of the running Knative service, or `nil` if the
      # current code is not running on Knative.
      #
      # @return [String,nil]
      #
      def knative_service_id
        variables["K_SERVICE"]
      end
      alias knative_service_name knative_service_id

      ##
      # Returns the revision of the running Knative service, or `nil` if the
      # current code is not running on Knative.
      #
      # @return [String,nil]
      #
      def knative_service_revision
        variables["K_REVISION"]
      end

      ##
      # Returns the name of the running App Engine service, or `nil` if the
      # current code is not running in App Engine.
      #
      # @return [String,nil]
      #
      def app_engine_service_id
        variables["GAE_SERVICE"]
      end
      alias app_engine_service_name app_engine_service_id

      ##
      # Returns the version of the running App Engine service, or `nil` if the
      # current code is not running in App Engine.
      #
      # @return [String,nil]
      #
      def app_engine_service_version
        variables["GAE_VERSION"]
      end

      ##
      # Returns the amount of memory reserved for the current App Engine
      # instance, or `nil` if the current code is not running in App Engine.
      #
      # @return [Integer,nil]
      #
      def app_engine_memory_mb
        result = variables["GAE_MEMORY_MB"]
        result&.to_i
      end

      ##
      # Returns the name of the Kubernetes Engine cluster hosting the
      # application, or `nil` if the current code is not running in
      # Kubernetes Engine.
      #
      # @return [String,nil]
      #
      def kubernetes_engine_cluster_name
        instance_attribute "cluster-name"
      rescue MetadataServerNotResponding
        nil
      end
      alias container_engine_cluster_name kubernetes_engine_cluster_name

      ##
      # Returns the name of the Kubernetes Engine namespace hosting the
      # application, or `nil` if the current code is not running in
      # Kubernetes Engine.
      #
      # @return [String,nil]
      #
      def kubernetes_engine_namespace_id
        # The Kubernetes namespace is difficult to obtain without help from
        # the application using the Downward API. The environment variable
        # below is set in some older versions of GKE, and the file below is
        # present in Kubernetes as of version 1.9, but it is possible that
        # alternatives will need to be found in the future.
        variables["GKE_NAMESPACE_ID"] ||
          file_system.read("/var/run/secrets/kubernetes.io/serviceaccount/namespace")
      end
      alias container_engine_namespace_id kubernetes_engine_namespace_id

      ##
      # Determine whether the application is running in an environment where a
      # Google Cloud logging agent is expected to be running. In such an
      # environment, we expect that the standard output and error streams are
      # likely to be parsed by the logging agent and log entries are written to
      # the Google Cloud Logging service.
      #
      # @return [boolean]
      #
      def logging_agent_expected?
        compute_engine? && !cloud_shell? && (app_engine? || knative? || kubernetes_engine?)
      end

      ##
      # Returns the global instance of {Google::Cloud::Env}.
      #
      # @return [Google::Cloud::Env]
      #
      def self.get
        ::Google::Cloud.env
      end
    end

    @env = Env.new

    ##
    # Returns the global instance of {Google::Cloud::Env}.
    #
    # @return [Google::Cloud::Env]
    #
    def self.env
      @env
    end
  end
end
