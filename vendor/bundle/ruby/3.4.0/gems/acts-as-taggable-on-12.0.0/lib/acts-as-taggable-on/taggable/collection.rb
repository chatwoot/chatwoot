# frozen_string_literal: true

module ActsAsTaggableOn
  module Taggable
    module Collection
      extend ActiveSupport::Concern

      included do
        initialize_acts_as_taggable_on_collection
      end

      class_methods do
        def initialize_acts_as_taggable_on_collection
          tag_types.map(&:to_s).each do |tag_type|
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def self.#{tag_type.singularize}_counts(options={})
              tag_counts_on('#{tag_type}', options)
            end

            def #{tag_type.singularize}_counts(options = {})
              tag_counts_on('#{tag_type}', options)
            end

            def top_#{tag_type}(limit = 10)
              tag_counts_on('#{tag_type}', order: 'count desc', limit: limit.to_i)
            end

            def self.top_#{tag_type}(limit = 10)
              tag_counts_on('#{tag_type}', order: 'count desc', limit: limit.to_i)
            end
            RUBY
          end
        end

        def acts_as_taggable_on(*args)
          super(*args)
          initialize_acts_as_taggable_on_collection
        end

        def tag_counts_on(context, options = {})
          all_tag_counts(options.merge({ on: context.to_s }))
        end

        def tags_on(context, options = {})
          all_tags(options.merge({ on: context.to_s }))
        end

        ##
        # Calculate the tag names.
        # To be used when you don't need tag counts and want to avoid the taggable joins.
        #
        # @param [Hash] options Options:
        #                       * :start_at   - Restrict the tags to those created after a certain time
        #                       * :end_at     - Restrict the tags to those created before a certain time
        #                       * :conditions - A piece of SQL conditions to add to the query. Note we don't join the taggable objects for performance reasons.
        #                       * :limit      - The maximum number of tags to return
        #                       * :order      - A piece of SQL to order by. Eg 'tags.count desc' or 'taggings.created_at desc'
        #                       * :on         - Scope the find to only include a certain context
        def all_tags(options = {})
          options = options.dup
          options.assert_valid_keys :start_at, :end_at, :conditions, :order, :limit, :on

          ## Generate conditions:
          options[:conditions] = sanitize_sql(options[:conditions]) if options[:conditions]

          ## Generate scope:
          tagging_scope = ActsAsTaggableOn::Tagging.select("#{ActsAsTaggableOn::Tagging.table_name}.tag_id")
          tag_scope = ActsAsTaggableOn::Tag.select("#{ActsAsTaggableOn::Tag.table_name}.*").order(options[:order]).limit(options[:limit])

          # Joins and conditions
          tagging_conditions(options).each { |condition| tagging_scope = tagging_scope.where(condition) }
          tag_scope = tag_scope.where(options[:conditions])

          group_columns = "#{ActsAsTaggableOn::Tagging.table_name}.tag_id"

          # Append the current scope to the scope, because we can't use scope(:find) in RoR 3.0 anymore:
          tagging_scope = generate_tagging_scope_in_clause(tagging_scope, table_name, primary_key).group(group_columns)

          tag_scope_joins(tag_scope, tagging_scope)
        end

        ##
        # Calculate the tag counts for all tags.
        #
        # @param [Hash] options Options:
        #                       * :start_at   - Restrict the tags to those created after a certain time
        #                       * :end_at     - Restrict the tags to those created before a certain time
        #                       * :conditions - A piece of SQL conditions to add to the query
        #                       * :limit      - The maximum number of tags to return
        #                       * :order      - A piece of SQL to order by. Eg 'tags.count desc' or 'taggings.created_at desc'
        #                       * :at_least   - Exclude tags with a frequency less than the given value
        #                       * :at_most    - Exclude tags with a frequency greater than the given value
        #                       * :on         - Scope the find to only include a certain context
        def all_tag_counts(options = {})
          options = options.dup
          options.assert_valid_keys :start_at, :end_at, :conditions, :at_least, :at_most, :order, :limit, :on, :id

          ## Generate conditions:
          options[:conditions] = sanitize_sql(options[:conditions]) if options[:conditions]

          ## Generate scope:
          tagging_scope = ActsAsTaggableOn::Tagging.select("#{ActsAsTaggableOn::Tagging.table_name}.tag_id, COUNT(#{ActsAsTaggableOn::Tagging.table_name}.tag_id) AS tags_count")
          tag_scope = ActsAsTaggableOn::Tag.select("#{ActsAsTaggableOn::Tag.table_name}.*, #{ActsAsTaggableOn::Tagging.table_name}.tags_count AS count").order(options[:order]).limit(options[:limit])

          # Current model is STI descendant, so add type checking to the join condition
          unless descends_from_active_record?
            taggable_join = "INNER JOIN #{table_name} ON #{table_name}.#{primary_key} = #{ActsAsTaggableOn::Tagging.table_name}.taggable_id"
            taggable_join =  taggable_join + " AND #{table_name}.#{inheritance_column} = '#{name}'"
            tagging_scope = tagging_scope.joins(taggable_join)
          end

          # Conditions
          tagging_conditions(options).each { |condition| tagging_scope = tagging_scope.where(condition) }
          tag_scope = tag_scope.where(options[:conditions])

          # GROUP BY and HAVING clauses:
          having = ["COUNT(#{ActsAsTaggableOn::Tagging.table_name}.tag_id) > 0"]
          if options[:at_least]
            having.push sanitize_sql(["COUNT(#{ActsAsTaggableOn::Tagging.table_name}.tag_id) >= ?",
                                      options.delete(:at_least)])
          end
          if options[:at_most]
            having.push sanitize_sql(["COUNT(#{ActsAsTaggableOn::Tagging.table_name}.tag_id) <= ?",
                                      options.delete(:at_most)])
          end
          having = having.compact.join(' AND ')

          group_columns = "#{ActsAsTaggableOn::Tagging.table_name}.tag_id"

          unless options[:id]
            # Append the current scope to the scope, because we can't use scope(:find) in RoR 3.0 anymore:
            tagging_scope = generate_tagging_scope_in_clause(tagging_scope, table_name, primary_key)
          end

          tagging_scope = tagging_scope.group(group_columns).having(having)

          tag_scope_joins(tag_scope, tagging_scope)
        end

        def safe_to_sql(relation)
          if connection.respond_to?(:unprepared_statement)
            connection.unprepared_statement do
              relation.to_sql
            end
          else
            relation.to_sql
          end
        end

        private

        def generate_tagging_scope_in_clause(tagging_scope, table_name, primary_key)
          table_name_pkey = "#{table_name}.#{primary_key}"
          if ActsAsTaggableOn::Utils.using_mysql?
            # See https://github.com/mbleigh/acts-as-taggable-on/pull/457 for details
            scoped_ids = pluck(table_name_pkey)
            tagging_scope = tagging_scope.where("#{ActsAsTaggableOn::Tagging.table_name}.taggable_id IN (?)",
                                                scoped_ids)
          else
            tagging_scope = tagging_scope.where("#{ActsAsTaggableOn::Tagging.table_name}.taggable_id IN(#{safe_to_sql(except(:select).select(table_name_pkey))})")
          end

          tagging_scope
        end

        def tagging_conditions(options)
          tagging_conditions = []
          if options[:end_at]
            tagging_conditions.push sanitize_sql(["#{ActsAsTaggableOn::Tagging.table_name}.created_at <= ?",
                                                  options.delete(:end_at)])
          end
          if options[:start_at]
            tagging_conditions.push sanitize_sql(["#{ActsAsTaggableOn::Tagging.table_name}.created_at >= ?",
                                                  options.delete(:start_at)])
          end

          taggable_conditions = sanitize_sql(["#{ActsAsTaggableOn::Tagging.table_name}.taggable_type = ?",
                                              base_class.name])
          if options[:on]
            taggable_conditions << sanitize_sql([" AND #{ActsAsTaggableOn::Tagging.table_name}.context = ?",
                                                 options.delete(:on).to_s])
          end

          if options[:id]
            taggable_conditions << if options[:id].is_a? Array
                                     sanitize_sql([" AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_id IN (?)",
                                                   options[:id]])
                                   else
                                     sanitize_sql([" AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_id = ?",
                                                   options[:id]])
                                   end
          end

          tagging_conditions.push taggable_conditions

          tagging_conditions
        end

        def tag_scope_joins(tag_scope, tagging_scope)
          tag_scope = tag_scope.joins("JOIN (#{safe_to_sql(tagging_scope)}) AS #{ActsAsTaggableOn::Tagging.table_name} ON #{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.id")
          tag_scope.extending(CalculationMethods)
        end
      end

      def tag_counts_on(context, options = {})
        self.class.tag_counts_on(context, options.merge(id: id))
      end

      module CalculationMethods
        # Rails 5 TODO: Remove options argument as soon we remove support to
        # activerecord-deprecated_finders.
        # See https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/calculations.rb#L38
        def count(column_name = :all, _options = {})
          # https://github.com/rails/rails/commit/da9b5d4a8435b744fcf278fffd6d7f1e36d4a4f2
          super(column_name)
        end
      end
    end
  end
end
