require "active_record"
require "groupdate/query_methods"
require "groupdate/relation"

ActiveRecord::Base.extend(Groupdate::QueryMethods)
ActiveRecord::Relation.include(Groupdate::Relation)
