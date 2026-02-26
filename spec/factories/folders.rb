# == Schema Information
#
# Table name: folders
#
#  id          :bigint           not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer          not null
#  category_id :integer          not null
#
FactoryBot.define do
  factory :folder, class: 'Folder' do
    account_id { 1 }
    name { 'MyString' }
    description { 'MyText' }
    category_id { 1 }
  end
end
