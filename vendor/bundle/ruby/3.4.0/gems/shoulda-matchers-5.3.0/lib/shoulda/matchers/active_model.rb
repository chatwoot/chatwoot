require 'shoulda/matchers/active_model/helpers'
require 'shoulda/matchers/active_model/qualifiers'
require 'shoulda/matchers/active_model/validation_matcher'
require 'shoulda/matchers/active_model/validation_matcher/build_description'
require 'shoulda/matchers/active_model/validator'
require 'shoulda/matchers/active_model/allow_value_matcher'
require 'shoulda/matchers/active_model/allow_value_matcher/attribute_changed_value_error'
require 'shoulda/matchers/active_model/allow_value_matcher/attribute_does_not_exist_error'
require 'shoulda/matchers/active_model/allow_value_matcher/attribute_setter'
require 'shoulda/matchers/active_model/allow_value_matcher/attribute_setter_and_validator'
require 'shoulda/matchers/active_model/allow_value_matcher/attribute_setters'
require 'shoulda/matchers/active_model/allow_value_matcher/attribute_setters_and_validators'
require 'shoulda/matchers/active_model/allow_value_matcher/successful_check'
require 'shoulda/matchers/active_model/allow_value_matcher/successful_setting'
require 'shoulda/matchers/active_model/disallow_value_matcher'
require 'shoulda/matchers/active_model/validate_length_of_matcher'
require 'shoulda/matchers/active_model/validate_inclusion_of_matcher'
require 'shoulda/matchers/active_model/validate_exclusion_of_matcher'
require 'shoulda/matchers/active_model/validate_absence_of_matcher'
require 'shoulda/matchers/active_model/validate_presence_of_matcher'
require 'shoulda/matchers/active_model/validate_acceptance_of_matcher'
require 'shoulda/matchers/active_model/validate_confirmation_of_matcher'
require 'shoulda/matchers/active_model/validate_numericality_of_matcher'
require 'shoulda/matchers/active_model/numericality_matchers/numeric_type_matcher'
require 'shoulda/matchers/active_model/numericality_matchers/comparison_matcher'
require 'shoulda/matchers/active_model/numericality_matchers/odd_number_matcher'
require 'shoulda/matchers/active_model/numericality_matchers/even_number_matcher'
require 'shoulda/matchers/active_model/numericality_matchers/only_integer_matcher'
require 'shoulda/matchers/active_model/numericality_matchers/range_matcher'
require 'shoulda/matchers/active_model/numericality_matchers/submatchers'
require 'shoulda/matchers/active_model/errors'
require 'shoulda/matchers/active_model/have_secure_password_matcher'

module Shoulda
  module Matchers
    # This module provides matchers that are used to test behavior within
    # ActiveModel or ActiveRecord classes.
    #
    # ### Testing conditional validations
    #
    # If your model defines a validation conditionally -- meaning that the
    # validation is declared with an `:if` or `:unless` option -- how do you
    # test it? You might expect the validation matchers here to have
    # corresponding `if` or `unless` qualifiers, but this isn't what you use.
    # Instead, before using the matcher in question, you place the record
    # you're testing in a state such that the validation you're also testing
    # will be run. A common way to do this is to make a new `context` and
    # override the subject to populate the record accordingly. You'll also want
    # to make sure to test that the validation is *not* run when the
    # conditional fails.
    #
    # Here's an example to illustrate what we mean:
    #
    #     class User
    #       include ActiveModel::Model
    #
    #       attr_accessor :role, :admin
    #
    #       validates_presence_of :role, if: :admin
    #     end
    #
    #     # RSpec
    #     RSpec.describe User, type: :model do
    #       context "when an admin" do
    #         subject { User.new(admin: true) }
    #
    #         it { should validate_presence_of(:role) }
    #       end
    #
    #       context "when not an admin" do
    #         subject { User.new(admin: false) }
    #
    #         it { should_not validate_presence_of(:role) }
    #       end
    #     end
    #
    #     # Minitest (Shoulda)
    #     class UserTest < ActiveSupport::TestCase
    #       context "when an admin" do
    #         subject { User.new(admin: true) }
    #
    #         should validate_presence_of(:role)
    #       end
    #
    #       context "when not an admin" do
    #         subject { User.new(admin: false) }
    #
    #         should_not validate_presence_of(:role)
    #       end
    #     end
    #
    module ActiveModel
    end
  end
end
