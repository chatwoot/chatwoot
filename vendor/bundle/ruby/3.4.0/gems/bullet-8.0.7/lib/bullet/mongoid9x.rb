# frozen_string_literal: true

module Bullet
  module Mongoid
    def self.enable
      require 'mongoid'
      require 'rubygems'
      ::Mongoid::Contextual::Mongo.class_eval do
        alias_method :origin_first, :first
        alias_method :origin_last, :last
        alias_method :origin_each, :each
        alias_method :origin_eager_load, :eager_load

        %i[first last].each do |context|
          default = Gem::Version.new(::Mongoid::VERSION) >= Gem::Version.new('7.5') ? nil : {}
          define_method(context) do |opts = default|
            result = send(:"origin_#{context}", opts)
            Bullet::Detector::NPlusOneQuery.add_impossible_object(result) if result
            result
          end
        end

        def each(&_block)
          return to_enum unless block_given?

          first_document = nil
          document_count = 0

          origin_each do |document|
            document_count += 1

            if document_count == 1
              first_document = document
            elsif document_count == 2
              Bullet::Detector::NPlusOneQuery.add_possible_objects([first_document, document])
              yield(first_document)
              first_document = nil
              yield(document)
            else
              Bullet::Detector::NPlusOneQuery.add_possible_objects(document)
              yield(document)
            end
          end

          if document_count == 1
            Bullet::Detector::NPlusOneQuery.add_impossible_object(first_document)
            yield(first_document)
          end

          self
        end

        def eager_load(docs)
          associations = criteria.inclusions.map(&:name)
          docs.each { |doc| Bullet::Detector::NPlusOneQuery.add_object_associations(doc, associations) }
          Bullet::Detector::UnusedEagerLoading.add_eager_loadings(docs, associations)
          origin_eager_load(docs)
        end
      end

      ::Mongoid::Association::Accessors.class_eval do
        alias_method :origin_get_relation, :get_relation

        def get_relation(name, association, object, reload = false)
          result = origin_get_relation(name, association, object, reload)
          Bullet::Detector::NPlusOneQuery.call_association(self, name) unless association.embedded?
          result
        end
      end
    end
  end
end
