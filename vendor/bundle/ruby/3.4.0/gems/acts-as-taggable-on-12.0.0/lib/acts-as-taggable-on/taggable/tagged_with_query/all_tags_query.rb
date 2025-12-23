# frozen_string_literal: true

module ActsAsTaggableOn
  module Taggable
    module TaggedWithQuery
      class AllTagsQuery < QueryBase
        def build
          taggable_model.joins(each_tag_in_list)
                        .group(by_taggable)
                        .having(tags_that_matches_count)
                        .order(order_conditions)
                        .readonly(false)
        end

        private

        def each_tag_in_list
          arel_join = taggable_arel_table

          tag_list.each do |tag|
            tagging_alias = tagging_arel_table.alias(tagging_alias(tag))
            arel_join = arel_join
                        .join(tagging_alias)
                        .on(on_conditions(tag, tagging_alias))
          end

          if options[:match_all].present?
            arel_join = arel_join
                        .join(tagging_arel_table, Arel::Nodes::OuterJoin)
                        .on(
                          match_all_on_conditions
                        )
          end

          arel_join.join_sources
        end

        def on_conditions(tag, tagging_alias)
          on_condition = tagging_alias[:taggable_id].eq(taggable_arel_table[taggable_model.primary_key])
                                                    .and(tagging_alias[:taggable_type].eq(taggable_model.base_class.name))
                                                    .and(
                                                      tagging_alias[:tag_id].in(
                                                        tag_arel_table.project(tag_arel_table[:id]).where(tag_match_type(tag))
                                                      )
                                                    )

          if options[:start_at].present?
            on_condition = on_condition.and(tagging_alias[:created_at].gteq(options[:start_at]))
          end

          if options[:end_at].present?
            on_condition = on_condition.and(tagging_alias[:created_at].lteq(options[:end_at]))
          end

          on_condition = on_condition.and(tagging_alias[:context].eq(options[:on])) if options[:on].present?

          if (owner = options[:owned_by]).present?
            on_condition = on_condition.and(tagging_alias[:tagger_id].eq(owner.id))
                                       .and(tagging_alias[:tagger_type].eq(owner.class.base_class.to_s))
          end

          on_condition
        end

        def match_all_on_conditions
          on_condition = tagging_arel_table[:taggable_id].eq(taggable_arel_table[taggable_model.primary_key])
                                                         .and(tagging_arel_table[:taggable_type].eq(taggable_model.base_class.name))

          if options[:start_at].present?
            on_condition = on_condition.and(tagging_arel_table[:created_at].gteq(options[:start_at]))
          end

          if options[:end_at].present?
            on_condition = on_condition.and(tagging_arel_table[:created_at].lteq(options[:end_at]))
          end

          on_condition = on_condition.and(tagging_arel_table[:context].eq(options[:on])) if options[:on].present?

          on_condition
        end

        def by_taggable
          return [] if options[:match_all].blank?

          taggable_arel_table[taggable_model.primary_key]
        end

        def tags_that_matches_count
          return [] if options[:match_all].blank?

          taggable_model.find_by_sql(tag_arel_table.project(Arel.star.count).where(tags_match_type).to_sql)

          tagging_arel_table[:taggable_id].count.eq(
            tag_arel_table.project(Arel.star.count).where(tags_match_type)
          )
        end

        def order_conditions
          order_by = []
          if options[:order_by_matching_tag_count].present? && options[:match_all].blank?
            order_by << tagging_arel_table.project(tagging_arel_table[Arel.star].count.as('taggings_count')).order('taggings_count DESC').to_sql
          end

          order_by << options[:order] if options[:order].present?
          order_by.join(', ')
        end

        def tagging_alias(tag)
          alias_base_name = taggable_model.base_class.name.downcase
          adjust_taggings_alias("#{alias_base_name[0..11]}_taggings_#{ActsAsTaggableOn::Utils.sha_prefix(tag)}")
        end
      end
    end
  end
end
