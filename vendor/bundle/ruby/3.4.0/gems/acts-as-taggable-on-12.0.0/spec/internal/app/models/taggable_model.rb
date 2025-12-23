class TaggableModel < ActiveRecord::Base
  acts_as_taggable
  acts_as_taggable_on :languages
  acts_as_taggable_on :skills
  acts_as_taggable_on :needs, :offerings
  acts_as_taggable_tenant :tenant_id

  has_many :untaggable_models

  attr_reader :tag_list_submethod_called

  def tag_list=(v)
    @tag_list_submethod_called = true
    super
  end
end
