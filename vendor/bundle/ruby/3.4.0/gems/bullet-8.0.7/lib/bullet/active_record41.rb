# frozen_string_literal: true

module Bullet
  module ActiveRecord
    def self.enable
      require 'active_record'
      ::ActiveRecord::Base.class_eval do
        class << self
          alias_method :origin_find_by_sql, :find_by_sql
          def find_by_sql(sql, binds = [])
            result = origin_find_by_sql(sql, binds)
            if Bullet.start?
              if result.is_a? Array
                if result.size > 1
                  Bullet::Detector::NPlusOneQuery.add_possible_objects(result)
                  Bullet::Detector::CounterCache.add_possible_objects(result)
                elsif result.size == 1
                  Bullet::Detector::NPlusOneQuery.add_impossible_object(result.first)
                  Bullet::Detector::CounterCache.add_impossible_object(result.first)
                end
              elsif result.is_a? ::ActiveRecord::Base
                Bullet::Detector::NPlusOneQuery.add_impossible_object(result)
                Bullet::Detector::CounterCache.add_impossible_object(result)
              end
            end
            result
          end
        end
      end

      ::ActiveRecord::Relation.class_eval do
        alias_method :origin_to_a, :to_a

        # if select a collection of objects, then these objects have possible to cause N+1 query.
        # if select only one object, then the only one object has impossible to cause N+1 query.
        def to_a
          records = origin_to_a
          if Bullet.start?
            if records.first.class.name !~ /^HABTM_/
              if records.size > 1
                Bullet::Detector::NPlusOneQuery.add_possible_objects(records)
                Bullet::Detector::CounterCache.add_possible_objects(records)
              elsif records.size == 1
                Bullet::Detector::NPlusOneQuery.add_impossible_object(records.first)
                Bullet::Detector::CounterCache.add_impossible_object(records.first)
              end
            end
          end
          records
        end
      end

      ::ActiveRecord::Persistence.class_eval do
        def _create_record_with_bullet(*args)
          _create_record_without_bullet(*args).tap do
            Bullet::Detector::NPlusOneQuery.update_inversed_object(self)
            Bullet::Detector::NPlusOneQuery.add_impossible_object(self)
          end
        end
        alias_method_chain :_create_record, :bullet
      end

      ::ActiveRecord::Associations::Preloader.class_eval do
        alias_method :origin_preloaders_on, :preloaders_on

        def preloaders_on(association, records, scope)
          if Bullet.start?
            records.compact!
            if records.first.class.name !~ /^HABTM_/
              records.each { |record| Bullet::Detector::Association.add_object_associations(record, association) }
              Bullet::Detector::UnusedEagerLoading.add_eager_loadings(records, association)
            end
          end
          origin_preloaders_on(association, records, scope)
        end
      end

      ::ActiveRecord::FinderMethods.class_eval do
        # add includes in scope
        alias_method :origin_find_with_associations, :find_with_associations
        def find_with_associations
          return origin_find_with_associations { |r| yield r } if block_given?

          records = origin_find_with_associations
          if Bullet.start?
            associations = (eager_load_values + includes_values).uniq
            records.each { |record| Bullet::Detector::Association.add_object_associations(record, associations) }
            Bullet::Detector::UnusedEagerLoading.add_eager_loadings(records, associations)
          end
          records
        end
      end

      ::ActiveRecord::Associations::JoinDependency.class_eval do
        alias_method :origin_instantiate, :instantiate
        alias_method :origin_construct_model, :construct_model

        def instantiate(result_set, aliases)
          @bullet_eager_loadings = {}
          records = origin_instantiate(result_set, aliases)

          if Bullet.start?
            @bullet_eager_loadings.each do |_klazz, eager_loadings_hash|
              objects = eager_loadings_hash.keys
              Bullet::Detector::UnusedEagerLoading.add_eager_loadings(objects, eager_loadings_hash[objects.first].to_a)
            end
          end
          records
        end

        # call join associations
        def construct_model(record, node, row, model_cache, id, aliases)
          result = origin_construct_model(record, node, row, model_cache, id, aliases)

          if Bullet.start?
            associations = [node.reflection.name]
            if node.reflection.nested?
              associations << node.reflection.through_reflection.name
            end
            associations.each do |association|
              Bullet::Detector::Association.add_object_associations(record, association)
              Bullet::Detector::NPlusOneQuery.call_association(record, association)
              @bullet_eager_loadings[record.class] ||= {}
              @bullet_eager_loadings[record.class][record] ||= Set.new
              @bullet_eager_loadings[record.class][record] << association
            end
          end

          result
        end
      end

      ::ActiveRecord::Associations::CollectionAssociation.class_eval do
        # call one to many associations
        alias_method :origin_load_target, :load_target
        def load_target
          Bullet::Detector::NPlusOneQuery.call_association(@owner, @reflection.name) if Bullet.start? && !@inversed
          origin_load_target
        end

        alias_method :origin_empty?, :empty?
        def empty?
          if Bullet.start? && !has_cached_counter?(@reflection)
            Bullet::Detector::NPlusOneQuery.call_association(@owner, @reflection.name)
          end
          origin_empty?
        end

        alias_method :origin_include?, :include?
        def include?(object)
          Bullet::Detector::NPlusOneQuery.call_association(@owner, @reflection.name) if Bullet.start?
          origin_include?(object)
        end
      end

      ::ActiveRecord::Associations::SingularAssociation.class_eval do
        # call has_one and belongs_to associations
        alias_method :origin_reader, :reader
        def reader(force_reload = false)
          result = origin_reader(force_reload)
          if Bullet.start?
            if @owner.class.name !~ /^HABTM_/ && !@inversed
              Bullet::Detector::NPlusOneQuery.call_association(@owner, @reflection.name)
              Bullet::Detector::NPlusOneQuery.add_possible_objects(result)
            end
          end
          result
        end
      end

      ::ActiveRecord::Associations::HasManyAssociation.class_eval do
        alias_method :origin_count_records, :count_records
        def count_records
          result = has_cached_counter?
          Bullet::Detector::CounterCache.add_counter_cache(@owner, @reflection.name) if Bullet.start? && !result
          origin_count_records
        end
      end

      ::ActiveRecord::Associations::CollectionProxy.class_eval do
        def count(column_name = nil, options = {})
          if Bullet.start?
            Bullet::Detector::CounterCache.add_counter_cache(proxy_association.owner, proxy_association.reflection.name)
            Bullet::Detector::NPlusOneQuery.call_association(proxy_association.owner, proxy_association.reflection.name)
          end
          super(column_name, options)
        end
      end
    end
  end
end
