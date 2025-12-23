# frozen_string_literal: true

require_relative 'install_generator_helpers'

module DeviseTokenAuth
  class InstallMongoidGenerator < Rails::Generators::Base
    include DeviseTokenAuth::InstallGeneratorHelpers

    def create_user_model
      fname = "app/models/#{user_class.underscore}.rb"
      if File.exist?(File.join(destination_root, fname))
        inclusion = 'include DeviseTokenAuth::Concerns::User'
        unless parse_file_for_line(fname, inclusion)
          inject_into_file fname, before: /end\s\z/ do <<-'RUBY'

  include Mongoid::Locker

  field :locker_locked_at, type: Time
  field :locker_locked_until, type: Time

  locker locked_at_field: :locker_locked_at,
         locked_until_field: :locker_locked_until

  ## Required
  field :provider, type: String
  field :uid,      type: String, default: ''

  ## Tokens
  field :tokens, type: Hash, default: {}

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  include DeviseTokenAuth::Concerns::User

  index({ uid: 1, provider: 1}, { name: 'uid_provider_index', unique: true, background: true })
            RUBY
          end
        end
      else
        template('user_mongoid.rb.erb', fname)
      end
    end
  end
end
