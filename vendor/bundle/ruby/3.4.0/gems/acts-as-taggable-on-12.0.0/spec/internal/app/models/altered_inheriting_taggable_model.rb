require_relative 'taggable_model'

class AlteredInheritingTaggableModel < TaggableModel
  acts_as_taggable_on :parts
end
