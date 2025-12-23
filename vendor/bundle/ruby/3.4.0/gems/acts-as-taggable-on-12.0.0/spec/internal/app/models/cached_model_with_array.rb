if using_postgresql?
  class CachedModelWithArray < ActiveRecord::Base
    acts_as_taggable
  end
  if postgresql_support_json?
    class TaggableModelWithJson < ActiveRecord::Base
      acts_as_taggable
      acts_as_taggable_on :skills
    end
  end
end
