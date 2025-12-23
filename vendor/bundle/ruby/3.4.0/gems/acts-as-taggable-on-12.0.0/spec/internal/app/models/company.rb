class Company < ActiveRecord::Base
  acts_as_taggable_on :locations, :markets

  has_many :markets, :through => :market_taggings, :source => :tag

  private

  def find_or_create_tags_from_list_with_context(tag_list, context)
    if context.to_sym == :markets
      Market.find_or_create_all_with_like_by_name(tag_list)
    else
      super
    end
  end
end
