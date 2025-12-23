# Copyright 2015 Google LLC
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


require "google/cloud/config"
require "google/cloud/core/version"

##
# # Google Cloud
#
# The google-cloud library is the official library for interacting with Google
# Cloud Platform. Google Cloud Platform is a set of modular cloud-based services
# that allow you to create anything from simple websites to complex
# applications.
#
# The goal of google-cloud is to provide an API that is comfortable to
# Rubyists. Your authentication credentials are detected automatically in
# Google Cloud Platform environments such as Google Compute Engine, Google
# App Engine and Google Kubernetes Engine. In other environments you can
# configure authentication easily, either directly in your code or via
# environment variables. Read more about the options for connecting in the
# {file:AUTHENTICATION.md Authentication Guide}.
#
module Google
  module Cloud
    ##
    # Creates a new object for connecting to Google Cloud.
    #
    # For more information on connecting to Google Cloud see the
    # {file:AUTHENTICATION.md Authentication Guide}.
    #
    # @param [String] project_id Project identifier for the service you are
    #   connecting to.
    # @param [String, Hash, Google::Auth::Credentials] credentials The path to
    #   the keyfile as a String, the contents of the keyfile as a Hash, or a
    #   Google::Auth::Credentials object.
    # @param [Integer] retries Number of times to retry requests on server
    #   error. The default value is `3`. Optional.
    # @param [Integer] timeout Default timeout to use in requests. Optional.
    #
    # @return [Google::Cloud]
    #
    # @example
    #   require "google/cloud"
    #
    #   gcloud  = Google::Cloud.new
    #   datastore = gcloud.datastore
    #   pubsub  = gcloud.pubsub
    #   storage = gcloud.storage
    #
    def self.new project_id = nil, credentials = nil, retries: nil, timeout: nil
      gcloud = Object.new
      gcloud.instance_variable_set :@project, project_id
      gcloud.instance_variable_set :@keyfile, credentials
      gcloud.instance_variable_set :@retries, retries
      gcloud.instance_variable_set :@timeout, timeout
      gcloud.extend Google::Cloud
      gcloud
    end

    ##
    # Configure the default parameter for Google::Cloud. The values defined on
    # this top level will be shared across all Google::Cloud libraries, which
    # may also add fields to this object or add sub configuration options under
    # this object.
    #
    # Possible configuration parameters:
    #
    # * `project_id`: The Google Cloud Project ID. Automatically discovered
    #                 when running from GCP environments.
    # * `credentials`: The service account JSON file path. Automatically
    #                  discovered when running from GCP environments.
    # * `on_error`: A Proc to be run when an error is encountered during on a
    #               background thread. The Proc must take the error object as
    #               the single argument.
    #
    # @return [Google::Cloud::Config] The top-level configuration object for
    #     Google::Cloud libraries.
    #
    def self.configure
      @config ||= Config.create

      yield @config if block_given?

      @config
    end

    ##
    # Initialize toplevel configuration
    # @private
    #
    def self.init_configuration
      configure do |config|
        default_project = Google::Cloud::Config.deferred do
          ENV["GOOGLE_CLOUD_PROJECT"] || ENV["GCLOUD_PROJECT"]
        end
        default_creds = Google::Cloud::Config.deferred do
          Google::Cloud::Config.credentials_from_env \
            "GOOGLE_CLOUD_CREDENTIALS", "GOOGLE_CLOUD_CREDENTIALS_JSON",
            "GOOGLE_CLOUD_KEYFILE", "GOOGLE_CLOUD_KEYFILE_JSON",
            "GCLOUD_KEYFILE", "GCLOUD_KEYFILE_JSON"
        end

        config.add_field! :project_id, default_project,
                          match: String, allow_nil: true
        config.add_alias! :project, :project_id
        config.add_field! :credentials, default_creds, match: Object
        config.add_alias! :keyfile, :credentials
        config.add_field! :on_error, nil, match: Proc
      end
    end

    ##
    # Safely load all google-cloud-* gems.
    # @private
    #
    def self.auto_load_gems
      currently_loaded_files = loaded_files

      auto_load_files.each do |auto_load_file|
        auto_load_file = File.realpath auto_load_file
        next if currently_loaded_files.include? auto_load_file
        require auto_load_file
      end
    end

    ##
    # Find files that are currently loaded.
    # @private
    #
    def self.loaded_files
      files = Array(caller).map do |backtrace_line|
        until backtrace_line.split(":").size < 2 || File.file?(backtrace_line)
          backtrace_line = backtrace_line.split(":")[0..-2].join ":"
        end
        backtrace_line
      end
      files.uniq!
      files.select! { |file| File.file? file }
      files.map { |file| File.realpath file }
    end

    ##
    # Find all google-cloud-* files for available gems.
    # @private
    #
    def self.auto_load_files
      return Gem.find_latest_files "google-cloud-*.rb" if Gem.respond_to? :find_latest_files
      # Ruby 2.0 does not have Gem.find_latest_files
      Gem.find_files "google-cloud-*.rb"
    end
  end
end

# Set the default top-level configuration
Google::Cloud.init_configuration

# Auto-load all Google Cloud service gems.
Google::Cloud.auto_load_gems
