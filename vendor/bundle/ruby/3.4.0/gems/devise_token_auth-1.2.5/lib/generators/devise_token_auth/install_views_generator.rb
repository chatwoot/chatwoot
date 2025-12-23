# frozen_string_literal: true

module DeviseTokenAuth
  class InstallViewsGenerator < Rails::Generators::Base
    source_root File.expand_path('../../../app/views/devise/mailer', __dir__)

    def copy_mailer_templates
      copy_file(
        'confirmation_instructions.html.erb',
        'app/views/devise/mailer/confirmation_instructions.html.erb'
      )
      copy_file(
        'reset_password_instructions.html.erb',
        'app/views/devise/mailer/reset_password_instructions.html.erb'
      )
    end
  end
end
