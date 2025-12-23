# frozen_string_literal: true

module ActsAsTaggableOn
  module Taggable
    module Related
      def self.included(base)
        base.extend ActsAsTaggableOn::Taggable::Related::ClassMethods
        base.initialize_acts_as_taggable_on_related
      end

      module ClassMethods
        def initialize_acts_as_taggable_on_related
          tag_types.map(&:to_s).each do |tag_type|
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def find_related_#{tag_type}(options = {})
              related_tags_for('#{tag_type}', self.class, options)
            end
            alias_method :find_related_on_#{tag_type}, :find_related_#{tag_type}

            def find_related_#{tag_type}_for(klass, options = {})
              related_tags_for('#{tag_type}', klass, options)
            end
            RUBY
          end
        end

        def acts_as_taggable_on(*args)
          super(*args)
          initialize_acts_as_taggable_on_related
        end
      end

      def find_matching_contexts(search_context, result_context, options = {})
        matching_contexts_for(search_context.to_s, result_context.to_s, self.class, options)
      end

      def find_matching_contexts_for(klass, search_context, result_context, options = {})
        matching_contexts_for(search_context.to_s, result_context.to_s, klass, options)
      end

      def matching_contexts_for(search_context, result_context, klass, _options = {})
        tags_to_find = tags_on(search_context).map(&:name)
        related_where(klass,
                      [
                        "#{exclude_self(klass,
                                        id)} #{klass.table_name}.#{klass.primary_key} = #{ActsAsTaggableOn::Tagging.table_name}.taggable_id AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_type = '#{klass.base_class}' AND #{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.#{ActsAsTaggableOn::Tag.primary_key} AND #{ActsAsTaggableOn::Tag.table_name}.name IN (?) AND #{ActsAsTaggableOn::Tagging.table_name}.context = ?", tags_to_find, result_context
                      ])
      end

      def related_tags_for(context, klass, options = {})
        tags_to_ignore = Array.wrap(options[:ignore]).map(&:to_s) || []
        tags_to_find = tags_on(context).map(&:name).reject { |t| tags_to_ignore.include? t }
        related_where(klass,
                      [
                        "#{exclude_self(klass,
                                        id)} #{klass.table_name}.#{klass.primary_key} = #{ActsAsTaggableOn::Tagging.table_name}.taggable_id AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_type = '#{klass.base_class}' AND #{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.#{ActsAsTaggableOn::Tag.primary_key} AND #{ActsAsTaggableOn::Tag.table_name}.name IN (?) AND #{ActsAsTaggableOn::Tagging.table_name}.context = ?", tags_to_find, context
                      ])
      end

      private

      def exclude_self(klass, id)
        "#{klass.arel_table[klass.primary_key].not_eq(id).to_sql} AND" if [self.class.base_class,
                                                                           self.class].include? klass
      end

      def group_columns(klass)
        if ActsAsTaggableOn::Utils.using_postgresql?
          grouped_column_names_for(klass)
        else
          "#{klass.table_name}.#{klass.primary_key}"
        end
      end

      def related_where(klass, conditions)
        klass.select("#{klass.table_name}.*, COUNT(#{ActsAsTaggableOn::Tag.table_name}.#{ActsAsTaggableOn::Tag.primary_key}) AS count")
             .from("#{klass.table_name}, #{ActsAsTaggableOn::Tag.table_name}, #{ActsAsTaggableOn::Tagging.table_name}")
             .group(group_columns(klass))
             .order('count DESC')
             .where(conditions)
      end
    end
  end
end
