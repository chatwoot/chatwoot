# frozen_string_literal: true

class TagAlias < ActiveRecord::Base
  unless ENV["SKIP_COMPOSITE_PK"]
    if ENV['AR_VERSION'].to_f <= 7.0 || ENV['AR_VERSION'].to_f >= 8.0
      belongs_to :tag, foreign_key: [:tag_id, :parent_id], required: true
    else
      belongs_to :tag, query_constraints: [:tag_id, :parent_id], required: true
    end
  end
end
