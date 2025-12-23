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


module Google
  module Cloud
    module Storage
      class Bucket
        ##
        # # Bucket Access Control List
        #
        # Represents a Bucket's Access Control List.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   bucket.acl.readers.each { |reader| puts reader }
        #
        class Acl
          # @private
          RULES = { "authenticatedRead" => "authenticatedRead",
                    "auth" => "authenticatedRead",
                    "auth_read" => "authenticatedRead",
                    "authenticated" => "authenticatedRead",
                    "authenticated_read" => "authenticatedRead",
                    "private" => "private",
                    "projectPrivate" => "projectPrivate",
                    "proj_private" => "projectPrivate",
                    "project_private" => "projectPrivate",
                    "publicRead" => "publicRead",
                    "public" => "publicRead",
                    "public_read" => "publicRead",
                    "publicReadWrite" => "publicReadWrite",
                    "public_write" => "publicReadWrite" }.freeze

          ##
          # A boolean value or a project ID string to indicate the project to
          # be billed for operations on the bucket and its files. If this
          # attribute is set to `true`, transit costs for operations on the
          # bucket will be billed to the current project for this client. (See
          # {Project#project} for the ID of the current project.) If this
          # attribute is set to a project ID, and that project is authorized for
          # the currently authenticated service account, transit costs will be
          # billed to that project. This attribute is required with requester
          # pays-enabled buckets. The default is `nil`.
          #
          # In general, this attribute should be set when first retrieving the
          # owning bucket by providing the `user_project` option to
          # {Project#bucket}.
          #
          # See also {Bucket#requester_pays=} and {Bucket#requester_pays}.
          #
          attr_accessor :user_project

          ##
          # @private Initialized a new Acl object.
          # Must provide a valid Bucket object.
          def initialize bucket
            @bucket = bucket.name
            @service = bucket.service
            @user_project = bucket.user_project
            @owners  = nil
            @writers = nil
            @readers = nil
          end

          ##
          # Reloads all Access Control List data for the bucket.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.acl.reload!
          #
          def reload!
            gapi = @service.list_bucket_acls @bucket, user_project: user_project
            acls = Array(gapi.items)
            @owners  = entities_from_acls acls, "OWNER"
            @writers = entities_from_acls acls, "WRITER"
            @readers = entities_from_acls acls, "READER"
          end
          alias refresh! reload!

          ##
          # Lists the owners of the bucket.
          #
          # @return [Array<String>]
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.acl.owners.each { |owner| puts owner }
          #
          def owners
            reload! if @owners.nil?
            @owners
          end

          ##
          # Lists the owners of the bucket.
          #
          # @return [Array<String>]
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.acl.writers.each { |writer| puts writer }
          #
          def writers
            reload! if @writers.nil?
            @writers
          end

          ##
          # Lists the readers of the bucket.
          #
          # @return [Array<String>]
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.acl.readers.each { |reader| puts reader }
          #
          def readers
            reload! if @readers.nil?
            @readers
          end

          ##
          # Grants owner permission to the bucket.
          #
          # @param [String] entity The entity holding the permission, in one of
          #   the following forms:
          #
          #   * user-userId
          #   * user-email
          #   * group-groupId
          #   * group-email
          #   * domain-domain
          #   * project-team-projectId
          #   * allUsers
          #   * allAuthenticatedUsers
          #
          # @return [String] The entity.
          #
          # @example Grant access to a user by prepending `"user-"` to an email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   email = "heidi@example.net"
          #   bucket.acl.add_owner "user-#{email}"
          #
          # @example Grant access to a group by prepending `"group-"` to email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   email = "authors@example.net"
          #   bucket.acl.add_owner "group-#{email}"
          #
          def add_owner entity
            gapi = @service.insert_bucket_acl @bucket, entity, "OWNER",
                                              user_project: user_project
            entity = gapi.entity
            @owners&.push entity
            entity
          end

          ##
          # Grants writer permission to the bucket.
          #
          # @param [String] entity The entity holding the permission, in one of
          #   the following forms:
          #
          #   * user-userId
          #   * user-email
          #   * group-groupId
          #   * group-email
          #   * domain-domain
          #   * project-team-projectId
          #   * allUsers
          #   * allAuthenticatedUsers
          #
          # @return [String] The entity.
          #
          # @example Grant access to a user by prepending `"user-"` to an email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   email = "heidi@example.net"
          #   bucket.acl.add_writer "user-#{email}"
          #
          # @example Grant access to a group by prepending `"group-"` to email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   email = "authors@example.net"
          #   bucket.acl.add_writer "group-#{email}"
          #
          def add_writer entity
            gapi = @service.insert_bucket_acl @bucket, entity, "WRITER",
                                              user_project: user_project
            entity = gapi.entity
            @writers&.push entity
            entity
          end

          ##
          # Grants reader permission to the bucket.
          #
          # @param [String] entity The entity holding the permission, in one of
          #   the following forms:
          #
          #   * user-userId
          #   * user-email
          #   * group-groupId
          #   * group-email
          #   * domain-domain
          #   * project-team-projectId
          #   * allUsers
          #   * allAuthenticatedUsers
          #
          # @return [String] The entity.
          #
          # @example Grant access to a user by prepending `"user-"` to an email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   email = "heidi@example.net"
          #   bucket.acl.add_reader "user-#{email}"
          #
          # @example Grant access to a group by prepending `"group-"` to email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   email = "authors@example.net"
          #   bucket.acl.add_reader "group-#{email}"
          #
          def add_reader entity
            gapi = @service.insert_bucket_acl @bucket, entity, "READER",
                                              user_project: user_project
            entity = gapi.entity
            @readers&.push entity
            entity
          end

          ##
          # Permanently deletes the entity from the bucket's access control
          # list.
          #
          # @param [String] entity The entity holding the permission, in one of
          #   the following forms:
          #
          #   * user-userId
          #   * user-email
          #   * group-groupId
          #   * group-email
          #   * domain-domain
          #   * project-team-projectId
          #   * allUsers
          #   * allAuthenticatedUsers
          #
          # @return [Boolean]
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   email = "heidi@example.net"
          #   bucket.acl.delete "user-#{email}"
          #
          def delete entity
            @service.delete_bucket_acl @bucket, entity,
                                       user_project: user_project
            @owners&.delete entity
            @writers&.delete entity
            @readers&.delete entity
            true
          end

          # @private
          def self.predefined_rule_for rule_name
            RULES[rule_name.to_s]
          end

          # Predefined ACL helpers

          ##
          # Convenience method to apply the `authenticatedRead` predefined ACL
          # rule to the bucket.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.acl.auth!
          #
          def auth! if_metageneration_match: nil
            update_predefined_acl! "authenticatedRead", if_metageneration_match: if_metageneration_match
          end
          alias authenticatedRead! auth!
          alias auth_read! auth!
          alias authenticated! auth!
          alias authenticated_read! auth!

          ##
          # Convenience method to apply the `private` predefined ACL
          # rule to the bucket.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.acl.private!
          #
          def private! if_metageneration_match: nil
            update_predefined_acl! "private", if_metageneration_match: if_metageneration_match
          end

          ##
          # Convenience method to apply the `projectPrivate` predefined ACL
          # rule to the bucket.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.acl.project_private!
          #
          def project_private! if_metageneration_match: nil
            update_predefined_acl! "projectPrivate", if_metageneration_match: if_metageneration_match
          end
          alias projectPrivate! project_private!

          ##
          # Convenience method to apply the `publicRead` predefined ACL
          # rule to the bucket.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.acl.public!
          #
          def public! if_metageneration_match: nil
            update_predefined_acl! "publicRead", if_metageneration_match: if_metageneration_match
          end
          alias publicRead! public!
          alias public_read! public!

          # Convenience method to apply the `publicReadWrite` predefined ACL
          # rule to the bucket.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.acl.public_write!
          #
          def public_write! if_metageneration_match: nil
            update_predefined_acl! "publicReadWrite", if_metageneration_match: if_metageneration_match
          end
          alias publicReadWrite! public_write!

          protected

          def clear!
            @owners  = nil
            @writers = nil
            @readers = nil
            self
          end

          def update_predefined_acl! acl_role, if_metageneration_match: nil
            @service.patch_bucket @bucket, predefined_acl: acl_role,
                                           user_project: user_project,
                                           if_metageneration_match: if_metageneration_match
            clear!
          end

          def entities_from_acls acls, role
            selected = acls.select { |acl| acl.role == role }
            selected.map(&:entity)
          end
        end

        ##
        # # Bucket Default Access Control List
        #
        # Represents a Bucket's Default Access Control List.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   bucket.default_acl.readers.each { |reader| puts reader }
        #
        class DefaultAcl
          # @private
          RULES = { "authenticatedRead" => "authenticatedRead",
                    "auth" => "authenticatedRead",
                    "auth_read" => "authenticatedRead",
                    "authenticated" => "authenticatedRead",
                    "authenticated_read" => "authenticatedRead",
                    "bucketOwnerFullControl" => "bucketOwnerFullControl",
                    "owner_full" => "bucketOwnerFullControl",
                    "bucketOwnerRead" => "bucketOwnerRead",
                    "owner_read" => "bucketOwnerRead",
                    "private" => "private",
                    "projectPrivate" => "projectPrivate",
                    "project_private" => "projectPrivate",
                    "publicRead" => "publicRead",
                    "public" => "publicRead",
                    "public_read" => "publicRead" }.freeze

          ##
          # A boolean value or a project ID string to indicate the project to
          # be billed for operations on the bucket and its files. If this
          # attribute is set to `true`, transit costs for operations on the
          # bucket will be billed to the current project for this client. (See
          # {Project#project} for the ID of the current project.) If this
          # attribute is set to a project ID, and that project is authorized for
          # the currently authenticated service account, transit costs will be
          # billed to that project. This attribute is required with requester
          # pays-enabled buckets. The default is `nil`.
          #
          # In general, this attribute should be set when first retrieving the
          # owning bucket by providing the `user_project` option to
          # {Project#bucket}.
          #
          # See also {Bucket#requester_pays=} and {Bucket#requester_pays}.
          #
          attr_accessor :user_project

          ##
          # @private Initialized a new DefaultAcl object.
          # Must provide a valid Bucket object.
          def initialize bucket
            @bucket = bucket.name
            @service = bucket.service
            @user_project = bucket.user_project
            @owners  = nil
            @readers = nil
          end

          ##
          # Reloads all Default Access Control List data for the bucket.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.default_acl.reload!
          #
          def reload!
            gapi = @service.list_default_acls @bucket,
                                              user_project: user_project
            acls = Array(gapi.items).map do |acl|
              next acl if acl.is_a? Google::Apis::StorageV1::ObjectAccessControl
              raise "Unknown ACL format: #{acl.class}" unless acl.is_a? Hash
              Google::Apis::StorageV1::ObjectAccessControl.from_json acl.to_json
            end
            @owners  = entities_from_acls acls, "OWNER"
            @readers = entities_from_acls acls, "READER"
          end
          alias refresh! reload!

          ##
          # Lists the default owners for files in the bucket.
          #
          # @return [Array<String>]
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.default_acl.owners.each { |owner| puts owner }
          #
          def owners
            reload! if @owners.nil?
            @owners
          end

          ##
          # Lists the default readers for files in the bucket.
          #
          # @return [Array<String>]
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.default_acl.readers.each { |reader| puts reader }
          #
          def readers
            reload! if @readers.nil?
            @readers
          end

          ##
          # Grants default owner permission to files in the bucket.
          #
          # @param [String] entity The entity holding the permission, in one of
          #   the following forms:
          #
          #   * user-userId
          #   * user-email
          #   * group-groupId
          #   * group-email
          #   * domain-domain
          #   * project-team-projectId
          #   * allUsers
          #   * allAuthenticatedUsers
          #
          # @example Grant access to a user by prepending `"user-"` to an email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   email = "heidi@example.net"
          #   bucket.default_acl.add_owner "user-#{email}"
          #
          # @example Grant access to a group by prepending `"group-"` to email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   email = "authors@example.net"
          #   bucket.default_acl.add_owner "group-#{email}"
          #
          def add_owner entity
            gapi = @service.insert_default_acl @bucket, entity, "OWNER",
                                               user_project: user_project
            entity = gapi.entity
            @owners&.push entity
            entity
          end

          ##
          # Grants default reader permission to files in the bucket.
          #
          # @param [String] entity The entity holding the permission, in one of
          #   the following forms:
          #
          #   * user-userId
          #   * user-email
          #   * group-groupId
          #   * group-email
          #   * domain-domain
          #   * project-team-projectId
          #   * allUsers
          #   * allAuthenticatedUsers
          #
          # @example Grant access to a user by prepending `"user-"` to an email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   email = "heidi@example.net"
          #   bucket.default_acl.add_reader "user-#{email}"
          #
          # @example Grant access to a group by prepending `"group-"` to email:
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   email = "authors@example.net"
          #   bucket.default_acl.add_reader "group-#{email}"
          #
          def add_reader entity
            gapi = @service.insert_default_acl @bucket, entity, "READER",
                                               user_project: user_project
            entity = gapi.entity
            @readers&.push entity
            entity
          end

          ##
          # Permanently deletes the entity from the bucket's default access
          # control list for files.
          #
          # @param [String] entity The entity holding the permission, in one of
          #   the following forms:
          #
          #   * user-userId
          #   * user-email
          #   * group-groupId
          #   * group-email
          #   * domain-domain
          #   * project-team-projectId
          #   * allUsers
          #   * allAuthenticatedUsers
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   email = "heidi@example.net"
          #   bucket.default_acl.delete "user-#{email}"
          #
          def delete entity
            @service.delete_default_acl @bucket, entity,
                                        user_project: user_project
            @owners&.delete entity
            @readers&.delete entity
            true
          end

          # @private
          def self.predefined_rule_for rule_name
            RULES[rule_name.to_s]
          end

          # Predefined ACL helpers

          ##
          # Convenience method to apply the default `authenticatedRead`
          # predefined ACL rule to files in the bucket.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.default_acl.auth!
          #
          def auth! if_metageneration_match: nil
            update_predefined_default_acl! "authenticatedRead", if_metageneration_match: if_metageneration_match
          end
          alias authenticatedRead! auth!
          alias auth_read! auth!
          alias authenticated! auth!
          alias authenticated_read! auth!

          ##
          # Convenience method to apply the default `bucketOwnerFullControl`
          # predefined ACL rule to files in the bucket.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.default_acl.owner_full!
          #
          def owner_full! if_metageneration_match: nil
            update_predefined_default_acl! "bucketOwnerFullControl", if_metageneration_match: if_metageneration_match
          end
          alias bucketOwnerFullControl! owner_full!

          ##
          # Convenience method to apply the default `bucketOwnerRead`
          # predefined ACL rule to files in the bucket.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.default_acl.owner_read!
          #
          def owner_read! if_metageneration_match: nil
            update_predefined_default_acl! "bucketOwnerRead", if_metageneration_match: if_metageneration_match
          end
          alias bucketOwnerRead! owner_read!

          ##
          # Convenience method to apply the default `private`
          # predefined ACL rule to files in the bucket.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.default_acl.private!
          #
          def private! if_metageneration_match: nil
            update_predefined_default_acl! "private", if_metageneration_match: if_metageneration_match
          end

          ##
          # Convenience method to apply the default `projectPrivate`
          # predefined ACL rule to files in the bucket.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.default_acl.project_private!
          #
          def project_private! if_metageneration_match: nil
            update_predefined_default_acl! "projectPrivate", if_metageneration_match: if_metageneration_match
          end
          alias projectPrivate! project_private!

          ##
          # Convenience method to apply the default `publicRead`
          # predefined ACL rule to files in the bucket.
          #
          # @example
          #   require "google/cloud/storage"
          #
          #   storage = Google::Cloud::Storage.new
          #
          #   bucket = storage.bucket "my-bucket"
          #
          #   bucket.default_acl.public!
          #
          def public! if_metageneration_match: nil
            update_predefined_default_acl! "publicRead", if_metageneration_match: if_metageneration_match
          end
          alias publicRead! public!
          alias public_read! public!

          protected

          def clear!
            @owners  = nil
            @readers = nil
            self
          end

          def update_predefined_default_acl! acl_role, if_metageneration_match: nil
            @service.patch_bucket @bucket, predefined_default_acl: acl_role,
                                           user_project: user_project,
                                           if_metageneration_match: if_metageneration_match
            clear!
          end

          def entities_from_acls acls, role
            selected = acls.select { |acl| acl.role == role }
            selected.map(&:entity)
          end
        end
      end
    end
  end
end
