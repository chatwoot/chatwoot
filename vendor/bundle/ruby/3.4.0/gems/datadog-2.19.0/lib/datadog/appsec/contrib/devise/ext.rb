# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module Devise
        # Devise integration constants
        module Ext
          EVENT_LOGIN_SUCCESS = 'users.login.success'
          EVENT_LOGIN_FAILURE = 'users.login.failure'
          EVENT_SIGNUP = 'users.signup'

          TAG_DD_USR_ID = '_dd.appsec.usr.id'
          TAG_DD_USR_LOGIN = '_dd.appsec.usr.login'
          TAG_DD_SIGNUP_MODE = '_dd.appsec.events.users.signup.auto.mode'
          TAG_DD_COLLECTION_MODE = '_dd.appsec.user.collection_mode'
          TAG_DD_LOGIN_SUCCESS_MODE = '_dd.appsec.events.users.login.success.auto.mode'
          TAG_DD_LOGIN_FAILURE_MODE = '_dd.appsec.events.users.login.failure.auto.mode'

          TAG_USR_ID = 'usr.id'
          TAG_SESSION_ID = 'usr.session_id'
          TAG_SIGNUP_TRACK = 'appsec.events.users.signup.track'
          TAG_SIGNUP_USR_ID = 'appsec.events.users.signup.usr.id'
          TAG_SIGNUP_USR_LOGIN = 'appsec.events.users.signup.usr.login'
          TAG_LOGIN_FAILURE_TRACK = 'appsec.events.users.login.failure.track'
          TAG_LOGIN_FAILURE_USR_ID = 'appsec.events.users.login.failure.usr.id'
          TAG_LOGIN_FAILURE_USR_LOGIN = 'appsec.events.users.login.failure.usr.login'
          TAG_LOGIN_FAILURE_USR_EXISTS = 'appsec.events.users.login.failure.usr.exists'
          TAG_LOGIN_SUCCESS_TRACK = 'appsec.events.users.login.success.track'
          TAG_LOGIN_SUCCESS_USR_LOGIN = 'appsec.events.users.login.success.usr.login'
        end
      end
    end
  end
end
