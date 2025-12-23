# frozen_string_literal: true

using Bullet::Ext::Object

module Bullet
  module Detector
    class Association < Base
      class << self
        def add_object_associations(object, associations)
          return unless Bullet.start?
          return if !Bullet.n_plus_one_query_enable? && !Bullet.unused_eager_loading_enable?
          return unless object.bullet_primary_key_value

          Bullet.debug(
            'Detector::Association#add_object_associations',
            "object: #{object.bullet_key}, associations: #{associations}"
          )
          call_stacks.add(object.bullet_key)
          object_associations.add(object.bullet_key, associations)
        end

        def add_call_object_associations(object, associations)
          return unless Bullet.start?
          return if !Bullet.n_plus_one_query_enable? && !Bullet.unused_eager_loading_enable?
          return unless object.bullet_primary_key_value

          Bullet.debug(
            'Detector::Association#add_call_object_associations',
            "object: #{object.bullet_key}, associations: #{associations}"
          )
          call_stacks.add(object.bullet_key)
          call_object_associations.add(object.bullet_key, associations)
        end

        # possible_objects keep the class to object relationships
        # that the objects may cause N+1 query.
        # e.g. { Post => ["Post:1", "Post:2"] }
        def possible_objects
          Thread.current.thread_variable_get(:bullet_possible_objects)
        end

        # impossible_objects keep the class to objects relationships
        # that the objects may not cause N+1 query.
        # e.g. { Post => ["Post:1", "Post:2"] }
        # if find collection returns only one object, then the object is impossible object,
        # impossible_objects are used to avoid treating 1+1 query to N+1 query.
        def impossible_objects
          Thread.current.thread_variable_get(:bullet_impossible_objects)
        end

        private

        # object_associations keep the object relationships
        # that the object has many associations.
        # e.g. { "Post:1" => [:comments] }
        # the object_associations keep all associations that may be or may no be
        # unpreload associations or unused preload associations.
        def object_associations
          Thread.current.thread_variable_get(:bullet_object_associations)
        end

        # call_object_associations keep the object relationships
        # that object.associations is called.
        # e.g. { "Post:1" => [:comments] }
        # they are used to detect unused preload associations.
        def call_object_associations
          Thread.current.thread_variable_get(:bullet_call_object_associations)
        end

        # inversed_objects keeps object relationships
        # that association is inversed.
        # e.g. { "Comment:1" => ["post"] }
        def inversed_objects
          Thread.current.thread_variable_get(:bullet_inversed_objects)
        end

        # eager_loadings keep the object relationships
        # that the associations are preloaded by find :include.
        # e.g. { ["Post:1", "Post:2"] => [:comments, :user] }
        def eager_loadings
          Thread.current.thread_variable_get(:bullet_eager_loadings)
        end

        # call_stacks keeps stacktraces where querie-objects were called from.
        # e.g. { 'Object:111' => [SomeProject/app/controllers/...] }
        def call_stacks
          Thread.current.thread_variable_get(:bullet_call_stacks)
        end
      end
    end
  end
end
