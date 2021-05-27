# == Schema Information
#
# Table name: super_admins
#
#  id                  :bigint           not null, primary key
#  current_sign_in_at  :datetime
#  current_sign_in_ip  :inet
#  email               :string           default(""), not null
#  encrypted_password  :string           default(""), not null
#  last_sign_in_at     :datetime
#  last_sign_in_ip     :inet
#  remember_created_at :datetime
#  sign_in_count       :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_super_admins_on_email  (email) UNIQUE
#
class SuperAdmin < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :trackable, :rememberable, :validatable, :password_has_required_content
end
