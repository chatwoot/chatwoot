# == Schema Information
#
# Table name: embeddings
#
#  id         :bigint           not null, primary key
#  embedding  :vector(1536)
#  obj_type   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  obj_id     :bigint           not null
#
# Indexes
#
#  index_embeddings_on_account_id  (account_id)
#  index_embeddings_on_embedding   (embedding) USING ivfflat
#  index_embeddings_on_obj         (obj_type,obj_id)
#
class Embeddings < ApplicationRecord
  has_neighbors :embedding, normalize: true
  belongs_to :account
  belongs_to :obj, polymorphic: true
end
