# frozen_string_literal: true

module ActsAsTaggableOn
  module Taggable
    module TaggedWithQuery
      class ExcludeTagsQuery < QueryBase
        def build
          taggable_model.joins(owning_to_tagger)
                        .where(tags_not_in_list)
                        .having(tags_that_matches_count)
                        .readonly(false)
        end

        private

        def tags_not_in_list
          taggable_arel_table[:id].not_in(
            tagging_arel_table
              .project(tagging_arel_table[:taggable_id])
              .join(tag_arel_table)
              .on(
                tagging_arel_table[:tag_id].eq(tag_arel_table[:id])
                .and(tagging_arel_table[:taggable_type].eq(taggable_model.base_class.name))
                .and(tags_match_type)
              )
          )

          # FIXME: missing time scope, this is also missing in the original implementation
        end

        def owning_to_tagger
          return [] if options[:owned_by].blank?

          owner = options[:owned_by]

          arel_join = taggable_arel_table
                      .join(tagging_arel_table)
                      .on(
                        tagging_arel_table[:tagger_id].eq(owner.id)
                        .and(tagging_arel_table[:tagger_type].eq(owner.class.base_class.to_s))
                        .and(tagging_arel_table[:taggable_id].eq(taggable_arel_table[taggable_model.primary_key]))
                        .and(tagging_arel_table[:taggable_type].eq(taggable_model.base_class.name))
                      )

          if options[:match_all].present?
            arel_join = arel_join
                        .join(tagging_arel_table, Arel::Nodes::OuterJoin)
                        .on(
                          match_all_on_conditions
                        )
          end

          arel_join.join_sources
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

        def tags_that_matches_count
          return [] if options[:match_all].blank?

          taggable_model.find_by_sql(tag_arel_table.project(Arel.star.count).where(tags_match_type).to_sql)

          tagging_arel_table[:taggable_id].count.eq(
            tag_arel_table.project(Arel.star.count).where(tags_match_type)
          )
        end
      end
    end
  end
end
