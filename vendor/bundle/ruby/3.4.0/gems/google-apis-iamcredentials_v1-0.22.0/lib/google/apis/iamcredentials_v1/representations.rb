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

require 'date'
require 'google/apis/core/base_service'
require 'google/apis/core/json_representation'
require 'google/apis/core/hashable'
require 'google/apis/errors'

module Google
  module Apis
    module IamcredentialsV1
      
      class GenerateAccessTokenRequest
        class Representation < Google::Apis::Core::JsonRepresentation; end
      
        include Google::Apis::Core::JsonObjectSupport
      end
      
      class GenerateAccessTokenResponse
        class Representation < Google::Apis::Core::JsonRepresentation; end
      
        include Google::Apis::Core::JsonObjectSupport
      end
      
      class GenerateIdTokenRequest
        class Representation < Google::Apis::Core::JsonRepresentation; end
      
        include Google::Apis::Core::JsonObjectSupport
      end
      
      class GenerateIdTokenResponse
        class Representation < Google::Apis::Core::JsonRepresentation; end
      
        include Google::Apis::Core::JsonObjectSupport
      end
      
      class ServiceAccountAllowedLocations
        class Representation < Google::Apis::Core::JsonRepresentation; end
      
        include Google::Apis::Core::JsonObjectSupport
      end
      
      class SignBlobRequest
        class Representation < Google::Apis::Core::JsonRepresentation; end
      
        include Google::Apis::Core::JsonObjectSupport
      end
      
      class SignBlobResponse
        class Representation < Google::Apis::Core::JsonRepresentation; end
      
        include Google::Apis::Core::JsonObjectSupport
      end
      
      class SignJwtRequest
        class Representation < Google::Apis::Core::JsonRepresentation; end
      
        include Google::Apis::Core::JsonObjectSupport
      end
      
      class SignJwtResponse
        class Representation < Google::Apis::Core::JsonRepresentation; end
      
        include Google::Apis::Core::JsonObjectSupport
      end
      
      class GenerateAccessTokenRequest
        # @private
        class Representation < Google::Apis::Core::JsonRepresentation
          collection :delegates, as: 'delegates'
          property :lifetime, as: 'lifetime'
          collection :scope, as: 'scope'
        end
      end
      
      class GenerateAccessTokenResponse
        # @private
        class Representation < Google::Apis::Core::JsonRepresentation
          property :access_token, as: 'accessToken'
          property :expire_time, as: 'expireTime'
        end
      end
      
      class GenerateIdTokenRequest
        # @private
        class Representation < Google::Apis::Core::JsonRepresentation
          property :audience, as: 'audience'
          collection :delegates, as: 'delegates'
          property :include_email, as: 'includeEmail'
        end
      end
      
      class GenerateIdTokenResponse
        # @private
        class Representation < Google::Apis::Core::JsonRepresentation
          property :token, as: 'token'
        end
      end
      
      class ServiceAccountAllowedLocations
        # @private
        class Representation < Google::Apis::Core::JsonRepresentation
          property :encoded_locations, as: 'encodedLocations'
          collection :locations, as: 'locations'
        end
      end
      
      class SignBlobRequest
        # @private
        class Representation < Google::Apis::Core::JsonRepresentation
          collection :delegates, as: 'delegates'
          property :payload, :base64 => true, as: 'payload'
        end
      end
      
      class SignBlobResponse
        # @private
        class Representation < Google::Apis::Core::JsonRepresentation
          property :key_id, as: 'keyId'
          property :signed_blob, :base64 => true, as: 'signedBlob'
        end
      end
      
      class SignJwtRequest
        # @private
        class Representation < Google::Apis::Core::JsonRepresentation
          collection :delegates, as: 'delegates'
          property :payload, as: 'payload'
        end
      end
      
      class SignJwtResponse
        # @private
        class Representation < Google::Apis::Core::JsonRepresentation
          property :key_id, as: 'keyId'
          property :signed_jwt, as: 'signedJwt'
        end
      end
    end
  end
end
