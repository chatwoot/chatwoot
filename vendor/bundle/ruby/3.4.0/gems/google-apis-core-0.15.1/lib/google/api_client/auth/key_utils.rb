# Copyright 2010 Google Inc.
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

module Google
  class APIClient
    ##
    # Helper for loading keys from the PKCS12 files downloaded when
    # setting up service accounts at the APIs Console.
    #
    # @deprecated Use google-auth-library-ruby instead
    module KeyUtils
      ##
      # Loads a key from PKCS12 file, assuming a single private key
      # is present.
      #
      # @param [String] keyfile
      #    Path of the PKCS12 file to load. If not a path to an actual file,
      #    assumes the string is the content of the file itself.
      # @param [String] passphrase
      #   Passphrase for unlocking the private key
      #
      # @return [OpenSSL::PKey] The private key for signing assertions.
      def self.load_from_pkcs12(keyfile, passphrase)
        load_key(keyfile, passphrase) do |content, pass_phrase|
          OpenSSL::PKCS12.new(content, pass_phrase).key
        end
      end


      ##
      # Loads a key from a PEM file.
      #
      # @param [String] keyfile
      #    Path of the PEM file to load. If not a path to an actual file,
      #    assumes the string is the content of the file itself.
      # @param [String] passphrase
      #   Passphrase for unlocking the private key
      #
      # @return [OpenSSL::PKey] The private key for signing assertions.
      #
      def self.load_from_pem(keyfile, passphrase)
        load_key(keyfile, passphrase) do | content, pass_phrase|
          OpenSSL::PKey::RSA.new(content, pass_phrase)
        end
      end

      private

      ##
      # Helper for loading keys from file or memory. Accepts a block
      # to handle the specific file format.
      #
      # @param [String] keyfile
      #    Path of thefile to load. If not a path to an actual file,
      #    assumes the string is the content of the file itself.
      # @param [String] passphrase
      #   Passphrase for unlocking the private key
      #
      # @yield [String, String]
      #   Key file & passphrase to extract key from
      # @yieldparam [String] keyfile
      #   Contents of the file
      # @yieldparam [String] passphrase
      #   Passphrase to unlock key
      # @yieldreturn [OpenSSL::PKey]
      #   Private key
      #
      # @return [OpenSSL::PKey] The private key for signing assertions.
      def self.load_key(keyfile, passphrase, &block)
        begin
          begin
            content = File.open(keyfile, 'rb') { |io| io.read }
          rescue
            content = keyfile
          end
          block.call(content, passphrase)
        rescue OpenSSL::OpenSSLError
          raise ArgumentError.new("Invalid keyfile or passphrase")
        end
      end
    end
  end
end
