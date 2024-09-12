# == Schema Information
#
# Table name: keycloak_session_infos
#
#  id            :bigint           not null, primary key
#  browser_token :string
#  metadata      :json
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class KeycloakSessionInfo < ApplicationRecord
  validates :browser_token, uniqueness: true
end
