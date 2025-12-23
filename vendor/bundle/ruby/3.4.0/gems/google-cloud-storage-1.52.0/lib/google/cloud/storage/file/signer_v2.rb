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


require "addressable/uri"
require "base64"
require "cgi"
require "openssl"
require "google/cloud/storage/errors"

module Google
  module Cloud
    module Storage
      class File
        ##
        # @private Create a signed_url for a file.
        class SignerV2
          def initialize bucket, path, service
            @bucket = bucket
            @path = path
            @service = service
          end

          def self.from_file file
            new file.bucket, file.name, file.service
          end

          def self.from_bucket bucket, path
            new bucket.name, path, bucket.service
          end

          ##
          # The external path to the file, URI-encoded.
          # Will not URI encode the special `${filename}` variable.
          # "You can also use the ${filename} variable..."
          # https://cloud.google.com/storage/docs/xml-api/post-object
          #
          def ext_path
            path = "/#{@bucket}/#{@path}"
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
          def ext_url
            root_url = @service.service.root_url.chomp "/"
            "#{root_url}#{ext_path}"
          end

          def apply_option_defaults options
            adjusted_expires = (Time.now.utc + (options[:expires] || 300)).to_i
            options[:expires] = adjusted_expires
            options[:method] ||= "GET"
            options
          end

          def signature_str options
            [options[:method], options[:content_md5],
             options[:content_type], options[:expires],
             format_extension_headers(options[:headers]) + ext_path].join "\n"
          end

          def determine_signing_key options = {}
            signing_key = options[:signing_key] || options[:private_key] ||
                          options[:signer] || @service.credentials.signing_key
            raise SignedUrlUnavailable, error_msg("signing_key (private_key, signer)") unless signing_key
            signing_key
          end

          def determine_issuer options = {}
            issuer = options[:issuer] || options[:client_email] || @service.credentials.issuer
            raise SignedUrlUnavailable, error_msg("issuer (client_email)") unless issuer
            issuer
          end

          def error_msg attr_name
            "Service account credentials '#{attr_name}' is missing. To generate service account credentials " \
            "see https://cloud.google.com/iam/docs/service-accounts"
          end

          def post_object options
            options = apply_option_defaults options

            fields = {
              key: ext_path.sub("/", "")
            }

            p = options[:policy] || {}
            raise "Policy must be given in a Hash" unless p.is_a? Hash

            i = determine_issuer options
            s = determine_signing_key options

            policy_str = p.to_json
            policy = Base64.strict_encode64(policy_str).delete "\n"

            signature = generate_signature s, policy

            fields[:GoogleAccessId] = i
            fields[:signature] = signature
            fields[:policy] = policy

            Google::Cloud::Storage::PostObject.new GOOGLEAPIS_URL, fields
          end

          def signed_url options
            options = apply_option_defaults options

            i = determine_issuer options
            s = determine_signing_key options

            sig = generate_signature s, signature_str(options)
            generate_signed_url i, sig, options[:expires], options[:query]
          end

          def generate_signature signing_key, secret
            unencoded_signature = ""
            if signing_key.is_a? Proc
              unencoded_signature = signing_key.call secret
            else
              unless signing_key.respond_to? :sign
                signing_key = OpenSSL::PKey::RSA.new signing_key
              end
              unencoded_signature = signing_key.sign OpenSSL::Digest::SHA256.new, secret
            end
            Base64.strict_encode64(unencoded_signature).delete "\n"
          end

          def generate_signed_url issuer, signed_string, expires, query
            url = "#{ext_url}?GoogleAccessId=#{url_escape issuer}" \
              "&Expires=#{expires}" \
              "&Signature=#{url_escape signed_string}"

            query&.each do |name, value|
              url << "&#{url_escape name}=#{url_escape value}"
            end

            url
          end

          def format_extension_headers headers
            return "" if headers.nil?
            raise "Headers must be given in a Hash" unless headers.is_a? Hash
            flatten = headers.map do |key, value|
              "#{key.to_s.downcase}:#{value.gsub(/\s+/, ' ')}\n"
            end
            flatten.reject! { |h| h.start_with? "x-goog-encryption-key" }
            flatten.sort.join
          end

          def url_escape str
            CGI.escape String str
          end
        end
      end
    end
  end
end
