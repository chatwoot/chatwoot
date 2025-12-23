class UntaggableModel < ActiveRecord::Base
  belongs_to :taggable_model
end
