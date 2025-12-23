# frozen_string_literal: true

using Bullet::Ext::Object

module Bullet
  module Detector
    class NPlusOneQuery < Association
      extend Dependency
      extend StackTraceFilter

      class << self
        # executed when object.associations is called.
        # first, it keeps this method call for object.association.
        # then, it checks if this associations call is unpreload.
        #   if it is, keeps this unpreload associations and caller.
        def call_association(object, associations)
          return unless Bullet.start?
          return unless Bullet.n_plus_one_query_enable?
          return unless object.bullet_primary_key_value
          return if inversed_objects.include?(object.bullet_key, associations)

          add_call_object_associations(object, associations)

          Bullet.debug(
            'Detector::NPlusOneQuery#call_association',
            "object: #{object.bullet_key}, associations: #{associations}"
          )
          if !excluded_stacktrace_path? && conditions_met?(object, associations)
            Bullet.debug('detect n + 1 query', "object: #{object.bullet_key}, associations: #{associations}")
            create_notification(caller_in_project(object.bullet_key), object.class.to_s, associations)
          end
        end

        def add_possible_objects(object_or_objects)
          return unless Bullet.start?
          return unless Bullet.n_plus_one_query_enable?

          objects = Array.wrap(object_or_objects)
          class_names_match_regex = true
          primary_key_values_are_empty = true

          keys_joined = objects.map do |obj|
            unless obj.class.name =~ /^HABTM_/
              class_names_match_regex = false
            end
            unless obj.bullet_primary_key_value.nil?
              primary_key_values_are_empty = false
            end
            obj.bullet_key
          end.join(", ")

          unless class_names_match_regex || primary_key_values_are_empty
            Bullet.debug('Detector::NPlusOneQuery#add_possible_objects', "objects: #{keys_joined}")
            objects.each { |object| possible_objects.add object.bullet_key }
          end
        end

        def add_impossible_object(object)
          return unless Bullet.start?
          return unless Bullet.n_plus_one_query_enable?
          return unless object.bullet_primary_key_value

          Bullet.debug('Detector::NPlusOneQuery#add_impossible_object', "object: #{object.bullet_key}")
          impossible_objects.add object.bullet_key
        end

        def add_inversed_object(object, association)
          return unless Bullet.start?
          return unless Bullet.n_plus_one_query_enable?

          object_key = object.bullet_primary_key_value ? object.bullet_key : object.object_id
          Bullet.debug(
            'Detector::NPlusOneQuery#add_inversed_object',
            "object: #{object_key}, association: #{association}"
          )
          inversed_objects.add object_key, association
        end

        def update_inversed_object(object)
          if inversed_objects&.key?(object.object_id)
            Bullet.debug(
              'Detector::NPlusOneQuery#update_inversed_object',
              "object from #{object.object_id} to #{object.bullet_key}"
            )
            inversed_objects.add(object.bullet_key, inversed_objects[object.object_id].to_a)
          end
        end

        # decide whether the object.associations is unpreloaded or not.
        def conditions_met?(object, associations)
          possible?(object) && !impossible?(object) && !association?(object, associations)
        end

        def possible?(object)
          possible_objects.include? object.bullet_key
        end

        def impossible?(object)
          impossible_objects.include? object.bullet_key
        end

        # check if object => associations already exists in object_associations.
        def association?(object, associations)
          value = object_associations[object.bullet_key]
          value&.each do |v|
            # associations == v comparison order is important here because
            # v variable might be a squeel node where :== method is redefined,
            # so it does not compare values at all and return unexpected results
            result = v.is_a?(Hash) ? v.key?(associations) : associations == v
            return true if result
          end

          false
        end

        private

        def create_notification(callers, klazz, associations)
          notify_associations = Array.wrap(associations) - Bullet.get_safelist_associations(:n_plus_one_query, klazz)

          if notify_associations.present?
            notice = Bullet::Notification::NPlusOneQuery.new(callers, klazz, notify_associations)
            Bullet.notification_collector.add(notice)
          end
        end
      end
    end
  end
end
