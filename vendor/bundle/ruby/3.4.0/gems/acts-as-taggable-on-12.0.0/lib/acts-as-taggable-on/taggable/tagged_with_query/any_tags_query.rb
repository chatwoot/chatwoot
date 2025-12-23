# frozen_string_literal: true

module ActsAsTaggableOn
  module Taggable
    module TaggedWithQuery
      class AnyTagsQuery < QueryBase
        def build
          taggable_model.select(all_fields)
                        .where(model_has_at_least_one_tag)
                        .order(Arel.sql(order_conditions))
                        .readonly(false)
        end

        private

        def all_fields
          taggable_arel_table[Arel.star]
        end

        def model_has_at_least_one_tag
          tagging_arel_table.project(Arel.star).where(at_least_one_tag).exists
        end

        def at_least_one_tag
          exists_contition = tagging_arel_table[:taggable_id].eq(taggable_arel_table[taggable_model.primary_key])
                                                             .and(tagging_arel_table[:taggable_type].eq(taggable_model.base_class.name))
                                                             .and(
                                                               tagging_arel_table[:tag_id].in(
                                                                 tag_arel_table.project(tag_arel_table[:id]).where(tags_match_type)
                                                               )
                                                             )

          if options[:start_at].present?
            exists_contition = exists_contition.and(tagging_arel_table[:created_at].gteq(options[:start_at]))
          end

          if options[:end_at].present?
            exists_contition = exists_contition.and(tagging_arel_table[:created_at].lteq(options[:end_at]))
          end

          if options[:on].present?
            exists_contition = exists_contition.and(tagging_arel_table[:context].eq(options[:on]))
          end

          if (owner = options[:owned_by]).present?
            exists_contition = exists_contition.and(tagging_arel_table[:tagger_id].eq(owner.id))
                                               .and(tagging_arel_table[:tagger_type].eq(owner.class.base_class.to_s))
          end

          exists_contition
        end

        def order_conditions
          order_by = []
          if options[:order_by_matching_tag_count].present?
            order_by << "(SELECT count(*) FROM #{tagging_model.table_name} WHERE #{at_least_one_tag.to_sql}) desc"
          end

          order_by << options[:order] if options[:order].present?
          order_by.join(', ')
        end

        def alias_name(tag_list)
          alias_base_name = taggable_model.base_class.name.downcase
          taggings_context = options[:on] ? "_#{options[:on]}" : ''

          adjust_taggings_alias(
            "#{alias_base_name[0..4]}#{taggings_context[0..6]}_taggings_#{ActsAsTaggableOn::Utils.sha_prefix(tag_list.join('_'))}"
          )
        end
      end
    end
  end
end
