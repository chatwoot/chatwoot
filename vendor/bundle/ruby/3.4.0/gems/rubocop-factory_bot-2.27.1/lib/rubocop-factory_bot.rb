# frozen_string_literal: true

require 'pathname'
require 'yaml'

require 'rubocop'

require_relative 'rubocop/factory_bot/factory_bot'
require_relative 'rubocop/factory_bot/language'
require_relative 'rubocop/factory_bot/plugin'
require_relative 'rubocop/factory_bot/version'

require_relative 'rubocop/cop/factory_bot/mixin/configurable_explicit_only'

require_relative 'rubocop/cop/factory_bot_cops'
