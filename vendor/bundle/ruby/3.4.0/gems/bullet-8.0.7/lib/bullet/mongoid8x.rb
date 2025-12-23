module Bullet
  module Mongoid
    def self.enable
      require 'mongoid'
      ::Mongoid::Contextual::Mongo.class_eval do
        alias_method :origin_first, :first
        alias_method :origin_last, :last
        alias_method :origin_each, :each
        alias_method :origin_eager_load, :eager_load

        def first(limit = nil)
          result = origin_first(limit)
          Bullet::Detector::NPlusOneQuery.add_impossible_object(result) if result
          result
        end

        def last(limit = nil)
          result = origin_last(limit)
          Bullet::Detector::NPlusOneQuery.add_impossible_object(result) if result
          result
        end

        def each(&block)
          return to_enum unless block_given?

          records = []
          origin_each { |record| records << record }
          if records.length > 1
            Bullet::Detector::NPlusOneQuery.add_possible_objects(records)
          elsif records.size == 1
            Bullet::Detector::NPlusOneQuery.add_impossible_object(records.first)
          end
          records.each(&block)
        end

        def eager_load(docs)
          associations = criteria.inclusions.map(&:name)
          docs.each do |doc|
            Bullet::Detector::NPlusOneQuery.add_object_associations(doc, associations)
          end
          Bullet::Detector::UnusedEagerLoading.add_eager_loadings(docs, associations)
          origin_eager_load(docs)
        end
      end

      ::Mongoid::Association::Accessors.class_eval do
        alias_method :origin_get_relation, :get_relation

        def get_relation(name, association, object, reload = false)
          result = origin_get_relation(name, association, object, reload)
          unless association.embedded?
            Bullet::Detector::NPlusOneQuery.call_association(self, name)
          end
          result
        end
      end
    end
  end
end
