class NonStandardIdTaggableModel < ActiveRecord::Base
  self.primary_key = :an_id
  acts_as_taggable
  acts_as_taggable_on :languages
  acts_as_taggable_on :skills
  acts_as_taggable_on :needs, :offerings
  has_many :untaggable_models
end
