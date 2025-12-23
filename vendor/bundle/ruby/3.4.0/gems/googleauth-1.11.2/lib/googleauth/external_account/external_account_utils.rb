# Copyright 2023 Google, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.require "time"

require "googleauth/base_client"
require "googleauth/helpers/connection"
require "googleauth/oauth2/sts_client"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    module ExternalAccount
      # Authenticates requests using External Account credentials, such
      # as those provided by the AWS provider or OIDC provider like Azure, etc.
      module ExternalAccountUtils
        # Cloud resource manager URL used to retrieve project information.
        CLOUD_RESOURCE_MANAGER = "https://cloudresourcemanager.googleapis.com/v1/projects/".freeze

        ##
        # Retrieves the project ID corresponding to the workload identity or workforce pool.
        # For workforce pool credentials, it returns the project ID corresponding to the workforce_pool_user_project.
        # When not determinable, None is returned.
        #
        # The resource may not have permission (resourcemanager.projects.get) to
        # call this API or the required scopes may not be selected:
        # https://cloud.google.com/resource-manager/reference/rest/v1/projects/get#authorization-scopes
        #
        # @return [string,nil]
        #     The project ID corresponding to the workload identity pool or workforce pool if determinable.
        #
        def project_id
          return @project_id unless @project_id.nil?
          project_number = self.project_number || @workforce_pool_user_project

          # if we missing either project number or scope, we won't retrieve project_id
          return nil if project_number.nil? || @scope.nil?

          url = "#{CLOUD_RESOURCE_MANAGER}#{project_number}"
          response = connection.get url do |req|
            req.headers["Authorization"] = "Bearer #{@access_token}"
            req.headers["Content-Type"] = "application/json"
          end

          if response.status == 200
            response_data = MultiJson.load response.body, symbolize_names: true
            @project_id = response_data[:projectId]
          end

          @project_id
        end

        ##
        # Retrieve the project number corresponding to workload identity pool
        # STS audience pattern:
        #     `//iam.googleapis.com/projects/$PROJECT_NUMBER/locations/...`
        #
        # @return [string, nil]
        #
        def project_number
          segments = @audience.split "/"
          idx = segments.index "projects"
          return nil if idx.nil? || idx + 1 == segments.size
          segments[idx + 1]
        end

        def normalize_timestamp time
          case time
          when NilClass
            nil
          when Time
            time
          when String
            Time.parse time
          else
            raise "Invalid time value #{time}"
          end
        end

        def service_account_email
          return nil if @service_account_impersonation_url.nil?
          start_idx = @service_account_impersonation_url.rindex "/"
          end_idx = @service_account_impersonation_url.index ":generateAccessToken"
          if start_idx != -1 && end_idx != -1 && start_idx < end_idx
            start_idx += 1
            return @service_account_impersonation_url[start_idx..end_idx]
          end
          nil
        end
      end
    end
  end
end
