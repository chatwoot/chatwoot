# frozen_string_literal: true

# Copyright 2020 Google LLC
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
# limitations under the License.


module Google
  module Auth
    module IDTokens
      ##
      # Failed to obtain keys from the key source.
      #
      class KeySourceError < StandardError; end

      ##
      # Failed to verify a token.
      #
      class VerificationError < StandardError; end

      ##
      # Failed to verify a token because it is expired.
      #
      class ExpiredTokenError < VerificationError; end

      ##
      # Failed to verify a token because its signature did not match.
      #
      class SignatureError < VerificationError; end

      ##
      # Failed to verify a token because its issuer did not match.
      #
      class IssuerMismatchError < VerificationError; end

      ##
      # Failed to verify a token because its audience did not match.
      #
      class AudienceMismatchError < VerificationError; end

      ##
      # Failed to verify a token because its authorized party did not match.
      #
      class AuthorizedPartyMismatchError < VerificationError; end
    end
  end
end
