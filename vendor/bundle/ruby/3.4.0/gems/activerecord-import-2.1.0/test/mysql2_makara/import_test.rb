# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../test_helper")

require File.expand_path("#{File.dirname(__FILE__)}/../support/assertions")
require File.expand_path("#{File.dirname(__FILE__)}/../support/mysql/import_examples")

should_support_mysql_import_functionality
