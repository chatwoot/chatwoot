# Copyright 2019 Google LLC
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


require "addressable/uri"
require "cgi"
require "openssl"
require "google/cloud/storage/errors"

module Google
  module Cloud
    module Storage
      class File
        ##
        # @private Create a signed_url for a file.
        class SignerV4
          def initialize bucket_name, file_name, service
            @bucket_name = bucket_name
            @file_name = file_name
            @service = service
          end

          def self.from_file file
            new file.bucket, file.name, file.service
          end

          def self.from_bucket bucket, file_name
            new bucket.name, file_name, bucket.service
          end

          def post_object issuer: nil,
                          client_email: nil,
                          signing_key: nil,
                          private_key: nil,
                          signer: nil,
                          expires: nil,
                          fields: nil,
                          conditions: nil,
                          scheme: "https",
                          virtual_hosted_style: nil,
                          bucket_bound_hostname: nil
            i = determine_issuer issuer, client_email
            s = determine_signing_key signing_key, private_key, signer

            now = Time.now.utc
            base_fields = required_fields i, now
            post_fields = fields.dup || {}
            post_fields.merge! base_fields

            p = {}
            p["conditions"] = policy_conditions base_fields, conditions, fields
            expires ||= 60 * 60 * 24
            p["expiration"] = (now + expires).strftime "%Y-%m-%dT%H:%M:%SZ"

            policy_str = escape_characters p.to_json

            policy = Base64.strict_encode64(policy_str).force_encoding "utf-8"
            signature = generate_signature s, policy

            post_fields["x-goog-signature"] = signature
            post_fields["policy"] = policy
            url = post_object_ext_url scheme, virtual_hosted_style, bucket_bound_hostname
            hostname = "#{url}#{bucket_path path_style?(virtual_hosted_style, bucket_bound_hostname)}"
            Google::Cloud::Storage::PostObject.new hostname, post_fields
          end

          def signed_url method: "GET",
                         expires: nil,
                         headers: nil,
                         issuer: nil,
                         client_email: nil,
                         signing_key: nil,
                         private_key: nil,
                         signer: nil,
                         query: nil,
                         scheme: "https",
                         virtual_hosted_style: nil,
                         bucket_bound_hostname: nil
            raise ArgumentError, "method is required" unless method
            issuer, signer = issuer_and_signer issuer, client_email, signing_key, private_key, signer
            datetime_now = Time.now.utc
            goog_date = datetime_now.strftime "%Y%m%dT%H%M%SZ"
            datestamp = datetime_now.strftime "%Y%m%d"
            # goog4_request is not checked.
            scope = "#{datestamp}/auto/storage/goog4_request"

            canonical_headers_str, signed_headers_str = canonical_and_signed_headers \
              headers, virtual_hosted_style, bucket_bound_hostname

            algorithm = "GOOG4-RSA-SHA256"
            expires = determine_expires expires
            credential = "#{issuer}/#{scope}"
            canonical_query_str = canonical_query query, algorithm, credential, goog_date, expires, signed_headers_str

            # From AWS: You don't include a payload hash in the Canonical
            # Request, because when you create a presigned URL, you don't know
            # the payload content because the URL is used to upload an arbitrary
            # payload. Instead, you use a constant string UNSIGNED-PAYLOAD.
            payload = headers&.key?("X-Goog-Content-SHA256") ? headers["X-Goog-Content-SHA256"] : "UNSIGNED-PAYLOAD"

            canonical_request = [method,
                                 file_path(!(virtual_hosted_style || bucket_bound_hostname)),
                                 canonical_query_str,
                                 canonical_headers_str,
                                 signed_headers_str,
                                 payload].join("\n")

            # Construct string to sign
            req_sha = Digest::SHA256.hexdigest canonical_request
            string_to_sign = [algorithm, goog_date, scope, req_sha].join "\n"

            # Sign string
            signature = signer.call string_to_sign

            # Construct signed URL
            hostname = signed_url_hostname scheme, virtual_hosted_style, bucket_bound_hostname
            "#{hostname}?#{canonical_query_str}&X-Goog-Signature=#{signature}"
          end

          # methods below are public visibility only for unit testing
          # rubocop:disable Style/StringLiterals
          def escape_characters str
            str.split("").map do |s|
              if s.ascii_only?
                case s
                when "\\"
                  '\\'
                when "\b"
                  '\b'
                when "\f"
                  '\f'
                when "\n"
                  '\n'
                when "\r"
                  '\r'
                when "\t"
                  '\t'
                when "\v"
                  '\v'
                else
                  s
                end
              else
                escape_special_unicode s
              end
            end.join
          end
          # rubocop:enable Style/StringLiterals

          def escape_special_unicode str
            str.unpack("U*").map { |i| "\\u#{i.to_s(16).rjust(4, '0')}" }.join
          end

          protected

          def required_fields issuer, time
            {
              "key" => @file_name,
              "x-goog-date" => time.strftime("%Y%m%dT%H%M%SZ"),
              "x-goog-credential" => "#{issuer}/#{time.strftime '%Y%m%d'}/auto/storage/goog4_request",
              "x-goog-algorithm" => "GOOG4-RSA-SHA256"
            }.freeze
          end

          def policy_conditions base_fields, user_conditions, user_fields
            # Convert each pair in base_fields hash to a single-entry hash in an array.
            conditions = base_fields.to_a.map { |f| Hash[*f] }
            # Add the bucket to the head of the base_fields. This is not returned in the PostObject fields.
            conditions.unshift "bucket" => @bucket_name
            # Add user-provided conditions to the head of the conditions array.
            conditions = user_conditions + conditions if user_conditions
            if user_fields
              # Convert each pair in fields hash to a single-entry hash and add it to the head of the conditions array.
              user_fields.to_a.reverse.each { |f| conditions.unshift Hash[*f] }
            end
            conditions.freeze
          end

          def signed_url_hostname scheme, virtual_hosted_style, bucket_bound_hostname
            url = ext_url scheme, virtual_hosted_style, bucket_bound_hostname
            "#{url}#{file_path path_style?(virtual_hosted_style, bucket_bound_hostname)}"
          end

          def determine_issuer issuer, client_email
            # Parse the Service Account and get client id and private key
            issuer = issuer || client_email || @service.credentials.issuer
            raise SignedUrlUnavailable, error_msg("issuer (client_email)") unless issuer
            issuer
          end

          def determine_signing_key signing_key, private_key, signer
            signing_key = signing_key || private_key || signer || @service.credentials.signing_key
            raise SignedUrlUnavailable, error_msg("signing_key (private_key, signer)") unless signing_key
            signing_key
          end

          def error_msg attr_name
            "Service account credentials '#{attr_name}' is missing. To generate service account credentials " \
            "see https://cloud.google.com/iam/docs/service-accounts"
          end

          def service_account_signer signer
            if signer.is_a? Proc
              lambda do |string_to_sign|
                sig = signer.call string_to_sign
                sig.unpack1 "H*"
              end
            else
              signer = OpenSSL::PKey::RSA.new signer unless signer.respond_to? :sign
              # Sign string to sign
              lambda do |string_to_sign|
                sig = signer.sign OpenSSL::Digest::SHA256.new, string_to_sign
                sig.unpack1 "H*"
              end
            end
          end

          def issuer_and_signer issuer, client_email, signing_key, private_key, signer
            issuer = determine_issuer issuer, client_email
            signing_key = determine_signing_key signing_key, private_key, signer
            signer = service_account_signer signing_key
            [issuer, signer]
          end

          def canonical_and_signed_headers headers, virtual_hosted_style, bucket_bound_hostname
            if virtual_hosted_style && bucket_bound_hostname
              raise "virtual_hosted_style: #{virtual_hosted_style} and bucket_bound_hostname: " \
                    "#{bucket_bound_hostname} params cannot both be passed together"
            end

            canonical_headers = headers || {}
            headers_arr = canonical_headers.map do |k, v|
              [k.downcase, v.strip.gsub(/[^\S\t]+/, " ").gsub(/\t+/, " ")]
            end
            canonical_headers = Hash[headers_arr]
            canonical_headers["host"] = host_name virtual_hosted_style, bucket_bound_hostname

            canonical_headers = canonical_headers.sort_by(&:first).to_h
            canonical_headers_str = canonical_headers.map { |k, v| "#{k}:#{v}\n" }.join
            signed_headers_str = canonical_headers.keys.join ";"
            [canonical_headers_str, signed_headers_str]
          end

          def determine_expires expires
            expires ||= 604_800 # Default is 7 days.
            if expires > 604_800
              raise ArgumentError, "Expiration time can't be longer than a week"
            end
            expires
          end

          def canonical_query query, algorithm, credential, goog_date, expires, signed_headers_str
            query ||= {}
            query["X-Goog-Algorithm"] = algorithm
            query["X-Goog-Credential"] = credential
            query["X-Goog-Date"] = goog_date
            query["X-Goog-Expires"] = expires
            query["X-Goog-SignedHeaders"] = signed_headers_str
            query = query.map { |k, v| [escape_query_param(k), escape_query_param(v)] }.sort_by(&:first).to_h
            query.map { |k, v| "#{k}=#{v}" }.join "&"
          end

          ##
          # Only the characters in the regex set [A-Za-z0-9.~_-] must be left un-escaped; all others must be
          # percent-encoded using %XX UTF-8 style.
          def escape_query_param str
            CGI.escape(str.to_s).gsub("%7E", "~").gsub "+", "%20"
          end

          def host_name virtual_hosted_style, bucket_bound_hostname
            return bucket_bound_hostname if bucket_bound_hostname
            virtual_hosted_style ? "#{@bucket_name}.storage.googleapis.com" : "storage.googleapis.com"
          end

          ##
          # The URI-encoded (percent encoded) external path to the file.
          def file_path path_style
            path = []
            path << "/#{@bucket_name}" if path_style
            path << "/#{String(@file_name)}" if @file_name && !@file_name.empty?
            CGI.escape(path.join).gsub("%2F", "/").gsub "+", "%20"
          end

          ##
          # The external path to the bucket, with trailing slash.
          def bucket_path path_style
            return "/#{@bucket_name}/" if path_style
          end

          ##
          # The external url to the file.
          def ext_url scheme, virtual_hosted_style, bucket_bound_hostname
            url = @service.service.root_url.chomp "/"
            if virtual_hosted_style
              parts = url.split "//"
              parts[1] = "#{@bucket_name}.#{parts[1]}"
              parts.join "//"
            elsif bucket_bound_hostname
              raise ArgumentError, "scheme is required" unless scheme
              URI "#{scheme.to_s.downcase}://#{bucket_bound_hostname}"
            else
              url
            end
          end

          def path_style? virtual_hosted_style, bucket_bound_hostname
            !(virtual_hosted_style || bucket_bound_hostname)
          end

          ##
          # The external path to the file, URI-encoded.
          # Will not URI encode the special `${filename}` variable.
          # "You can also use the ${filename} variable..."
          # https://cloud.google.com/storage/docs/xml-api/post-object
          #
          def post_object_ext_path
            path = "/#{@bucket_name}/#{@file_name}"
            escaped = Addressable::URI.encode_component path, Addressable::URI::CharacterClasses::PATH
            special_var = "${filename}"
            # Restore the unencoded `${filename}` variable, if present.
            if path.include? special_var
              return escaped.gsub "$%7Bfilename%7D", special_var
            end
            escaped
          end

          ##
          # The external url to the file.
          def post_object_ext_url scheme, virtual_hosted_style, bucket_bound_hostname
            url = GOOGLEAPIS_URL.dup
            if virtual_hosted_style
              parts = url.split "//"
              parts[1] = "#{@bucket_name}.#{parts[1]}/"
              parts.join "//"
            elsif bucket_bound_hostname
              raise ArgumentError, "scheme is required" unless scheme
              URI "#{scheme.to_s.downcase}://#{bucket_bound_hostname}/"
            else
              url
            end
          end

          def generate_signature signing_key, data
            packed_signature = nil
            if signing_key.is_a? Proc
              packed_signature = signing_key.call data
            else
              unless signing_key.respond_to? :sign
                signing_key = OpenSSL::PKey::RSA.new signing_key
              end
              packed_signature = signing_key.sign OpenSSL::Digest::SHA256.new, data
            end
            packed_signature.unpack1("H*").force_encoding "utf-8"
          end
        end
      end
    end
  end
end
