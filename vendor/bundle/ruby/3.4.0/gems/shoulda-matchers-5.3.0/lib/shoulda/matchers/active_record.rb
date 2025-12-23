require 'shoulda/matchers/active_record/association_matcher'
require 'shoulda/matchers/active_record/association_matchers'
require 'shoulda/matchers/active_record/association_matchers/counter_cache_matcher'
require 'shoulda/matchers/active_record/association_matchers/inverse_of_matcher'
require 'shoulda/matchers/active_record/association_matchers/join_table_matcher'
require 'shoulda/matchers/active_record/association_matchers/order_matcher'
require 'shoulda/matchers/active_record/association_matchers/through_matcher'
require 'shoulda/matchers/active_record/association_matchers/dependent_matcher'
require 'shoulda/matchers/active_record/association_matchers/required_matcher'
require 'shoulda/matchers/active_record/association_matchers/optional_matcher'
require 'shoulda/matchers/active_record/association_matchers/source_matcher'
require 'shoulda/matchers/active_record/association_matchers/model_reflector'
require 'shoulda/matchers/active_record/association_matchers/model_reflection'
require 'shoulda/matchers/active_record/association_matchers/option_verifier'
require 'shoulda/matchers/active_record/have_db_column_matcher'
require 'shoulda/matchers/active_record/have_db_index_matcher'
require 'shoulda/matchers/active_record/have_implicit_order_column'
require 'shoulda/matchers/active_record/have_readonly_attribute_matcher'
require 'shoulda/matchers/active_record/have_rich_text_matcher'
require 'shoulda/matchers/active_record/have_secure_token_matcher'
require 'shoulda/matchers/active_record/serialize_matcher'
require 'shoulda/matchers/active_record/accept_nested_attributes_for_matcher'
require 'shoulda/matchers/active_record/define_enum_for_matcher'
require 'shoulda/matchers/active_record/uniqueness'
require 'shoulda/matchers/active_record/validate_uniqueness_of_matcher'
require 'shoulda/matchers/active_record/have_attached_matcher'

module Shoulda
  module Matchers
    # This module provides matchers that are used to test behavior within
    # ActiveRecord classes.
    module ActiveRecord
    end
  end
end
