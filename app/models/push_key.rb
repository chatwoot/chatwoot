# == Schema Information
#
# Table name: push_keys
#
#  id          :bigint           not null, primary key
#  private_key :string           default(""), not null
#  provider    :string           not null
#  public_key  :string           default(""), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class PushKey < ApplicationRecord
  validates :provider, presence: true

  after_commit do |record|
    # cache pubilc and private keys
    ::Redis::Alfred.set(::Redis::Alfred::PUSH_PUBLIC_KEY, record.public_key)
    ::Redis::Alfred.set(::Redis::Alfred::PUSH_PRIVATE_KEY, record.private_key)
  end
end
