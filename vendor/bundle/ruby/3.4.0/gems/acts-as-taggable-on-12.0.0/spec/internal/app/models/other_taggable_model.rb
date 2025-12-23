class OtherTaggableModel < ActiveRecord::Base
  acts_as_taggable_on :tags, :languages
  acts_as_taggable_on :needs, :offerings
end
