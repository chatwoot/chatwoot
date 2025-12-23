# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'google/apis/iamcredentials_v1/service.rb'
require 'google/apis/iamcredentials_v1/classes.rb'
require 'google/apis/iamcredentials_v1/representations.rb'
require 'google/apis/iamcredentials_v1/gem_version.rb'

module Google
  module Apis
    # IAM Service Account Credentials API
    #
    # Creates short-lived credentials for impersonating IAM service accounts.
    # Disabling this API also disables the IAM API (iam.googleapis.com). However,
    # enabling this API doesn't enable the IAM API.
    #
    # @see https://cloud.google.com/iam/docs/creating-short-lived-service-account-credentials
    module IamcredentialsV1
      # Version of the IAM Service Account Credentials API this client connects to.
      # This is NOT the gem version.
      VERSION = 'V1'

      # See, edit, configure, and delete your Google Cloud data and see the email address for your Google Account.
      AUTH_CLOUD_PLATFORM = 'https://www.googleapis.com/auth/cloud-platform'
    end
  end
end
