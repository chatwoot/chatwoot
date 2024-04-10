# == Schema Information
#
# Table name: keycloak_session_infos
#
#  id            :bigint           not null, primary key
#  email         :string
#  session_state :string
#  token_info    :json
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class KeycloakSessionInfo < ApplicationRecord
end
