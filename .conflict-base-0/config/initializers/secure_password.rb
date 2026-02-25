# frozen_string_literal: true

Devise.setup do |config|
  # ==> Configuration for the Devise Secure Password extension
  #     Module: password_has_required_content
  #
  # Configure password content requirements including the number of uppercase,
  # lowercase, number, and special characters that are required. To configure the
  # minimum and maximum length refer to the Devise config.password_length
  # standard configuration parameter.

  # The number of uppercase letters (latin A-Z) required in a password:
  config.password_required_uppercase_count = 1

  # The number of lowercase letters (latin A-Z) required in a password:
  config.password_required_lowercase_count = 1

  # The number of numbers (0-9) required in a password:
  config.password_required_number_count = 1

  # The number of special characters (!@#$%^&*()_+-=[]{}|') required in a password:
  config.password_required_special_character_count = 1

  # we are not using the configurations below
  # ==> Configuration for the Devise Secure Password extension
  #     Module: password_disallows_frequent_reuse
  #
  # The number of previously used passwords that can not be reused:
  # config.password_previously_used_count = 8

  # ==> Configuration for the Devise Secure Password extension
  #     Module: password_disallows_frequent_changes
  #     *Requires* password_disallows_frequent_reuse
  #
  # The minimum time that must pass between password changes:
  # config.password_minimum_age = 1.days

  # ==> Configuration for the Devise Secure Password extension
  #     Module: password_requires_regular_updates
  #     *Requires* password_disallows_frequent_reuse
  #
  # The maximum allowed age of a password:
  # config.password_maximum_age = 180.days
end
