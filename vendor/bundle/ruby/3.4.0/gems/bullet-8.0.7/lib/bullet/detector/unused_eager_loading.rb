# frozen_string_literal: true

using Bullet::Ext::Object
using Bullet::Ext::String

module Bullet
  module Detector
    class UnusedEagerLoading < Association
      extend Dependency
      extend StackTraceFilter

      class << self
        # check if there are unused preload associations.
        #   get related_objects from eager_loadings associated with object and associations
        #   get call_object_association from associations of call_object_associations whose object is in related_objects
        #   if association not in call_object_association, then the object => association - call_object_association is unused preload associations
        def check_unused_preload_associations
          return unless Bullet.start?
          return unless Bullet.unused_eager_loading_enable?

          object_associations.each do |bullet_key, associations|
            object_association_diff = diff_object_associations bullet_key, associations
            next if object_association_diff.empty?

            Bullet.debug('detect unused preload', "object: #{bullet_key}, associations: #{object_association_diff}")
            create_notification(caller_in_project(bullet_key), bullet_key.bullet_class_name, object_association_diff)
          end
        end

        def add_eager_loadings(objects, associations)
          return unless Bullet.start?
          return unless Bullet.unused_eager_loading_enable?
          return if objects.map(&:bullet_primary_key_value).compact.empty?

          Bullet.debug(
            'Detector::UnusedEagerLoading#add_eager_loadings',
            "objects: #{objects.map(&:bullet_key).join(', ')}, associations: #{associations}"
          )
          bullet_keys = objects.map(&:bullet_key)

          to_add = []
          to_merge = []
          to_delete = []
          eager_loadings.each do |k, _v|
            key_objects_overlap = k & bullet_keys

            next if key_objects_overlap.empty?

            bullet_keys -= k
            if key_objects_overlap == k
              to_add << [k, associations]
            else
              to_merge << [key_objects_overlap, (eager_loadings[k].dup << associations)]

              keys_without_objects = k - key_objects_overlap
              to_merge << [keys_without_objects, eager_loadings[k]]
              to_delete << k
            end
          end

          to_add.each { |k, val| eager_loadings.add k, val }
          to_merge.each { |k, val| eager_loadings.merge k, val }
          to_delete.each { |k| eager_loadings.delete k }

          eager_loadings.add bullet_keys, associations unless bullet_keys.empty?
        end

        private

        def create_notification(callers, klazz, associations)
          notify_associations = Array.wrap(associations) - Bullet.get_safelist_associations(
            :unused_eager_loading,
            klazz
          )

          if notify_associations.present?
            notice = Bullet::Notification::UnusedEagerLoading.new(callers, klazz, notify_associations)
            Bullet.notification_collector.add(notice)
          end
        end

        def call_associations(bullet_key, associations)
          all = Set.new
          eager_loadings.similarly_associated(bullet_key, associations).each do |related_bullet_key|
            coa = call_object_associations[related_bullet_key]
            next if coa.nil?

            all.merge coa
          end
          all.to_a
        end

        def diff_object_associations(bullet_key, associations)
          potential_associations = associations - call_associations(bullet_key, associations)
          potential_associations.reject { |a| a.is_a?(Hash) }
        end
      end
    end
  end
end
