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
    module StorageV1
      
      # An AdvanceRelocateBucketOperation request.
      class AdvanceRelocateBucketOperationRequest
        include Google::Apis::Core::Hashable
      
        # Specifies the time when the relocation will revert to the sync stage if the
        # relocation hasn't succeeded.
        # Corresponds to the JSON property `expireTime`
        # @return [DateTime]
        attr_accessor :expire_time
      
        # Specifies the duration after which the relocation will revert to the sync
        # stage if the relocation hasn't succeeded. Optional, if not supplied, a default
        # value of 12h will be used.
        # Corresponds to the JSON property `ttl`
        # @return [String]
        attr_accessor :ttl
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @expire_time = args[:expire_time] if args.key?(:expire_time)
          @ttl = args[:ttl] if args.key?(:ttl)
        end
      end
      
      # An Anywhere Cache instance.
      class AnywhereCache
        include Google::Apis::Core::Hashable
      
        # The cache-level entry admission policy.
        # Corresponds to the JSON property `admissionPolicy`
        # @return [String]
        attr_accessor :admission_policy
      
        # The ID of the Anywhere cache instance.
        # Corresponds to the JSON property `anywhereCacheId`
        # @return [String]
        attr_accessor :anywhere_cache_id
      
        # The name of the bucket containing this cache instance.
        # Corresponds to the JSON property `bucket`
        # @return [String]
        attr_accessor :bucket
      
        # The creation time of the cache instance in RFC 3339 format.
        # Corresponds to the JSON property `createTime`
        # @return [DateTime]
        attr_accessor :create_time
      
        # The ID of the resource, including the project number, bucket name and anywhere
        # cache ID.
        # Corresponds to the JSON property `id`
        # @return [String]
        attr_accessor :id
      
        # The kind of item this is. For Anywhere Cache, this is always storage#
        # anywhereCache.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # True if the cache instance has an active Update long-running operation.
        # Corresponds to the JSON property `pendingUpdate`
        # @return [Boolean]
        attr_accessor :pending_update
        alias_method :pending_update?, :pending_update
      
        # The link to this cache instance.
        # Corresponds to the JSON property `selfLink`
        # @return [String]
        attr_accessor :self_link
      
        # The current state of the cache instance.
        # Corresponds to the JSON property `state`
        # @return [String]
        attr_accessor :state
      
        # The TTL of all cache entries in whole seconds. e.g., "7200s".
        # Corresponds to the JSON property `ttl`
        # @return [String]
        attr_accessor :ttl
      
        # The modification time of the cache instance metadata in RFC 3339 format.
        # Corresponds to the JSON property `updateTime`
        # @return [DateTime]
        attr_accessor :update_time
      
        # The zone in which the cache instance is running. For example, us-central1-a.
        # Corresponds to the JSON property `zone`
        # @return [String]
        attr_accessor :zone
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @admission_policy = args[:admission_policy] if args.key?(:admission_policy)
          @anywhere_cache_id = args[:anywhere_cache_id] if args.key?(:anywhere_cache_id)
          @bucket = args[:bucket] if args.key?(:bucket)
          @create_time = args[:create_time] if args.key?(:create_time)
          @id = args[:id] if args.key?(:id)
          @kind = args[:kind] if args.key?(:kind)
          @pending_update = args[:pending_update] if args.key?(:pending_update)
          @self_link = args[:self_link] if args.key?(:self_link)
          @state = args[:state] if args.key?(:state)
          @ttl = args[:ttl] if args.key?(:ttl)
          @update_time = args[:update_time] if args.key?(:update_time)
          @zone = args[:zone] if args.key?(:zone)
        end
      end
      
      # A list of Anywhere Caches.
      class AnywhereCaches
        include Google::Apis::Core::Hashable
      
        # The list of items.
        # Corresponds to the JSON property `items`
        # @return [Array<Google::Apis::StorageV1::AnywhereCache>]
        attr_accessor :items
      
        # The kind of item this is. For lists of Anywhere Caches, this is always storage#
        # anywhereCaches.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The continuation token, used to page through large result sets. Provide this
        # value in a subsequent request to return the next page of results.
        # Corresponds to the JSON property `nextPageToken`
        # @return [String]
        attr_accessor :next_page_token
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @items = args[:items] if args.key?(:items)
          @kind = args[:kind] if args.key?(:kind)
          @next_page_token = args[:next_page_token] if args.key?(:next_page_token)
        end
      end
      
      # A bucket.
      class Bucket
        include Google::Apis::Core::Hashable
      
        # Access controls on the bucket.
        # Corresponds to the JSON property `acl`
        # @return [Array<Google::Apis::StorageV1::BucketAccessControl>]
        attr_accessor :acl
      
        # The bucket's Autoclass configuration.
        # Corresponds to the JSON property `autoclass`
        # @return [Google::Apis::StorageV1::Bucket::Autoclass]
        attr_accessor :autoclass
      
        # The bucket's billing configuration.
        # Corresponds to the JSON property `billing`
        # @return [Google::Apis::StorageV1::Bucket::Billing]
        attr_accessor :billing
      
        # The bucket's Cross-Origin Resource Sharing (CORS) configuration.
        # Corresponds to the JSON property `cors`
        # @return [Array<Google::Apis::StorageV1::Bucket::CorsConfiguration>]
        attr_accessor :cors_configurations
      
        # The bucket's custom placement configuration for Custom Dual Regions.
        # Corresponds to the JSON property `customPlacementConfig`
        # @return [Google::Apis::StorageV1::Bucket::CustomPlacementConfig]
        attr_accessor :custom_placement_config
      
        # The default value for event-based hold on newly created objects in this bucket.
        # Event-based hold is a way to retain objects indefinitely until an event
        # occurs, signified by the hold's release. After being released, such objects
        # will be subject to bucket-level retention (if any). One sample use case of
        # this flag is for banks to hold loan documents for at least 3 years after loan
        # is paid in full. Here, bucket-level retention is 3 years and the event is loan
        # being paid in full. In this example, these objects will be held intact for any
        # number of years until the event has occurred (event-based hold on the object
        # is released) and then 3 more years after that. That means retention duration
        # of the objects begins from the moment event-based hold transitioned from true
        # to false. Objects under event-based hold cannot be deleted, overwritten or
        # archived until the hold is removed.
        # Corresponds to the JSON property `defaultEventBasedHold`
        # @return [Boolean]
        attr_accessor :default_event_based_hold
        alias_method :default_event_based_hold?, :default_event_based_hold
      
        # Default access controls to apply to new objects when no ACL is provided.
        # Corresponds to the JSON property `defaultObjectAcl`
        # @return [Array<Google::Apis::StorageV1::ObjectAccessControl>]
        attr_accessor :default_object_acl
      
        # Encryption configuration for a bucket.
        # Corresponds to the JSON property `encryption`
        # @return [Google::Apis::StorageV1::Bucket::Encryption]
        attr_accessor :encryption
      
        # HTTP 1.1 Entity tag for the bucket.
        # Corresponds to the JSON property `etag`
        # @return [String]
        attr_accessor :etag
      
        # The generation of this bucket.
        # Corresponds to the JSON property `generation`
        # @return [Fixnum]
        attr_accessor :generation
      
        # The hard delete time of the bucket in RFC 3339 format.
        # Corresponds to the JSON property `hardDeleteTime`
        # @return [DateTime]
        attr_accessor :hard_delete_time
      
        # The bucket's hierarchical namespace configuration.
        # Corresponds to the JSON property `hierarchicalNamespace`
        # @return [Google::Apis::StorageV1::Bucket::HierarchicalNamespace]
        attr_accessor :hierarchical_namespace
      
        # The bucket's IAM configuration.
        # Corresponds to the JSON property `iamConfiguration`
        # @return [Google::Apis::StorageV1::Bucket::IamConfiguration]
        attr_accessor :iam_configuration
      
        # The ID of the bucket. For buckets, the id and name properties are the same.
        # Corresponds to the JSON property `id`
        # @return [String]
        attr_accessor :id
      
        # The bucket's IP filter configuration. Specifies the network sources that are
        # allowed to access the operations on the bucket, as well as its underlying
        # objects. Only enforced when the mode is set to 'Enabled'.
        # Corresponds to the JSON property `ipFilter`
        # @return [Google::Apis::StorageV1::Bucket::IpFilter]
        attr_accessor :ip_filter
      
        # The kind of item this is. For buckets, this is always storage#bucket.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # User-provided labels, in key/value pairs.
        # Corresponds to the JSON property `labels`
        # @return [Hash<String,String>]
        attr_accessor :labels
      
        # The bucket's lifecycle configuration. See [Lifecycle Management](https://cloud.
        # google.com/storage/docs/lifecycle) for more information.
        # Corresponds to the JSON property `lifecycle`
        # @return [Google::Apis::StorageV1::Bucket::Lifecycle]
        attr_accessor :lifecycle
      
        # The location of the bucket. Object data for objects in the bucket resides in
        # physical storage within this region. Defaults to US. See the [Developer's
        # Guide](https://cloud.google.com/storage/docs/locations) for the authoritative
        # list.
        # Corresponds to the JSON property `location`
        # @return [String]
        attr_accessor :location
      
        # The type of the bucket location.
        # Corresponds to the JSON property `locationType`
        # @return [String]
        attr_accessor :location_type
      
        # The bucket's logging configuration, which defines the destination bucket and
        # optional name prefix for the current bucket's logs.
        # Corresponds to the JSON property `logging`
        # @return [Google::Apis::StorageV1::Bucket::Logging]
        attr_accessor :logging
      
        # The metadata generation of this bucket.
        # Corresponds to the JSON property `metageneration`
        # @return [Fixnum]
        attr_accessor :metageneration
      
        # The name of the bucket.
        # Corresponds to the JSON property `name`
        # @return [String]
        attr_accessor :name
      
        # The bucket's object retention config.
        # Corresponds to the JSON property `objectRetention`
        # @return [Google::Apis::StorageV1::Bucket::ObjectRetention]
        attr_accessor :object_retention
      
        # The owner of the bucket. This is always the project team's owner group.
        # Corresponds to the JSON property `owner`
        # @return [Google::Apis::StorageV1::Bucket::Owner]
        attr_accessor :owner
      
        # The project number of the project the bucket belongs to.
        # Corresponds to the JSON property `projectNumber`
        # @return [Fixnum]
        attr_accessor :project_number
      
        # The bucket's retention policy. The retention policy enforces a minimum
        # retention time for all objects contained in the bucket, based on their
        # creation time. Any attempt to overwrite or delete objects younger than the
        # retention period will result in a PERMISSION_DENIED error. An unlocked
        # retention policy can be modified or removed from the bucket via a storage.
        # buckets.update operation. A locked retention policy cannot be removed or
        # shortened in duration for the lifetime of the bucket. Attempting to remove or
        # decrease period of a locked retention policy will result in a
        # PERMISSION_DENIED error.
        # Corresponds to the JSON property `retentionPolicy`
        # @return [Google::Apis::StorageV1::Bucket::RetentionPolicy]
        attr_accessor :retention_policy
      
        # The Recovery Point Objective (RPO) of this bucket. Set to ASYNC_TURBO to turn
        # on Turbo Replication on a bucket.
        # Corresponds to the JSON property `rpo`
        # @return [String]
        attr_accessor :rpo
      
        # Reserved for future use.
        # Corresponds to the JSON property `satisfiesPZI`
        # @return [Boolean]
        attr_accessor :satisfies_pzi
        alias_method :satisfies_pzi?, :satisfies_pzi
      
        # Reserved for future use.
        # Corresponds to the JSON property `satisfiesPZS`
        # @return [Boolean]
        attr_accessor :satisfies_pzs
        alias_method :satisfies_pzs?, :satisfies_pzs
      
        # The URI of this bucket.
        # Corresponds to the JSON property `selfLink`
        # @return [String]
        attr_accessor :self_link
      
        # The bucket's soft delete policy, which defines the period of time that soft-
        # deleted objects will be retained, and cannot be permanently deleted.
        # Corresponds to the JSON property `softDeletePolicy`
        # @return [Google::Apis::StorageV1::Bucket::SoftDeletePolicy]
        attr_accessor :soft_delete_policy
      
        # The soft delete time of the bucket in RFC 3339 format.
        # Corresponds to the JSON property `softDeleteTime`
        # @return [DateTime]
        attr_accessor :soft_delete_time
      
        # The bucket's default storage class, used whenever no storageClass is specified
        # for a newly-created object. This defines how objects in the bucket are stored
        # and determines the SLA and the cost of storage. Values include MULTI_REGIONAL,
        # REGIONAL, STANDARD, NEARLINE, COLDLINE, ARCHIVE, and
        # DURABLE_REDUCED_AVAILABILITY. If this value is not specified when the bucket
        # is created, it will default to STANDARD. For more information, see [Storage
        # Classes](https://cloud.google.com/storage/docs/storage-classes).
        # Corresponds to the JSON property `storageClass`
        # @return [String]
        attr_accessor :storage_class
      
        # The creation time of the bucket in RFC 3339 format.
        # Corresponds to the JSON property `timeCreated`
        # @return [DateTime]
        attr_accessor :time_created
      
        # The modification time of the bucket in RFC 3339 format.
        # Corresponds to the JSON property `updated`
        # @return [DateTime]
        attr_accessor :updated
      
        # The bucket's versioning configuration.
        # Corresponds to the JSON property `versioning`
        # @return [Google::Apis::StorageV1::Bucket::Versioning]
        attr_accessor :versioning
      
        # The bucket's website configuration, controlling how the service behaves when
        # accessing bucket contents as a web site. See the [Static Website Examples](
        # https://cloud.google.com/storage/docs/static-website) for more information.
        # Corresponds to the JSON property `website`
        # @return [Google::Apis::StorageV1::Bucket::Website]
        attr_accessor :website
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @acl = args[:acl] if args.key?(:acl)
          @autoclass = args[:autoclass] if args.key?(:autoclass)
          @billing = args[:billing] if args.key?(:billing)
          @cors_configurations = args[:cors_configurations] if args.key?(:cors_configurations)
          @custom_placement_config = args[:custom_placement_config] if args.key?(:custom_placement_config)
          @default_event_based_hold = args[:default_event_based_hold] if args.key?(:default_event_based_hold)
          @default_object_acl = args[:default_object_acl] if args.key?(:default_object_acl)
          @encryption = args[:encryption] if args.key?(:encryption)
          @etag = args[:etag] if args.key?(:etag)
          @generation = args[:generation] if args.key?(:generation)
          @hard_delete_time = args[:hard_delete_time] if args.key?(:hard_delete_time)
          @hierarchical_namespace = args[:hierarchical_namespace] if args.key?(:hierarchical_namespace)
          @iam_configuration = args[:iam_configuration] if args.key?(:iam_configuration)
          @id = args[:id] if args.key?(:id)
          @ip_filter = args[:ip_filter] if args.key?(:ip_filter)
          @kind = args[:kind] if args.key?(:kind)
          @labels = args[:labels] if args.key?(:labels)
          @lifecycle = args[:lifecycle] if args.key?(:lifecycle)
          @location = args[:location] if args.key?(:location)
          @location_type = args[:location_type] if args.key?(:location_type)
          @logging = args[:logging] if args.key?(:logging)
          @metageneration = args[:metageneration] if args.key?(:metageneration)
          @name = args[:name] if args.key?(:name)
          @object_retention = args[:object_retention] if args.key?(:object_retention)
          @owner = args[:owner] if args.key?(:owner)
          @project_number = args[:project_number] if args.key?(:project_number)
          @retention_policy = args[:retention_policy] if args.key?(:retention_policy)
          @rpo = args[:rpo] if args.key?(:rpo)
          @satisfies_pzi = args[:satisfies_pzi] if args.key?(:satisfies_pzi)
          @satisfies_pzs = args[:satisfies_pzs] if args.key?(:satisfies_pzs)
          @self_link = args[:self_link] if args.key?(:self_link)
          @soft_delete_policy = args[:soft_delete_policy] if args.key?(:soft_delete_policy)
          @soft_delete_time = args[:soft_delete_time] if args.key?(:soft_delete_time)
          @storage_class = args[:storage_class] if args.key?(:storage_class)
          @time_created = args[:time_created] if args.key?(:time_created)
          @updated = args[:updated] if args.key?(:updated)
          @versioning = args[:versioning] if args.key?(:versioning)
          @website = args[:website] if args.key?(:website)
        end
        
        # The bucket's Autoclass configuration.
        class Autoclass
          include Google::Apis::Core::Hashable
        
          # Whether or not Autoclass is enabled on this bucket
          # Corresponds to the JSON property `enabled`
          # @return [Boolean]
          attr_accessor :enabled
          alias_method :enabled?, :enabled
        
          # The storage class that objects in the bucket eventually transition to if they
          # are not read for a certain length of time. Valid values are NEARLINE and
          # ARCHIVE.
          # Corresponds to the JSON property `terminalStorageClass`
          # @return [String]
          attr_accessor :terminal_storage_class
        
          # A date and time in RFC 3339 format representing the time of the most recent
          # update to "terminalStorageClass".
          # Corresponds to the JSON property `terminalStorageClassUpdateTime`
          # @return [DateTime]
          attr_accessor :terminal_storage_class_update_time
        
          # A date and time in RFC 3339 format representing the instant at which "enabled"
          # was last toggled.
          # Corresponds to the JSON property `toggleTime`
          # @return [DateTime]
          attr_accessor :toggle_time
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @enabled = args[:enabled] if args.key?(:enabled)
            @terminal_storage_class = args[:terminal_storage_class] if args.key?(:terminal_storage_class)
            @terminal_storage_class_update_time = args[:terminal_storage_class_update_time] if args.key?(:terminal_storage_class_update_time)
            @toggle_time = args[:toggle_time] if args.key?(:toggle_time)
          end
        end
        
        # The bucket's billing configuration.
        class Billing
          include Google::Apis::Core::Hashable
        
          # When set to true, Requester Pays is enabled for this bucket.
          # Corresponds to the JSON property `requesterPays`
          # @return [Boolean]
          attr_accessor :requester_pays
          alias_method :requester_pays?, :requester_pays
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @requester_pays = args[:requester_pays] if args.key?(:requester_pays)
          end
        end
        
        # 
        class CorsConfiguration
          include Google::Apis::Core::Hashable
        
          # The value, in seconds, to return in the  Access-Control-Max-Age header used in
          # preflight responses.
          # Corresponds to the JSON property `maxAgeSeconds`
          # @return [Fixnum]
          attr_accessor :max_age_seconds
        
          # The list of HTTP methods on which to include CORS response headers, (GET,
          # OPTIONS, POST, etc) Note: "*" is permitted in the list of methods, and means "
          # any method".
          # Corresponds to the JSON property `method`
          # @return [Array<String>]
          attr_accessor :http_method
        
          # The list of Origins eligible to receive CORS response headers. Note: "*" is
          # permitted in the list of origins, and means "any Origin".
          # Corresponds to the JSON property `origin`
          # @return [Array<String>]
          attr_accessor :origin
        
          # The list of HTTP headers other than the simple response headers to give
          # permission for the user-agent to share across domains.
          # Corresponds to the JSON property `responseHeader`
          # @return [Array<String>]
          attr_accessor :response_header
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @max_age_seconds = args[:max_age_seconds] if args.key?(:max_age_seconds)
            @http_method = args[:http_method] if args.key?(:http_method)
            @origin = args[:origin] if args.key?(:origin)
            @response_header = args[:response_header] if args.key?(:response_header)
          end
        end
        
        # The bucket's custom placement configuration for Custom Dual Regions.
        class CustomPlacementConfig
          include Google::Apis::Core::Hashable
        
          # The list of regional locations in which data is placed.
          # Corresponds to the JSON property `dataLocations`
          # @return [Array<String>]
          attr_accessor :data_locations
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @data_locations = args[:data_locations] if args.key?(:data_locations)
          end
        end
        
        # Encryption configuration for a bucket.
        class Encryption
          include Google::Apis::Core::Hashable
        
          # A Cloud KMS key that will be used to encrypt objects inserted into this bucket,
          # if no encryption method is specified.
          # Corresponds to the JSON property `defaultKmsKeyName`
          # @return [String]
          attr_accessor :default_kms_key_name
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @default_kms_key_name = args[:default_kms_key_name] if args.key?(:default_kms_key_name)
          end
        end
        
        # The bucket's hierarchical namespace configuration.
        class HierarchicalNamespace
          include Google::Apis::Core::Hashable
        
          # When set to true, hierarchical namespace is enabled for this bucket.
          # Corresponds to the JSON property `enabled`
          # @return [Boolean]
          attr_accessor :enabled
          alias_method :enabled?, :enabled
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @enabled = args[:enabled] if args.key?(:enabled)
          end
        end
        
        # The bucket's IAM configuration.
        class IamConfiguration
          include Google::Apis::Core::Hashable
        
          # The bucket's uniform bucket-level access configuration. The feature was
          # formerly known as Bucket Policy Only. For backward compatibility, this field
          # will be populated with identical information as the uniformBucketLevelAccess
          # field. We recommend using the uniformBucketLevelAccess field to enable and
          # disable the feature.
          # Corresponds to the JSON property `bucketPolicyOnly`
          # @return [Google::Apis::StorageV1::Bucket::IamConfiguration::BucketPolicyOnly]
          attr_accessor :bucket_policy_only
        
          # The bucket's Public Access Prevention configuration. Currently, 'inherited'
          # and 'enforced' are supported.
          # Corresponds to the JSON property `publicAccessPrevention`
          # @return [String]
          attr_accessor :public_access_prevention
        
          # The bucket's uniform bucket-level access configuration.
          # Corresponds to the JSON property `uniformBucketLevelAccess`
          # @return [Google::Apis::StorageV1::Bucket::IamConfiguration::UniformBucketLevelAccess]
          attr_accessor :uniform_bucket_level_access
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @bucket_policy_only = args[:bucket_policy_only] if args.key?(:bucket_policy_only)
            @public_access_prevention = args[:public_access_prevention] if args.key?(:public_access_prevention)
            @uniform_bucket_level_access = args[:uniform_bucket_level_access] if args.key?(:uniform_bucket_level_access)
          end
          
          # The bucket's uniform bucket-level access configuration. The feature was
          # formerly known as Bucket Policy Only. For backward compatibility, this field
          # will be populated with identical information as the uniformBucketLevelAccess
          # field. We recommend using the uniformBucketLevelAccess field to enable and
          # disable the feature.
          class BucketPolicyOnly
            include Google::Apis::Core::Hashable
          
            # If set, access is controlled only by bucket-level or above IAM policies.
            # Corresponds to the JSON property `enabled`
            # @return [Boolean]
            attr_accessor :enabled
            alias_method :enabled?, :enabled
          
            # The deadline for changing iamConfiguration.bucketPolicyOnly.enabled from true
            # to false in RFC 3339 format. iamConfiguration.bucketPolicyOnly.enabled may be
            # changed from true to false until the locked time, after which the field is
            # immutable.
            # Corresponds to the JSON property `lockedTime`
            # @return [DateTime]
            attr_accessor :locked_time
          
            def initialize(**args)
               update!(**args)
            end
          
            # Update properties of this object
            def update!(**args)
              @enabled = args[:enabled] if args.key?(:enabled)
              @locked_time = args[:locked_time] if args.key?(:locked_time)
            end
          end
          
          # The bucket's uniform bucket-level access configuration.
          class UniformBucketLevelAccess
            include Google::Apis::Core::Hashable
          
            # If set, access is controlled only by bucket-level or above IAM policies.
            # Corresponds to the JSON property `enabled`
            # @return [Boolean]
            attr_accessor :enabled
            alias_method :enabled?, :enabled
          
            # The deadline for changing iamConfiguration.uniformBucketLevelAccess.enabled
            # from true to false in RFC 3339  format. iamConfiguration.
            # uniformBucketLevelAccess.enabled may be changed from true to false until the
            # locked time, after which the field is immutable.
            # Corresponds to the JSON property `lockedTime`
            # @return [DateTime]
            attr_accessor :locked_time
          
            def initialize(**args)
               update!(**args)
            end
          
            # Update properties of this object
            def update!(**args)
              @enabled = args[:enabled] if args.key?(:enabled)
              @locked_time = args[:locked_time] if args.key?(:locked_time)
            end
          end
        end
        
        # The bucket's IP filter configuration. Specifies the network sources that are
        # allowed to access the operations on the bucket, as well as its underlying
        # objects. Only enforced when the mode is set to 'Enabled'.
        class IpFilter
          include Google::Apis::Core::Hashable
        
          # The mode of the IP filter. Valid values are 'Enabled' and 'Disabled'.
          # Corresponds to the JSON property `mode`
          # @return [String]
          attr_accessor :mode
        
          # The public network source of the bucket's IP filter.
          # Corresponds to the JSON property `publicNetworkSource`
          # @return [Google::Apis::StorageV1::Bucket::IpFilter::PublicNetworkSource]
          attr_accessor :public_network_source
        
          # The list of [VPC network](https://cloud.google.com/vpc/docs/vpc) sources of
          # the bucket's IP filter.
          # Corresponds to the JSON property `vpcNetworkSources`
          # @return [Array<Google::Apis::StorageV1::Bucket::IpFilter::VpcNetworkSource>]
          attr_accessor :vpc_network_sources
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @mode = args[:mode] if args.key?(:mode)
            @public_network_source = args[:public_network_source] if args.key?(:public_network_source)
            @vpc_network_sources = args[:vpc_network_sources] if args.key?(:vpc_network_sources)
          end
          
          # The public network source of the bucket's IP filter.
          class PublicNetworkSource
            include Google::Apis::Core::Hashable
          
            # The list of public IPv4, IPv6 cidr ranges that are allowed to access the
            # bucket.
            # Corresponds to the JSON property `allowedIpCidrRanges`
            # @return [Array<String>]
            attr_accessor :allowed_ip_cidr_ranges
          
            def initialize(**args)
               update!(**args)
            end
          
            # Update properties of this object
            def update!(**args)
              @allowed_ip_cidr_ranges = args[:allowed_ip_cidr_ranges] if args.key?(:allowed_ip_cidr_ranges)
            end
          end
          
          # 
          class VpcNetworkSource
            include Google::Apis::Core::Hashable
          
            # The list of IPv4, IPv6 cidr ranges subnetworks that are allowed to access the
            # bucket.
            # Corresponds to the JSON property `allowedIpCidrRanges`
            # @return [Array<String>]
            attr_accessor :allowed_ip_cidr_ranges
          
            # Name of the network. Format: projects/`PROJECT_ID`/global/networks/`
            # NETWORK_NAME`
            # Corresponds to the JSON property `network`
            # @return [String]
            attr_accessor :network
          
            def initialize(**args)
               update!(**args)
            end
          
            # Update properties of this object
            def update!(**args)
              @allowed_ip_cidr_ranges = args[:allowed_ip_cidr_ranges] if args.key?(:allowed_ip_cidr_ranges)
              @network = args[:network] if args.key?(:network)
            end
          end
        end
        
        # The bucket's lifecycle configuration. See [Lifecycle Management](https://cloud.
        # google.com/storage/docs/lifecycle) for more information.
        class Lifecycle
          include Google::Apis::Core::Hashable
        
          # A lifecycle management rule, which is made of an action to take and the
          # condition(s) under which the action will be taken.
          # Corresponds to the JSON property `rule`
          # @return [Array<Google::Apis::StorageV1::Bucket::Lifecycle::Rule>]
          attr_accessor :rule
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @rule = args[:rule] if args.key?(:rule)
          end
          
          # 
          class Rule
            include Google::Apis::Core::Hashable
          
            # The action to take.
            # Corresponds to the JSON property `action`
            # @return [Google::Apis::StorageV1::Bucket::Lifecycle::Rule::Action]
            attr_accessor :action
          
            # The condition(s) under which the action will be taken.
            # Corresponds to the JSON property `condition`
            # @return [Google::Apis::StorageV1::Bucket::Lifecycle::Rule::Condition]
            attr_accessor :condition
          
            def initialize(**args)
               update!(**args)
            end
          
            # Update properties of this object
            def update!(**args)
              @action = args[:action] if args.key?(:action)
              @condition = args[:condition] if args.key?(:condition)
            end
            
            # The action to take.
            class Action
              include Google::Apis::Core::Hashable
            
              # Target storage class. Required iff the type of the action is SetStorageClass.
              # Corresponds to the JSON property `storageClass`
              # @return [String]
              attr_accessor :storage_class
            
              # Type of the action. Currently, only Delete, SetStorageClass, and
              # AbortIncompleteMultipartUpload are supported.
              # Corresponds to the JSON property `type`
              # @return [String]
              attr_accessor :type
            
              def initialize(**args)
                 update!(**args)
              end
            
              # Update properties of this object
              def update!(**args)
                @storage_class = args[:storage_class] if args.key?(:storage_class)
                @type = args[:type] if args.key?(:type)
              end
            end
            
            # The condition(s) under which the action will be taken.
            class Condition
              include Google::Apis::Core::Hashable
            
              # Age of an object (in days). This condition is satisfied when an object reaches
              # the specified age.
              # Corresponds to the JSON property `age`
              # @return [Fixnum]
              attr_accessor :age
            
              # A date in RFC 3339 format with only the date part (for instance, "2013-01-15").
              # This condition is satisfied when an object is created before midnight of the
              # specified date in UTC.
              # Corresponds to the JSON property `createdBefore`
              # @return [Date]
              attr_accessor :created_before
            
              # A date in RFC 3339 format with only the date part (for instance, "2013-01-15").
              # This condition is satisfied when the custom time on an object is before this
              # date in UTC.
              # Corresponds to the JSON property `customTimeBefore`
              # @return [Date]
              attr_accessor :custom_time_before
            
              # Number of days elapsed since the user-specified timestamp set on an object.
              # The condition is satisfied if the days elapsed is at least this number. If no
              # custom timestamp is specified on an object, the condition does not apply.
              # Corresponds to the JSON property `daysSinceCustomTime`
              # @return [Fixnum]
              attr_accessor :days_since_custom_time
            
              # Number of days elapsed since the noncurrent timestamp of an object. The
              # condition is satisfied if the days elapsed is at least this number. This
              # condition is relevant only for versioned objects. The value of the field must
              # be a nonnegative integer. If it's zero, the object version will become
              # eligible for Lifecycle action as soon as it becomes noncurrent.
              # Corresponds to the JSON property `daysSinceNoncurrentTime`
              # @return [Fixnum]
              attr_accessor :days_since_noncurrent_time
            
              # Relevant only for versioned objects. If the value is true, this condition
              # matches live objects; if the value is false, it matches archived objects.
              # Corresponds to the JSON property `isLive`
              # @return [Boolean]
              attr_accessor :is_live
              alias_method :is_live?, :is_live
            
              # A regular expression that satisfies the RE2 syntax. This condition is
              # satisfied when the name of the object matches the RE2 pattern. Note: This
              # feature is currently in the "Early Access" launch stage and is only available
              # to a whitelisted set of users; that means that this feature may be changed in
              # backward-incompatible ways and that it is not guaranteed to be released.
              # Corresponds to the JSON property `matchesPattern`
              # @return [String]
              attr_accessor :matches_pattern
            
              # List of object name prefixes. This condition will be satisfied when at least
              # one of the prefixes exactly matches the beginning of the object name.
              # Corresponds to the JSON property `matchesPrefix`
              # @return [Array<String>]
              attr_accessor :matches_prefix
            
              # Objects having any of the storage classes specified by this condition will be
              # matched. Values include MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE,
              # STANDARD, and DURABLE_REDUCED_AVAILABILITY.
              # Corresponds to the JSON property `matchesStorageClass`
              # @return [Array<String>]
              attr_accessor :matches_storage_class
            
              # List of object name suffixes. This condition will be satisfied when at least
              # one of the suffixes exactly matches the end of the object name.
              # Corresponds to the JSON property `matchesSuffix`
              # @return [Array<String>]
              attr_accessor :matches_suffix
            
              # A date in RFC 3339 format with only the date part (for instance, "2013-01-15").
              # This condition is satisfied when the noncurrent time on an object is before
              # this date in UTC. This condition is relevant only for versioned objects.
              # Corresponds to the JSON property `noncurrentTimeBefore`
              # @return [Date]
              attr_accessor :noncurrent_time_before
            
              # Relevant only for versioned objects. If the value is N, this condition is
              # satisfied when there are at least N versions (including the live version)
              # newer than this version of the object.
              # Corresponds to the JSON property `numNewerVersions`
              # @return [Fixnum]
              attr_accessor :num_newer_versions
            
              def initialize(**args)
                 update!(**args)
              end
            
              # Update properties of this object
              def update!(**args)
                @age = args[:age] if args.key?(:age)
                @created_before = args[:created_before] if args.key?(:created_before)
                @custom_time_before = args[:custom_time_before] if args.key?(:custom_time_before)
                @days_since_custom_time = args[:days_since_custom_time] if args.key?(:days_since_custom_time)
                @days_since_noncurrent_time = args[:days_since_noncurrent_time] if args.key?(:days_since_noncurrent_time)
                @is_live = args[:is_live] if args.key?(:is_live)
                @matches_pattern = args[:matches_pattern] if args.key?(:matches_pattern)
                @matches_prefix = args[:matches_prefix] if args.key?(:matches_prefix)
                @matches_storage_class = args[:matches_storage_class] if args.key?(:matches_storage_class)
                @matches_suffix = args[:matches_suffix] if args.key?(:matches_suffix)
                @noncurrent_time_before = args[:noncurrent_time_before] if args.key?(:noncurrent_time_before)
                @num_newer_versions = args[:num_newer_versions] if args.key?(:num_newer_versions)
              end
            end
          end
        end
        
        # The bucket's logging configuration, which defines the destination bucket and
        # optional name prefix for the current bucket's logs.
        class Logging
          include Google::Apis::Core::Hashable
        
          # The destination bucket where the current bucket's logs should be placed.
          # Corresponds to the JSON property `logBucket`
          # @return [String]
          attr_accessor :log_bucket
        
          # A prefix for log object names.
          # Corresponds to the JSON property `logObjectPrefix`
          # @return [String]
          attr_accessor :log_object_prefix
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @log_bucket = args[:log_bucket] if args.key?(:log_bucket)
            @log_object_prefix = args[:log_object_prefix] if args.key?(:log_object_prefix)
          end
        end
        
        # The bucket's object retention config.
        class ObjectRetention
          include Google::Apis::Core::Hashable
        
          # The bucket's object retention mode. Can be Enabled.
          # Corresponds to the JSON property `mode`
          # @return [String]
          attr_accessor :mode
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @mode = args[:mode] if args.key?(:mode)
          end
        end
        
        # The owner of the bucket. This is always the project team's owner group.
        class Owner
          include Google::Apis::Core::Hashable
        
          # The entity, in the form project-owner-projectId.
          # Corresponds to the JSON property `entity`
          # @return [String]
          attr_accessor :entity
        
          # The ID for the entity.
          # Corresponds to the JSON property `entityId`
          # @return [String]
          attr_accessor :entity_id
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @entity = args[:entity] if args.key?(:entity)
            @entity_id = args[:entity_id] if args.key?(:entity_id)
          end
        end
        
        # The bucket's retention policy. The retention policy enforces a minimum
        # retention time for all objects contained in the bucket, based on their
        # creation time. Any attempt to overwrite or delete objects younger than the
        # retention period will result in a PERMISSION_DENIED error. An unlocked
        # retention policy can be modified or removed from the bucket via a storage.
        # buckets.update operation. A locked retention policy cannot be removed or
        # shortened in duration for the lifetime of the bucket. Attempting to remove or
        # decrease period of a locked retention policy will result in a
        # PERMISSION_DENIED error.
        class RetentionPolicy
          include Google::Apis::Core::Hashable
        
          # Server-determined value that indicates the time from which policy was enforced
          # and effective. This value is in RFC 3339 format.
          # Corresponds to the JSON property `effectiveTime`
          # @return [DateTime]
          attr_accessor :effective_time
        
          # Once locked, an object retention policy cannot be modified.
          # Corresponds to the JSON property `isLocked`
          # @return [Boolean]
          attr_accessor :is_locked
          alias_method :is_locked?, :is_locked
        
          # The duration in seconds that objects need to be retained. Retention duration
          # must be greater than zero and less than 100 years. Note that enforcement of
          # retention periods less than a day is not guaranteed. Such periods should only
          # be used for testing purposes.
          # Corresponds to the JSON property `retentionPeriod`
          # @return [Fixnum]
          attr_accessor :retention_period
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @effective_time = args[:effective_time] if args.key?(:effective_time)
            @is_locked = args[:is_locked] if args.key?(:is_locked)
            @retention_period = args[:retention_period] if args.key?(:retention_period)
          end
        end
        
        # The bucket's soft delete policy, which defines the period of time that soft-
        # deleted objects will be retained, and cannot be permanently deleted.
        class SoftDeletePolicy
          include Google::Apis::Core::Hashable
        
          # Server-determined value that indicates the time from which the policy, or one
          # with a greater retention, was effective. This value is in RFC 3339 format.
          # Corresponds to the JSON property `effectiveTime`
          # @return [DateTime]
          attr_accessor :effective_time
        
          # The duration in seconds that soft-deleted objects in the bucket will be
          # retained and cannot be permanently deleted.
          # Corresponds to the JSON property `retentionDurationSeconds`
          # @return [Fixnum]
          attr_accessor :retention_duration_seconds
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @effective_time = args[:effective_time] if args.key?(:effective_time)
            @retention_duration_seconds = args[:retention_duration_seconds] if args.key?(:retention_duration_seconds)
          end
        end
        
        # The bucket's versioning configuration.
        class Versioning
          include Google::Apis::Core::Hashable
        
          # While set to true, versioning is fully enabled for this bucket.
          # Corresponds to the JSON property `enabled`
          # @return [Boolean]
          attr_accessor :enabled
          alias_method :enabled?, :enabled
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @enabled = args[:enabled] if args.key?(:enabled)
          end
        end
        
        # The bucket's website configuration, controlling how the service behaves when
        # accessing bucket contents as a web site. See the [Static Website Examples](
        # https://cloud.google.com/storage/docs/static-website) for more information.
        class Website
          include Google::Apis::Core::Hashable
        
          # If the requested object path is missing, the service will ensure the path has
          # a trailing '/', append this suffix, and attempt to retrieve the resulting
          # object. This allows the creation of index.html objects to represent directory
          # pages.
          # Corresponds to the JSON property `mainPageSuffix`
          # @return [String]
          attr_accessor :main_page_suffix
        
          # If the requested object path is missing, and any mainPageSuffix object is
          # missing, if applicable, the service will return the named object from this
          # bucket as the content for a 404 Not Found result.
          # Corresponds to the JSON property `notFoundPage`
          # @return [String]
          attr_accessor :not_found_page
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @main_page_suffix = args[:main_page_suffix] if args.key?(:main_page_suffix)
            @not_found_page = args[:not_found_page] if args.key?(:not_found_page)
          end
        end
      end
      
      # An access-control entry.
      class BucketAccessControl
        include Google::Apis::Core::Hashable
      
        # The name of the bucket.
        # Corresponds to the JSON property `bucket`
        # @return [String]
        attr_accessor :bucket
      
        # The domain associated with the entity, if any.
        # Corresponds to the JSON property `domain`
        # @return [String]
        attr_accessor :domain
      
        # The email address associated with the entity, if any.
        # Corresponds to the JSON property `email`
        # @return [String]
        attr_accessor :email
      
        # The entity holding the permission, in one of the following forms:
        # - user-userId
        # - user-email
        # - group-groupId
        # - group-email
        # - domain-domain
        # - project-team-projectId
        # - allUsers
        # - allAuthenticatedUsers Examples:
        # - The user liz@example.com would be user-liz@example.com.
        # - The group example@googlegroups.com would be group-example@googlegroups.com.
        # - To refer to all members of the Google Apps for Business domain example.com,
        # the entity would be domain-example.com.
        # Corresponds to the JSON property `entity`
        # @return [String]
        attr_accessor :entity
      
        # The ID for the entity, if any.
        # Corresponds to the JSON property `entityId`
        # @return [String]
        attr_accessor :entity_id
      
        # HTTP 1.1 Entity tag for the access-control entry.
        # Corresponds to the JSON property `etag`
        # @return [String]
        attr_accessor :etag
      
        # The ID of the access-control entry.
        # Corresponds to the JSON property `id`
        # @return [String]
        attr_accessor :id
      
        # The kind of item this is. For bucket access control entries, this is always
        # storage#bucketAccessControl.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The project team associated with the entity, if any.
        # Corresponds to the JSON property `projectTeam`
        # @return [Google::Apis::StorageV1::BucketAccessControl::ProjectTeam]
        attr_accessor :project_team
      
        # The access permission for the entity.
        # Corresponds to the JSON property `role`
        # @return [String]
        attr_accessor :role
      
        # The link to this access-control entry.
        # Corresponds to the JSON property `selfLink`
        # @return [String]
        attr_accessor :self_link
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @bucket = args[:bucket] if args.key?(:bucket)
          @domain = args[:domain] if args.key?(:domain)
          @email = args[:email] if args.key?(:email)
          @entity = args[:entity] if args.key?(:entity)
          @entity_id = args[:entity_id] if args.key?(:entity_id)
          @etag = args[:etag] if args.key?(:etag)
          @id = args[:id] if args.key?(:id)
          @kind = args[:kind] if args.key?(:kind)
          @project_team = args[:project_team] if args.key?(:project_team)
          @role = args[:role] if args.key?(:role)
          @self_link = args[:self_link] if args.key?(:self_link)
        end
        
        # The project team associated with the entity, if any.
        class ProjectTeam
          include Google::Apis::Core::Hashable
        
          # The project number.
          # Corresponds to the JSON property `projectNumber`
          # @return [String]
          attr_accessor :project_number
        
          # The team.
          # Corresponds to the JSON property `team`
          # @return [String]
          attr_accessor :team
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @project_number = args[:project_number] if args.key?(:project_number)
            @team = args[:team] if args.key?(:team)
          end
        end
      end
      
      # An access-control list.
      class BucketAccessControls
        include Google::Apis::Core::Hashable
      
        # The list of items.
        # Corresponds to the JSON property `items`
        # @return [Array<Google::Apis::StorageV1::BucketAccessControl>]
        attr_accessor :items
      
        # The kind of item this is. For lists of bucket access control entries, this is
        # always storage#bucketAccessControls.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @items = args[:items] if args.key?(:items)
          @kind = args[:kind] if args.key?(:kind)
        end
      end
      
      # The storage layout configuration of a bucket.
      class BucketStorageLayout
        include Google::Apis::Core::Hashable
      
        # The name of the bucket.
        # Corresponds to the JSON property `bucket`
        # @return [String]
        attr_accessor :bucket
      
        # The bucket's custom placement configuration for Custom Dual Regions.
        # Corresponds to the JSON property `customPlacementConfig`
        # @return [Google::Apis::StorageV1::BucketStorageLayout::CustomPlacementConfig]
        attr_accessor :custom_placement_config
      
        # The bucket's hierarchical namespace configuration.
        # Corresponds to the JSON property `hierarchicalNamespace`
        # @return [Google::Apis::StorageV1::BucketStorageLayout::HierarchicalNamespace]
        attr_accessor :hierarchical_namespace
      
        # The kind of item this is. For storage layout, this is always storage#
        # storageLayout.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The location of the bucket.
        # Corresponds to the JSON property `location`
        # @return [String]
        attr_accessor :location
      
        # The type of the bucket location.
        # Corresponds to the JSON property `locationType`
        # @return [String]
        attr_accessor :location_type
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @bucket = args[:bucket] if args.key?(:bucket)
          @custom_placement_config = args[:custom_placement_config] if args.key?(:custom_placement_config)
          @hierarchical_namespace = args[:hierarchical_namespace] if args.key?(:hierarchical_namespace)
          @kind = args[:kind] if args.key?(:kind)
          @location = args[:location] if args.key?(:location)
          @location_type = args[:location_type] if args.key?(:location_type)
        end
        
        # The bucket's custom placement configuration for Custom Dual Regions.
        class CustomPlacementConfig
          include Google::Apis::Core::Hashable
        
          # The list of regional locations in which data is placed.
          # Corresponds to the JSON property `dataLocations`
          # @return [Array<String>]
          attr_accessor :data_locations
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @data_locations = args[:data_locations] if args.key?(:data_locations)
          end
        end
        
        # The bucket's hierarchical namespace configuration.
        class HierarchicalNamespace
          include Google::Apis::Core::Hashable
        
          # When set to true, hierarchical namespace is enabled for this bucket.
          # Corresponds to the JSON property `enabled`
          # @return [Boolean]
          attr_accessor :enabled
          alias_method :enabled?, :enabled
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @enabled = args[:enabled] if args.key?(:enabled)
          end
        end
      end
      
      # A list of buckets.
      class Buckets
        include Google::Apis::Core::Hashable
      
        # The list of items.
        # Corresponds to the JSON property `items`
        # @return [Array<Google::Apis::StorageV1::Bucket>]
        attr_accessor :items
      
        # The kind of item this is. For lists of buckets, this is always storage#buckets.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The continuation token, used to page through large result sets. Provide this
        # value in a subsequent request to return the next page of results.
        # Corresponds to the JSON property `nextPageToken`
        # @return [String]
        attr_accessor :next_page_token
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @items = args[:items] if args.key?(:items)
          @kind = args[:kind] if args.key?(:kind)
          @next_page_token = args[:next_page_token] if args.key?(:next_page_token)
        end
      end
      
      # A bulk restore objects request.
      class BulkRestoreObjectsRequest
        include Google::Apis::Core::Hashable
      
        # If false (default), the restore will not overwrite live objects with the same
        # name at the destination. This means some deleted objects may be skipped. If
        # true, live objects will be overwritten resulting in a noncurrent object (if
        # versioning is enabled). If versioning is not enabled, overwriting the object
        # will result in a soft-deleted object. In either case, if a noncurrent object
        # already exists with the same name, a live version can be written without issue.
        # Corresponds to the JSON property `allowOverwrite`
        # @return [Boolean]
        attr_accessor :allow_overwrite
        alias_method :allow_overwrite?, :allow_overwrite
      
        # If true, copies the source object's ACL; otherwise, uses the bucket's default
        # object ACL. The default is false.
        # Corresponds to the JSON property `copySourceAcl`
        # @return [Boolean]
        attr_accessor :copy_source_acl
        alias_method :copy_source_acl?, :copy_source_acl
      
        # Restores only the objects matching any of the specified glob(s). If this
        # parameter is not specified, all objects will be restored within the specified
        # time range.
        # Corresponds to the JSON property `matchGlobs`
        # @return [Array<String>]
        attr_accessor :match_globs
      
        # Restores only the objects that were soft-deleted after this time.
        # Corresponds to the JSON property `softDeletedAfterTime`
        # @return [DateTime]
        attr_accessor :soft_deleted_after_time
      
        # Restores only the objects that were soft-deleted before this time.
        # Corresponds to the JSON property `softDeletedBeforeTime`
        # @return [DateTime]
        attr_accessor :soft_deleted_before_time
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @allow_overwrite = args[:allow_overwrite] if args.key?(:allow_overwrite)
          @copy_source_acl = args[:copy_source_acl] if args.key?(:copy_source_acl)
          @match_globs = args[:match_globs] if args.key?(:match_globs)
          @soft_deleted_after_time = args[:soft_deleted_after_time] if args.key?(:soft_deleted_after_time)
          @soft_deleted_before_time = args[:soft_deleted_before_time] if args.key?(:soft_deleted_before_time)
        end
      end
      
      # An notification channel used to watch for resource changes.
      class Channel
        include Google::Apis::Core::Hashable
      
        # The address where notifications are delivered for this channel.
        # Corresponds to the JSON property `address`
        # @return [String]
        attr_accessor :address
      
        # Date and time of notification channel expiration, expressed as a Unix
        # timestamp, in milliseconds. Optional.
        # Corresponds to the JSON property `expiration`
        # @return [Fixnum]
        attr_accessor :expiration
      
        # A UUID or similar unique string that identifies this channel.
        # Corresponds to the JSON property `id`
        # @return [String]
        attr_accessor :id
      
        # Identifies this as a notification channel used to watch for changes to a
        # resource, which is "api#channel".
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # Additional parameters controlling delivery channel behavior. Optional.
        # Corresponds to the JSON property `params`
        # @return [Hash<String,String>]
        attr_accessor :params
      
        # A Boolean value to indicate whether payload is wanted. Optional.
        # Corresponds to the JSON property `payload`
        # @return [Boolean]
        attr_accessor :payload
        alias_method :payload?, :payload
      
        # An opaque ID that identifies the resource being watched on this channel.
        # Stable across different API versions.
        # Corresponds to the JSON property `resourceId`
        # @return [String]
        attr_accessor :resource_id
      
        # A version-specific identifier for the watched resource.
        # Corresponds to the JSON property `resourceUri`
        # @return [String]
        attr_accessor :resource_uri
      
        # An arbitrary string delivered to the target address with each notification
        # delivered over this channel. Optional.
        # Corresponds to the JSON property `token`
        # @return [String]
        attr_accessor :token
      
        # The type of delivery mechanism used for this channel.
        # Corresponds to the JSON property `type`
        # @return [String]
        attr_accessor :type
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @address = args[:address] if args.key?(:address)
          @expiration = args[:expiration] if args.key?(:expiration)
          @id = args[:id] if args.key?(:id)
          @kind = args[:kind] if args.key?(:kind)
          @params = args[:params] if args.key?(:params)
          @payload = args[:payload] if args.key?(:payload)
          @resource_id = args[:resource_id] if args.key?(:resource_id)
          @resource_uri = args[:resource_uri] if args.key?(:resource_uri)
          @token = args[:token] if args.key?(:token)
          @type = args[:type] if args.key?(:type)
        end
      end
      
      # A Compose request.
      class ComposeRequest
        include Google::Apis::Core::Hashable
      
        # An object.
        # Corresponds to the JSON property `destination`
        # @return [Google::Apis::StorageV1::Object]
        attr_accessor :destination
      
        # The kind of item this is.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The list of source objects that will be concatenated into a single object.
        # Corresponds to the JSON property `sourceObjects`
        # @return [Array<Google::Apis::StorageV1::ComposeRequest::SourceObject>]
        attr_accessor :source_objects
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @destination = args[:destination] if args.key?(:destination)
          @kind = args[:kind] if args.key?(:kind)
          @source_objects = args[:source_objects] if args.key?(:source_objects)
        end
        
        # 
        class SourceObject
          include Google::Apis::Core::Hashable
        
          # The generation of this object to use as the source.
          # Corresponds to the JSON property `generation`
          # @return [Fixnum]
          attr_accessor :generation
        
          # The source object's name. All source objects must reside in the same bucket.
          # Corresponds to the JSON property `name`
          # @return [String]
          attr_accessor :name
        
          # Conditions that must be met for this operation to execute.
          # Corresponds to the JSON property `objectPreconditions`
          # @return [Google::Apis::StorageV1::ComposeRequest::SourceObject::ObjectPreconditions]
          attr_accessor :object_preconditions
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @generation = args[:generation] if args.key?(:generation)
            @name = args[:name] if args.key?(:name)
            @object_preconditions = args[:object_preconditions] if args.key?(:object_preconditions)
          end
          
          # Conditions that must be met for this operation to execute.
          class ObjectPreconditions
            include Google::Apis::Core::Hashable
          
            # Only perform the composition if the generation of the source object that would
            # be used matches this value. If this value and a generation are both specified,
            # they must be the same value or the call will fail.
            # Corresponds to the JSON property `ifGenerationMatch`
            # @return [Fixnum]
            attr_accessor :if_generation_match
          
            def initialize(**args)
               update!(**args)
            end
          
            # Update properties of this object
            def update!(**args)
              @if_generation_match = args[:if_generation_match] if args.key?(:if_generation_match)
            end
          end
        end
      end
      
      # Represents an expression text. Example: title: "User account presence"
      # description: "Determines whether the request has a user account" expression: "
      # size(request.user) > 0"
      class Expr
        include Google::Apis::Core::Hashable
      
        # An optional description of the expression. This is a longer text which
        # describes the expression, e.g. when hovered over it in a UI.
        # Corresponds to the JSON property `description`
        # @return [String]
        attr_accessor :description
      
        # Textual representation of an expression in Common Expression Language syntax.
        # The application context of the containing message determines which well-known
        # feature set of CEL is supported.
        # Corresponds to the JSON property `expression`
        # @return [String]
        attr_accessor :expression
      
        # An optional string indicating the location of the expression for error
        # reporting, e.g. a file name and a position in the file.
        # Corresponds to the JSON property `location`
        # @return [String]
        attr_accessor :location
      
        # An optional title for the expression, i.e. a short string describing its
        # purpose. This can be used e.g. in UIs which allow to enter the expression.
        # Corresponds to the JSON property `title`
        # @return [String]
        attr_accessor :title
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @description = args[:description] if args.key?(:description)
          @expression = args[:expression] if args.key?(:expression)
          @location = args[:location] if args.key?(:location)
          @title = args[:title] if args.key?(:title)
        end
      end
      
      # A folder. Only available in buckets with hierarchical namespace enabled.
      class Folder
        include Google::Apis::Core::Hashable
      
        # The name of the bucket containing this folder.
        # Corresponds to the JSON property `bucket`
        # @return [String]
        attr_accessor :bucket
      
        # The creation time of the folder in RFC 3339 format.
        # Corresponds to the JSON property `createTime`
        # @return [DateTime]
        attr_accessor :create_time
      
        # The ID of the folder, including the bucket name, folder name.
        # Corresponds to the JSON property `id`
        # @return [String]
        attr_accessor :id
      
        # The kind of item this is. For folders, this is always storage#folder.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The version of the metadata for this folder. Used for preconditions and for
        # detecting changes in metadata.
        # Corresponds to the JSON property `metageneration`
        # @return [Fixnum]
        attr_accessor :metageneration
      
        # The name of the folder. Required if not specified by URL parameter.
        # Corresponds to the JSON property `name`
        # @return [String]
        attr_accessor :name
      
        # Only present if the folder is part of an ongoing rename folder operation.
        # Contains information which can be used to query the operation status.
        # Corresponds to the JSON property `pendingRenameInfo`
        # @return [Google::Apis::StorageV1::Folder::PendingRenameInfo]
        attr_accessor :pending_rename_info
      
        # The link to this folder.
        # Corresponds to the JSON property `selfLink`
        # @return [String]
        attr_accessor :self_link
      
        # The modification time of the folder metadata in RFC 3339 format.
        # Corresponds to the JSON property `updateTime`
        # @return [DateTime]
        attr_accessor :update_time
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @bucket = args[:bucket] if args.key?(:bucket)
          @create_time = args[:create_time] if args.key?(:create_time)
          @id = args[:id] if args.key?(:id)
          @kind = args[:kind] if args.key?(:kind)
          @metageneration = args[:metageneration] if args.key?(:metageneration)
          @name = args[:name] if args.key?(:name)
          @pending_rename_info = args[:pending_rename_info] if args.key?(:pending_rename_info)
          @self_link = args[:self_link] if args.key?(:self_link)
          @update_time = args[:update_time] if args.key?(:update_time)
        end
        
        # Only present if the folder is part of an ongoing rename folder operation.
        # Contains information which can be used to query the operation status.
        class PendingRenameInfo
          include Google::Apis::Core::Hashable
        
          # The ID of the rename folder operation.
          # Corresponds to the JSON property `operationId`
          # @return [String]
          attr_accessor :operation_id
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @operation_id = args[:operation_id] if args.key?(:operation_id)
          end
        end
      end
      
      # A list of folders.
      class Folders
        include Google::Apis::Core::Hashable
      
        # The list of items.
        # Corresponds to the JSON property `items`
        # @return [Array<Google::Apis::StorageV1::Folder>]
        attr_accessor :items
      
        # The kind of item this is. For lists of folders, this is always storage#folders.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The continuation token, used to page through large result sets. Provide this
        # value in a subsequent request to return the next page of results.
        # Corresponds to the JSON property `nextPageToken`
        # @return [String]
        attr_accessor :next_page_token
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @items = args[:items] if args.key?(:items)
          @kind = args[:kind] if args.key?(:kind)
          @next_page_token = args[:next_page_token] if args.key?(:next_page_token)
        end
      end
      
      # The response message for storage.buckets.operations.list.
      class GoogleLongrunningListOperationsResponse
        include Google::Apis::Core::Hashable
      
        # The kind of item this is. For lists of operations, this is always storage#
        # operations.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The continuation token, used to page through large result sets. Provide this
        # value in a subsequent request to return the next page of results.
        # Corresponds to the JSON property `nextPageToken`
        # @return [String]
        attr_accessor :next_page_token
      
        # A list of operations that matches the specified filter in the request.
        # Corresponds to the JSON property `operations`
        # @return [Array<Google::Apis::StorageV1::GoogleLongrunningOperation>]
        attr_accessor :operations
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @kind = args[:kind] if args.key?(:kind)
          @next_page_token = args[:next_page_token] if args.key?(:next_page_token)
          @operations = args[:operations] if args.key?(:operations)
        end
      end
      
      # This resource represents a long-running operation that is the result of a
      # network API call.
      class GoogleLongrunningOperation
        include Google::Apis::Core::Hashable
      
        # If the value is "false", it means the operation is still in progress. If "true"
        # , the operation is completed, and either "error" or "response" is available.
        # Corresponds to the JSON property `done`
        # @return [Boolean]
        attr_accessor :done
        alias_method :done?, :done
      
        # The "Status" type defines a logical error model that is suitable for different
        # programming environments, including REST APIs and RPC APIs. It is used by [
        # gRPC](https://github.com/grpc). Each "Status" message contains three pieces of
        # data: error code, error message, and error details. You can find out more
        # about this error model and how to work with it in the [API Design Guide](https:
        # //cloud.google.com/apis/design/errors).
        # Corresponds to the JSON property `error`
        # @return [Google::Apis::StorageV1::GoogleRpcStatus]
        attr_accessor :error
      
        # The kind of item this is. For operations, this is always storage#operation.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # Service-specific metadata associated with the operation. It typically contains
        # progress information and common metadata such as create time. Some services
        # might not provide such metadata. Any method that returns a long-running
        # operation should document the metadata type, if any.
        # Corresponds to the JSON property `metadata`
        # @return [Hash<String,Object>]
        attr_accessor :metadata
      
        # The server-assigned name, which is only unique within the same service that
        # originally returns it. If you use the default HTTP mapping, the "name" should
        # be a resource name ending with "operations/`operationId`".
        # Corresponds to the JSON property `name`
        # @return [String]
        attr_accessor :name
      
        # The normal response of the operation in case of success. If the original
        # method returns no data on success, such as "Delete", the response is google.
        # protobuf.Empty. If the original method is standard Get/Create/Update, the
        # response should be the resource. For other methods, the response should have
        # the type "XxxResponse", where "Xxx" is the original method name. For example,
        # if the original method name is "TakeSnapshot()", the inferred response type is
        # "TakeSnapshotResponse".
        # Corresponds to the JSON property `response`
        # @return [Hash<String,Object>]
        attr_accessor :response
      
        # The link to this long running operation.
        # Corresponds to the JSON property `selfLink`
        # @return [String]
        attr_accessor :self_link
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @done = args[:done] if args.key?(:done)
          @error = args[:error] if args.key?(:error)
          @kind = args[:kind] if args.key?(:kind)
          @metadata = args[:metadata] if args.key?(:metadata)
          @name = args[:name] if args.key?(:name)
          @response = args[:response] if args.key?(:response)
          @self_link = args[:self_link] if args.key?(:self_link)
        end
      end
      
      # The "Status" type defines a logical error model that is suitable for different
      # programming environments, including REST APIs and RPC APIs. It is used by [
      # gRPC](https://github.com/grpc). Each "Status" message contains three pieces of
      # data: error code, error message, and error details. You can find out more
      # about this error model and how to work with it in the [API Design Guide](https:
      # //cloud.google.com/apis/design/errors).
      class GoogleRpcStatus
        include Google::Apis::Core::Hashable
      
        # The status code, which should be an enum value of google.rpc.Code.
        # Corresponds to the JSON property `code`
        # @return [Fixnum]
        attr_accessor :code
      
        # A list of messages that carry the error details. There is a common set of
        # message types for APIs to use.
        # Corresponds to the JSON property `details`
        # @return [Array<Hash<String,Object>>]
        attr_accessor :details
      
        # A developer-facing error message, which should be in English.
        # Corresponds to the JSON property `message`
        # @return [String]
        attr_accessor :message
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @code = args[:code] if args.key?(:code)
          @details = args[:details] if args.key?(:details)
          @message = args[:message] if args.key?(:message)
        end
      end
      
      # JSON template to produce a JSON-style HMAC Key resource for Create responses.
      class HmacKey
        include Google::Apis::Core::Hashable
      
        # The kind of item this is. For HMAC keys, this is always storage#hmacKey.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # JSON template to produce a JSON-style HMAC Key metadata resource.
        # Corresponds to the JSON property `metadata`
        # @return [Google::Apis::StorageV1::HmacKeyMetadata]
        attr_accessor :metadata
      
        # HMAC secret key material.
        # Corresponds to the JSON property `secret`
        # @return [String]
        attr_accessor :secret
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @kind = args[:kind] if args.key?(:kind)
          @metadata = args[:metadata] if args.key?(:metadata)
          @secret = args[:secret] if args.key?(:secret)
        end
      end
      
      # JSON template to produce a JSON-style HMAC Key metadata resource.
      class HmacKeyMetadata
        include Google::Apis::Core::Hashable
      
        # The ID of the HMAC Key.
        # Corresponds to the JSON property `accessId`
        # @return [String]
        attr_accessor :access_id
      
        # HTTP 1.1 Entity tag for the HMAC key.
        # Corresponds to the JSON property `etag`
        # @return [String]
        attr_accessor :etag
      
        # The ID of the HMAC key, including the Project ID and the Access ID.
        # Corresponds to the JSON property `id`
        # @return [String]
        attr_accessor :id
      
        # The kind of item this is. For HMAC Key metadata, this is always storage#
        # hmacKeyMetadata.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # Project ID owning the service account to which the key authenticates.
        # Corresponds to the JSON property `projectId`
        # @return [String]
        attr_accessor :project_id
      
        # The link to this resource.
        # Corresponds to the JSON property `selfLink`
        # @return [String]
        attr_accessor :self_link
      
        # The email address of the key's associated service account.
        # Corresponds to the JSON property `serviceAccountEmail`
        # @return [String]
        attr_accessor :service_account_email
      
        # The state of the key. Can be one of ACTIVE, INACTIVE, or DELETED.
        # Corresponds to the JSON property `state`
        # @return [String]
        attr_accessor :state
      
        # The creation time of the HMAC key in RFC 3339 format.
        # Corresponds to the JSON property `timeCreated`
        # @return [DateTime]
        attr_accessor :time_created
      
        # The last modification time of the HMAC key metadata in RFC 3339 format.
        # Corresponds to the JSON property `updated`
        # @return [DateTime]
        attr_accessor :updated
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @access_id = args[:access_id] if args.key?(:access_id)
          @etag = args[:etag] if args.key?(:etag)
          @id = args[:id] if args.key?(:id)
          @kind = args[:kind] if args.key?(:kind)
          @project_id = args[:project_id] if args.key?(:project_id)
          @self_link = args[:self_link] if args.key?(:self_link)
          @service_account_email = args[:service_account_email] if args.key?(:service_account_email)
          @state = args[:state] if args.key?(:state)
          @time_created = args[:time_created] if args.key?(:time_created)
          @updated = args[:updated] if args.key?(:updated)
        end
      end
      
      # A list of hmacKeys.
      class HmacKeysMetadata
        include Google::Apis::Core::Hashable
      
        # The list of items.
        # Corresponds to the JSON property `items`
        # @return [Array<Google::Apis::StorageV1::HmacKeyMetadata>]
        attr_accessor :items
      
        # The kind of item this is. For lists of hmacKeys, this is always storage#
        # hmacKeysMetadata.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The continuation token, used to page through large result sets. Provide this
        # value in a subsequent request to return the next page of results.
        # Corresponds to the JSON property `nextPageToken`
        # @return [String]
        attr_accessor :next_page_token
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @items = args[:items] if args.key?(:items)
          @kind = args[:kind] if args.key?(:kind)
          @next_page_token = args[:next_page_token] if args.key?(:next_page_token)
        end
      end
      
      # A managed folder.
      class ManagedFolder
        include Google::Apis::Core::Hashable
      
        # The name of the bucket containing this managed folder.
        # Corresponds to the JSON property `bucket`
        # @return [String]
        attr_accessor :bucket
      
        # The creation time of the managed folder in RFC 3339 format.
        # Corresponds to the JSON property `createTime`
        # @return [DateTime]
        attr_accessor :create_time
      
        # The ID of the managed folder, including the bucket name and managed folder
        # name.
        # Corresponds to the JSON property `id`
        # @return [String]
        attr_accessor :id
      
        # The kind of item this is. For managed folders, this is always storage#
        # managedFolder.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The version of the metadata for this managed folder. Used for preconditions
        # and for detecting changes in metadata.
        # Corresponds to the JSON property `metageneration`
        # @return [Fixnum]
        attr_accessor :metageneration
      
        # The name of the managed folder. Required if not specified by URL parameter.
        # Corresponds to the JSON property `name`
        # @return [String]
        attr_accessor :name
      
        # The link to this managed folder.
        # Corresponds to the JSON property `selfLink`
        # @return [String]
        attr_accessor :self_link
      
        # The last update time of the managed folder metadata in RFC 3339 format.
        # Corresponds to the JSON property `updateTime`
        # @return [DateTime]
        attr_accessor :update_time
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @bucket = args[:bucket] if args.key?(:bucket)
          @create_time = args[:create_time] if args.key?(:create_time)
          @id = args[:id] if args.key?(:id)
          @kind = args[:kind] if args.key?(:kind)
          @metageneration = args[:metageneration] if args.key?(:metageneration)
          @name = args[:name] if args.key?(:name)
          @self_link = args[:self_link] if args.key?(:self_link)
          @update_time = args[:update_time] if args.key?(:update_time)
        end
      end
      
      # A list of managed folders.
      class ManagedFolders
        include Google::Apis::Core::Hashable
      
        # The list of items.
        # Corresponds to the JSON property `items`
        # @return [Array<Google::Apis::StorageV1::ManagedFolder>]
        attr_accessor :items
      
        # The kind of item this is. For lists of managed folders, this is always storage#
        # managedFolders.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The continuation token, used to page through large result sets. Provide this
        # value in a subsequent request to return the next page of results.
        # Corresponds to the JSON property `nextPageToken`
        # @return [String]
        attr_accessor :next_page_token
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @items = args[:items] if args.key?(:items)
          @kind = args[:kind] if args.key?(:kind)
          @next_page_token = args[:next_page_token] if args.key?(:next_page_token)
        end
      end
      
      # A subscription to receive Google PubSub notifications.
      class Notification
        include Google::Apis::Core::Hashable
      
        # An optional list of additional attributes to attach to each Cloud PubSub
        # message published for this notification subscription.
        # Corresponds to the JSON property `custom_attributes`
        # @return [Hash<String,String>]
        attr_accessor :custom_attributes
      
        # HTTP 1.1 Entity tag for this subscription notification.
        # Corresponds to the JSON property `etag`
        # @return [String]
        attr_accessor :etag
      
        # If present, only send notifications about listed event types. If empty, sent
        # notifications for all event types.
        # Corresponds to the JSON property `event_types`
        # @return [Array<String>]
        attr_accessor :event_types
      
        # The ID of the notification.
        # Corresponds to the JSON property `id`
        # @return [String]
        attr_accessor :id
      
        # The kind of item this is. For notifications, this is always storage#
        # notification.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # If present, only apply this notification configuration to object names that
        # begin with this prefix.
        # Corresponds to the JSON property `object_name_prefix`
        # @return [String]
        attr_accessor :object_name_prefix
      
        # The desired content of the Payload.
        # Corresponds to the JSON property `payload_format`
        # @return [String]
        attr_accessor :payload_format
      
        # The canonical URL of this notification.
        # Corresponds to the JSON property `selfLink`
        # @return [String]
        attr_accessor :self_link
      
        # The Cloud PubSub topic to which this subscription publishes. Formatted as: '//
        # pubsub.googleapis.com/projects/`project-identifier`/topics/`my-topic`'
        # Corresponds to the JSON property `topic`
        # @return [String]
        attr_accessor :topic
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @custom_attributes = args[:custom_attributes] if args.key?(:custom_attributes)
          @etag = args[:etag] if args.key?(:etag)
          @event_types = args[:event_types] if args.key?(:event_types)
          @id = args[:id] if args.key?(:id)
          @kind = args[:kind] if args.key?(:kind)
          @object_name_prefix = args[:object_name_prefix] if args.key?(:object_name_prefix)
          @payload_format = args[:payload_format] if args.key?(:payload_format)
          @self_link = args[:self_link] if args.key?(:self_link)
          @topic = args[:topic] if args.key?(:topic)
        end
      end
      
      # A list of notification subscriptions.
      class Notifications
        include Google::Apis::Core::Hashable
      
        # The list of items.
        # Corresponds to the JSON property `items`
        # @return [Array<Google::Apis::StorageV1::Notification>]
        attr_accessor :items
      
        # The kind of item this is. For lists of notifications, this is always storage#
        # notifications.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @items = args[:items] if args.key?(:items)
          @kind = args[:kind] if args.key?(:kind)
        end
      end
      
      # An object.
      class Object
        include Google::Apis::Core::Hashable
      
        # Access controls on the object.
        # Corresponds to the JSON property `acl`
        # @return [Array<Google::Apis::StorageV1::ObjectAccessControl>]
        attr_accessor :acl
      
        # The name of the bucket containing this object.
        # Corresponds to the JSON property `bucket`
        # @return [String]
        attr_accessor :bucket
      
        # Cache-Control directive for the object data. If omitted, and the object is
        # accessible to all anonymous users, the default will be public, max-age=3600.
        # Corresponds to the JSON property `cacheControl`
        # @return [String]
        attr_accessor :cache_control
      
        # Number of underlying components that make up this object. Components are
        # accumulated by compose operations.
        # Corresponds to the JSON property `componentCount`
        # @return [Fixnum]
        attr_accessor :component_count
      
        # Content-Disposition of the object data.
        # Corresponds to the JSON property `contentDisposition`
        # @return [String]
        attr_accessor :content_disposition
      
        # Content-Encoding of the object data.
        # Corresponds to the JSON property `contentEncoding`
        # @return [String]
        attr_accessor :content_encoding
      
        # Content-Language of the object data.
        # Corresponds to the JSON property `contentLanguage`
        # @return [String]
        attr_accessor :content_language
      
        # Content-Type of the object data. If an object is stored without a Content-Type,
        # it is served as application/octet-stream.
        # Corresponds to the JSON property `contentType`
        # @return [String]
        attr_accessor :content_type
      
        # CRC32c checksum, as described in RFC 4960, Appendix B; encoded using base64 in
        # big-endian byte order. For more information about using the CRC32c checksum,
        # see [Data Validation and Change Detection](https://cloud.google.com/storage/
        # docs/data-validation).
        # Corresponds to the JSON property `crc32c`
        # @return [String]
        attr_accessor :crc32c
      
        # A timestamp in RFC 3339 format specified by the user for an object.
        # Corresponds to the JSON property `customTime`
        # @return [DateTime]
        attr_accessor :custom_time
      
        # Metadata of customer-supplied encryption key, if the object is encrypted by
        # such a key.
        # Corresponds to the JSON property `customerEncryption`
        # @return [Google::Apis::StorageV1::Object::CustomerEncryption]
        attr_accessor :customer_encryption
      
        # HTTP 1.1 Entity tag for the object.
        # Corresponds to the JSON property `etag`
        # @return [String]
        attr_accessor :etag
      
        # Whether an object is under event-based hold. Event-based hold is a way to
        # retain objects until an event occurs, which is signified by the hold's release
        # (i.e. this value is set to false). After being released (set to false), such
        # objects will be subject to bucket-level retention (if any). One sample use
        # case of this flag is for banks to hold loan documents for at least 3 years
        # after loan is paid in full. Here, bucket-level retention is 3 years and the
        # event is the loan being paid in full. In this example, these objects will be
        # held intact for any number of years until the event has occurred (event-based
        # hold on the object is released) and then 3 more years after that. That means
        # retention duration of the objects begins from the moment event-based hold
        # transitioned from true to false.
        # Corresponds to the JSON property `eventBasedHold`
        # @return [Boolean]
        attr_accessor :event_based_hold
        alias_method :event_based_hold?, :event_based_hold
      
        # The content generation of this object. Used for object versioning.
        # Corresponds to the JSON property `generation`
        # @return [Fixnum]
        attr_accessor :generation
      
        # This is the time (in the future) when the soft-deleted object will no longer
        # be restorable. It is equal to the soft delete time plus the current soft
        # delete retention duration of the bucket.
        # Corresponds to the JSON property `hardDeleteTime`
        # @return [DateTime]
        attr_accessor :hard_delete_time
      
        # The ID of the object, including the bucket name, object name, and generation
        # number.
        # Corresponds to the JSON property `id`
        # @return [String]
        attr_accessor :id
      
        # The kind of item this is. For objects, this is always storage#object.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # Not currently supported. Specifying the parameter causes the request to fail
        # with status code 400 - Bad Request.
        # Corresponds to the JSON property `kmsKeyName`
        # @return [String]
        attr_accessor :kms_key_name
      
        # MD5 hash of the data; encoded using base64. For more information about using
        # the MD5 hash, see [Data Validation and Change Detection](https://cloud.google.
        # com/storage/docs/data-validation).
        # Corresponds to the JSON property `md5Hash`
        # @return [String]
        attr_accessor :md5_hash
      
        # Media download link.
        # Corresponds to the JSON property `mediaLink`
        # @return [String]
        attr_accessor :media_link
      
        # User-provided metadata, in key/value pairs.
        # Corresponds to the JSON property `metadata`
        # @return [Hash<String,String>]
        attr_accessor :metadata
      
        # The version of the metadata for this object at this generation. Used for
        # preconditions and for detecting changes in metadata. A metageneration number
        # is only meaningful in the context of a particular generation of a particular
        # object.
        # Corresponds to the JSON property `metageneration`
        # @return [Fixnum]
        attr_accessor :metageneration
      
        # The name of the object. Required if not specified by URL parameter.
        # Corresponds to the JSON property `name`
        # @return [String]
        attr_accessor :name
      
        # The owner of the object. This will always be the uploader of the object.
        # Corresponds to the JSON property `owner`
        # @return [Google::Apis::StorageV1::Object::Owner]
        attr_accessor :owner
      
        # Restore token used to differentiate deleted objects with the same name and
        # generation. This field is only returned for deleted objects in hierarchical
        # namespace buckets.
        # Corresponds to the JSON property `restoreToken`
        # @return [String]
        attr_accessor :restore_token
      
        # A collection of object level retention parameters.
        # Corresponds to the JSON property `retention`
        # @return [Google::Apis::StorageV1::Object::Retention]
        attr_accessor :retention
      
        # A server-determined value that specifies the earliest time that the object's
        # retention period expires. This value is in RFC 3339 format. Note 1: This field
        # is not provided for objects with an active event-based hold, since retention
        # expiration is unknown until the hold is removed. Note 2: This value can be
        # provided even when temporary hold is set (so that the user can reason about
        # policy without having to first unset the temporary hold).
        # Corresponds to the JSON property `retentionExpirationTime`
        # @return [DateTime]
        attr_accessor :retention_expiration_time
      
        # The link to this object.
        # Corresponds to the JSON property `selfLink`
        # @return [String]
        attr_accessor :self_link
      
        # Content-Length of the data in bytes.
        # Corresponds to the JSON property `size`
        # @return [Fixnum]
        attr_accessor :size
      
        # The time at which the object became soft-deleted in RFC 3339 format.
        # Corresponds to the JSON property `softDeleteTime`
        # @return [DateTime]
        attr_accessor :soft_delete_time
      
        # Storage class of the object.
        # Corresponds to the JSON property `storageClass`
        # @return [String]
        attr_accessor :storage_class
      
        # Whether an object is under temporary hold. While this flag is set to true, the
        # object is protected against deletion and overwrites. A common use case of this
        # flag is regulatory investigations where objects need to be retained while the
        # investigation is ongoing. Note that unlike event-based hold, temporary hold
        # does not impact retention expiration time of an object.
        # Corresponds to the JSON property `temporaryHold`
        # @return [Boolean]
        attr_accessor :temporary_hold
        alias_method :temporary_hold?, :temporary_hold
      
        # The creation time of the object in RFC 3339 format.
        # Corresponds to the JSON property `timeCreated`
        # @return [DateTime]
        attr_accessor :time_created
      
        # The time at which the object became noncurrent in RFC 3339 format. Will be
        # returned if and only if this version of the object has been deleted.
        # Corresponds to the JSON property `timeDeleted`
        # @return [DateTime]
        attr_accessor :time_deleted
      
        # The time at which the object's storage class was last changed. When the object
        # is initially created, it will be set to timeCreated.
        # Corresponds to the JSON property `timeStorageClassUpdated`
        # @return [DateTime]
        attr_accessor :time_storage_class_updated
      
        # The modification time of the object metadata in RFC 3339 format. Set initially
        # to object creation time and then updated whenever any metadata of the object
        # changes. This includes changes made by a requester, such as modifying custom
        # metadata, as well as changes made by Cloud Storage on behalf of a requester,
        # such as changing the storage class based on an Object Lifecycle Configuration.
        # Corresponds to the JSON property `updated`
        # @return [DateTime]
        attr_accessor :updated
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @acl = args[:acl] if args.key?(:acl)
          @bucket = args[:bucket] if args.key?(:bucket)
          @cache_control = args[:cache_control] if args.key?(:cache_control)
          @component_count = args[:component_count] if args.key?(:component_count)
          @content_disposition = args[:content_disposition] if args.key?(:content_disposition)
          @content_encoding = args[:content_encoding] if args.key?(:content_encoding)
          @content_language = args[:content_language] if args.key?(:content_language)
          @content_type = args[:content_type] if args.key?(:content_type)
          @crc32c = args[:crc32c] if args.key?(:crc32c)
          @custom_time = args[:custom_time] if args.key?(:custom_time)
          @customer_encryption = args[:customer_encryption] if args.key?(:customer_encryption)
          @etag = args[:etag] if args.key?(:etag)
          @event_based_hold = args[:event_based_hold] if args.key?(:event_based_hold)
          @generation = args[:generation] if args.key?(:generation)
          @hard_delete_time = args[:hard_delete_time] if args.key?(:hard_delete_time)
          @id = args[:id] if args.key?(:id)
          @kind = args[:kind] if args.key?(:kind)
          @kms_key_name = args[:kms_key_name] if args.key?(:kms_key_name)
          @md5_hash = args[:md5_hash] if args.key?(:md5_hash)
          @media_link = args[:media_link] if args.key?(:media_link)
          @metadata = args[:metadata] if args.key?(:metadata)
          @metageneration = args[:metageneration] if args.key?(:metageneration)
          @name = args[:name] if args.key?(:name)
          @owner = args[:owner] if args.key?(:owner)
          @restore_token = args[:restore_token] if args.key?(:restore_token)
          @retention = args[:retention] if args.key?(:retention)
          @retention_expiration_time = args[:retention_expiration_time] if args.key?(:retention_expiration_time)
          @self_link = args[:self_link] if args.key?(:self_link)
          @size = args[:size] if args.key?(:size)
          @soft_delete_time = args[:soft_delete_time] if args.key?(:soft_delete_time)
          @storage_class = args[:storage_class] if args.key?(:storage_class)
          @temporary_hold = args[:temporary_hold] if args.key?(:temporary_hold)
          @time_created = args[:time_created] if args.key?(:time_created)
          @time_deleted = args[:time_deleted] if args.key?(:time_deleted)
          @time_storage_class_updated = args[:time_storage_class_updated] if args.key?(:time_storage_class_updated)
          @updated = args[:updated] if args.key?(:updated)
        end
        
        # Metadata of customer-supplied encryption key, if the object is encrypted by
        # such a key.
        class CustomerEncryption
          include Google::Apis::Core::Hashable
        
          # The encryption algorithm.
          # Corresponds to the JSON property `encryptionAlgorithm`
          # @return [String]
          attr_accessor :encryption_algorithm
        
          # SHA256 hash value of the encryption key.
          # Corresponds to the JSON property `keySha256`
          # @return [String]
          attr_accessor :key_sha256
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @encryption_algorithm = args[:encryption_algorithm] if args.key?(:encryption_algorithm)
            @key_sha256 = args[:key_sha256] if args.key?(:key_sha256)
          end
        end
        
        # The owner of the object. This will always be the uploader of the object.
        class Owner
          include Google::Apis::Core::Hashable
        
          # The entity, in the form user-userId.
          # Corresponds to the JSON property `entity`
          # @return [String]
          attr_accessor :entity
        
          # The ID for the entity.
          # Corresponds to the JSON property `entityId`
          # @return [String]
          attr_accessor :entity_id
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @entity = args[:entity] if args.key?(:entity)
            @entity_id = args[:entity_id] if args.key?(:entity_id)
          end
        end
        
        # A collection of object level retention parameters.
        class Retention
          include Google::Apis::Core::Hashable
        
          # The bucket's object retention mode, can only be Unlocked or Locked.
          # Corresponds to the JSON property `mode`
          # @return [String]
          attr_accessor :mode
        
          # A time in RFC 3339 format until which object retention protects this object.
          # Corresponds to the JSON property `retainUntilTime`
          # @return [DateTime]
          attr_accessor :retain_until_time
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @mode = args[:mode] if args.key?(:mode)
            @retain_until_time = args[:retain_until_time] if args.key?(:retain_until_time)
          end
        end
      end
      
      # An access-control entry.
      class ObjectAccessControl
        include Google::Apis::Core::Hashable
      
        # The name of the bucket.
        # Corresponds to the JSON property `bucket`
        # @return [String]
        attr_accessor :bucket
      
        # The domain associated with the entity, if any.
        # Corresponds to the JSON property `domain`
        # @return [String]
        attr_accessor :domain
      
        # The email address associated with the entity, if any.
        # Corresponds to the JSON property `email`
        # @return [String]
        attr_accessor :email
      
        # The entity holding the permission, in one of the following forms:
        # - user-userId
        # - user-email
        # - group-groupId
        # - group-email
        # - domain-domain
        # - project-team-projectId
        # - allUsers
        # - allAuthenticatedUsers Examples:
        # - The user liz@example.com would be user-liz@example.com.
        # - The group example@googlegroups.com would be group-example@googlegroups.com.
        # - To refer to all members of the Google Apps for Business domain example.com,
        # the entity would be domain-example.com.
        # Corresponds to the JSON property `entity`
        # @return [String]
        attr_accessor :entity
      
        # The ID for the entity, if any.
        # Corresponds to the JSON property `entityId`
        # @return [String]
        attr_accessor :entity_id
      
        # HTTP 1.1 Entity tag for the access-control entry.
        # Corresponds to the JSON property `etag`
        # @return [String]
        attr_accessor :etag
      
        # The content generation of the object, if applied to an object.
        # Corresponds to the JSON property `generation`
        # @return [Fixnum]
        attr_accessor :generation
      
        # The ID of the access-control entry.
        # Corresponds to the JSON property `id`
        # @return [String]
        attr_accessor :id
      
        # The kind of item this is. For object access control entries, this is always
        # storage#objectAccessControl.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The name of the object, if applied to an object.
        # Corresponds to the JSON property `object`
        # @return [String]
        attr_accessor :object
      
        # The project team associated with the entity, if any.
        # Corresponds to the JSON property `projectTeam`
        # @return [Google::Apis::StorageV1::ObjectAccessControl::ProjectTeam]
        attr_accessor :project_team
      
        # The access permission for the entity.
        # Corresponds to the JSON property `role`
        # @return [String]
        attr_accessor :role
      
        # The link to this access-control entry.
        # Corresponds to the JSON property `selfLink`
        # @return [String]
        attr_accessor :self_link
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @bucket = args[:bucket] if args.key?(:bucket)
          @domain = args[:domain] if args.key?(:domain)
          @email = args[:email] if args.key?(:email)
          @entity = args[:entity] if args.key?(:entity)
          @entity_id = args[:entity_id] if args.key?(:entity_id)
          @etag = args[:etag] if args.key?(:etag)
          @generation = args[:generation] if args.key?(:generation)
          @id = args[:id] if args.key?(:id)
          @kind = args[:kind] if args.key?(:kind)
          @object = args[:object] if args.key?(:object)
          @project_team = args[:project_team] if args.key?(:project_team)
          @role = args[:role] if args.key?(:role)
          @self_link = args[:self_link] if args.key?(:self_link)
        end
        
        # The project team associated with the entity, if any.
        class ProjectTeam
          include Google::Apis::Core::Hashable
        
          # The project number.
          # Corresponds to the JSON property `projectNumber`
          # @return [String]
          attr_accessor :project_number
        
          # The team.
          # Corresponds to the JSON property `team`
          # @return [String]
          attr_accessor :team
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @project_number = args[:project_number] if args.key?(:project_number)
            @team = args[:team] if args.key?(:team)
          end
        end
      end
      
      # An access-control list.
      class ObjectAccessControls
        include Google::Apis::Core::Hashable
      
        # The list of items.
        # Corresponds to the JSON property `items`
        # @return [Array<Google::Apis::StorageV1::ObjectAccessControl>]
        attr_accessor :items
      
        # The kind of item this is. For lists of object access control entries, this is
        # always storage#objectAccessControls.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @items = args[:items] if args.key?(:items)
          @kind = args[:kind] if args.key?(:kind)
        end
      end
      
      # A list of objects.
      class Objects
        include Google::Apis::Core::Hashable
      
        # The list of items.
        # Corresponds to the JSON property `items`
        # @return [Array<Google::Apis::StorageV1::Object>]
        attr_accessor :items
      
        # The kind of item this is. For lists of objects, this is always storage#objects.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The continuation token, used to page through large result sets. Provide this
        # value in a subsequent request to return the next page of results.
        # Corresponds to the JSON property `nextPageToken`
        # @return [String]
        attr_accessor :next_page_token
      
        # The list of prefixes of objects matching-but-not-listed up to and including
        # the requested delimiter.
        # Corresponds to the JSON property `prefixes`
        # @return [Array<String>]
        attr_accessor :prefixes
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @items = args[:items] if args.key?(:items)
          @kind = args[:kind] if args.key?(:kind)
          @next_page_token = args[:next_page_token] if args.key?(:next_page_token)
          @prefixes = args[:prefixes] if args.key?(:prefixes)
        end
      end
      
      # A bucket/object/managedFolder IAM policy.
      class Policy
        include Google::Apis::Core::Hashable
      
        # An association between a role, which comes with a set of permissions, and
        # members who may assume that role.
        # Corresponds to the JSON property `bindings`
        # @return [Array<Google::Apis::StorageV1::Policy::Binding>]
        attr_accessor :bindings
      
        # HTTP 1.1  Entity tag for the policy.
        # Corresponds to the JSON property `etag`
        # NOTE: Values are automatically base64 encoded/decoded in the client library.
        # @return [String]
        attr_accessor :etag
      
        # The kind of item this is. For policies, this is always storage#policy. This
        # field is ignored on input.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The ID of the resource to which this policy belongs. Will be of the form
        # projects/_/buckets/bucket for buckets, projects/_/buckets/bucket/objects/
        # object for objects, and projects/_/buckets/bucket/managedFolders/managedFolder.
        # A specific generation may be specified by appending #generationNumber to the
        # end of the object name, e.g. projects/_/buckets/my-bucket/objects/data.txt#17.
        # The current generation can be denoted with #0. This field is ignored on input.
        # Corresponds to the JSON property `resourceId`
        # @return [String]
        attr_accessor :resource_id
      
        # The IAM policy format version.
        # Corresponds to the JSON property `version`
        # @return [Fixnum]
        attr_accessor :version
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @bindings = args[:bindings] if args.key?(:bindings)
          @etag = args[:etag] if args.key?(:etag)
          @kind = args[:kind] if args.key?(:kind)
          @resource_id = args[:resource_id] if args.key?(:resource_id)
          @version = args[:version] if args.key?(:version)
        end
        
        # 
        class Binding
          include Google::Apis::Core::Hashable
        
          # Represents an expression text. Example: title: "User account presence"
          # description: "Determines whether the request has a user account" expression: "
          # size(request.user) > 0"
          # Corresponds to the JSON property `condition`
          # @return [Google::Apis::StorageV1::Expr]
          attr_accessor :condition
        
          # A collection of identifiers for members who may assume the provided role.
          # Recognized identifiers are as follows:
          # - allUsers — A special identifier that represents anyone on the internet; with
          # or without a Google account.
          # - allAuthenticatedUsers — A special identifier that represents anyone who is
          # authenticated with a Google account or a service account.
          # - user:emailid — An email address that represents a specific account. For
          # example, user:alice@gmail.com or user:joe@example.com.
          # - serviceAccount:emailid — An email address that represents a service account.
          # For example,  serviceAccount:my-other-app@appspot.gserviceaccount.com .
          # - group:emailid — An email address that represents a Google group. For example,
          # group:admins@example.com.
          # - domain:domain — A Google Apps domain name that represents all the users of
          # that domain. For example, domain:google.com or domain:example.com.
          # - projectOwner:projectid — Owners of the given project. For example,
          # projectOwner:my-example-project
          # - projectEditor:projectid — Editors of the given project. For example,
          # projectEditor:my-example-project
          # - projectViewer:projectid — Viewers of the given project. For example,
          # projectViewer:my-example-project
          # Corresponds to the JSON property `members`
          # @return [Array<String>]
          attr_accessor :members
        
          # The role to which members belong. Two types of roles are supported: new IAM
          # roles, which grant permissions that do not map directly to those provided by
          # ACLs, and legacy IAM roles, which do map directly to ACL permissions. All
          # roles are of the format roles/storage.specificRole.
          # The new IAM roles are:
          # - roles/storage.admin — Full control of Google Cloud Storage resources.
          # - roles/storage.objectViewer — Read-Only access to Google Cloud Storage
          # objects.
          # - roles/storage.objectCreator — Access to create objects in Google Cloud
          # Storage.
          # - roles/storage.objectAdmin — Full control of Google Cloud Storage objects.
          # The legacy IAM roles are:
          # - roles/storage.legacyObjectReader — Read-only access to objects without
          # listing. Equivalent to an ACL entry on an object with the READER role.
          # - roles/storage.legacyObjectOwner — Read/write access to existing objects
          # without listing. Equivalent to an ACL entry on an object with the OWNER role.
          # - roles/storage.legacyBucketReader — Read access to buckets with object
          # listing. Equivalent to an ACL entry on a bucket with the READER role.
          # - roles/storage.legacyBucketWriter — Read access to buckets with object
          # listing/creation/deletion. Equivalent to an ACL entry on a bucket with the
          # WRITER role.
          # - roles/storage.legacyBucketOwner — Read and write access to existing buckets
          # with object listing/creation/deletion. Equivalent to an ACL entry on a bucket
          # with the OWNER role.
          # Corresponds to the JSON property `role`
          # @return [String]
          attr_accessor :role
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @condition = args[:condition] if args.key?(:condition)
            @members = args[:members] if args.key?(:members)
            @role = args[:role] if args.key?(:role)
          end
        end
      end
      
      # A Relocate Bucket request.
      class RelocateBucketRequest
        include Google::Apis::Core::Hashable
      
        # The bucket's new custom placement configuration if relocating to a Custom Dual
        # Region.
        # Corresponds to the JSON property `destinationCustomPlacementConfig`
        # @return [Google::Apis::StorageV1::RelocateBucketRequest::DestinationCustomPlacementConfig]
        attr_accessor :destination_custom_placement_config
      
        # The new location the bucket will be relocated to.
        # Corresponds to the JSON property `destinationLocation`
        # @return [String]
        attr_accessor :destination_location
      
        # If true, validate the operation, but do not actually relocate the bucket.
        # Corresponds to the JSON property `validateOnly`
        # @return [Boolean]
        attr_accessor :validate_only
        alias_method :validate_only?, :validate_only
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @destination_custom_placement_config = args[:destination_custom_placement_config] if args.key?(:destination_custom_placement_config)
          @destination_location = args[:destination_location] if args.key?(:destination_location)
          @validate_only = args[:validate_only] if args.key?(:validate_only)
        end
        
        # The bucket's new custom placement configuration if relocating to a Custom Dual
        # Region.
        class DestinationCustomPlacementConfig
          include Google::Apis::Core::Hashable
        
          # The list of regional locations in which data is placed.
          # Corresponds to the JSON property `dataLocations`
          # @return [Array<String>]
          attr_accessor :data_locations
        
          def initialize(**args)
             update!(**args)
          end
        
          # Update properties of this object
          def update!(**args)
            @data_locations = args[:data_locations] if args.key?(:data_locations)
          end
        end
      end
      
      # A rewrite response.
      class RewriteResponse
        include Google::Apis::Core::Hashable
      
        # true if the copy is finished; otherwise, false if the copy is in progress.
        # This property is always present in the response.
        # Corresponds to the JSON property `done`
        # @return [Boolean]
        attr_accessor :done
        alias_method :done?, :done
      
        # The kind of item this is.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The total size of the object being copied in bytes. This property is always
        # present in the response.
        # Corresponds to the JSON property `objectSize`
        # @return [Fixnum]
        attr_accessor :object_size
      
        # An object.
        # Corresponds to the JSON property `resource`
        # @return [Google::Apis::StorageV1::Object]
        attr_accessor :resource
      
        # A token to use in subsequent requests to continue copying data. This token is
        # present in the response only when there is more data to copy.
        # Corresponds to the JSON property `rewriteToken`
        # @return [String]
        attr_accessor :rewrite_token
      
        # The total bytes written so far, which can be used to provide a waiting user
        # with a progress indicator. This property is always present in the response.
        # Corresponds to the JSON property `totalBytesRewritten`
        # @return [Fixnum]
        attr_accessor :total_bytes_rewritten
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @done = args[:done] if args.key?(:done)
          @kind = args[:kind] if args.key?(:kind)
          @object_size = args[:object_size] if args.key?(:object_size)
          @resource = args[:resource] if args.key?(:resource)
          @rewrite_token = args[:rewrite_token] if args.key?(:rewrite_token)
          @total_bytes_rewritten = args[:total_bytes_rewritten] if args.key?(:total_bytes_rewritten)
        end
      end
      
      # A subscription to receive Google PubSub notifications.
      class ServiceAccount
        include Google::Apis::Core::Hashable
      
        # The ID of the notification.
        # Corresponds to the JSON property `email_address`
        # @return [String]
        attr_accessor :email_address
      
        # The kind of item this is. For notifications, this is always storage#
        # notification.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @email_address = args[:email_address] if args.key?(:email_address)
          @kind = args[:kind] if args.key?(:kind)
        end
      end
      
      # A storage.(buckets|objects|managedFolders).testIamPermissions response.
      class TestIamPermissionsResponse
        include Google::Apis::Core::Hashable
      
        # The kind of item this is.
        # Corresponds to the JSON property `kind`
        # @return [String]
        attr_accessor :kind
      
        # The permissions held by the caller. Permissions are always of the format
        # storage.resource.capability, where resource is one of buckets, objects, or
        # managedFolders. The supported permissions are as follows:
        # - storage.buckets.delete — Delete bucket.
        # - storage.buckets.get — Read bucket metadata.
        # - storage.buckets.getIamPolicy — Read bucket IAM policy.
        # - storage.buckets.create — Create bucket.
        # - storage.buckets.list — List buckets.
        # - storage.buckets.setIamPolicy — Update bucket IAM policy.
        # - storage.buckets.update — Update bucket metadata.
        # - storage.objects.delete — Delete object.
        # - storage.objects.get — Read object data and metadata.
        # - storage.objects.getIamPolicy — Read object IAM policy.
        # - storage.objects.create — Create object.
        # - storage.objects.list — List objects.
        # - storage.objects.setIamPolicy — Update object IAM policy.
        # - storage.objects.update — Update object metadata.
        # - storage.managedFolders.delete — Delete managed folder.
        # - storage.managedFolders.get — Read managed folder metadata.
        # - storage.managedFolders.getIamPolicy — Read managed folder IAM policy.
        # - storage.managedFolders.create — Create managed folder.
        # - storage.managedFolders.list — List managed folders.
        # - storage.managedFolders.setIamPolicy — Update managed folder IAM policy.
        # Corresponds to the JSON property `permissions`
        # @return [Array<String>]
        attr_accessor :permissions
      
        def initialize(**args)
           update!(**args)
        end
      
        # Update properties of this object
        def update!(**args)
          @kind = args[:kind] if args.key?(:kind)
          @permissions = args[:permissions] if args.key?(:permissions)
        end
      end
    end
  end
end
