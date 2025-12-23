class OtherCachedModel < ActiveRecord::Base
  acts_as_taggable_on :languages, :statuses, :glasses
end
