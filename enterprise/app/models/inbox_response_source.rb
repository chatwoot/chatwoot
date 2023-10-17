# == Schema Information
#
# Table name: inbox_response_sources
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  inbox_id           :bigint           not null
#  response_source_id :bigint           not null
#
# Indexes
#
#  index_inbox_response_sources_on_inbox_id                         (inbox_id)
#  index_inbox_response_sources_on_inbox_id_and_response_source_id  (inbox_id,response_source_id) UNIQUE
#  index_inbox_response_sources_on_response_source_id               (response_source_id)
#  index_inbox_response_sources_on_response_source_id_and_inbox_id  (response_source_id,inbox_id) UNIQUE
#
class InboxResponseSource < ApplicationRecord
  belongs_to :inbox
  belongs_to :response_source
end
