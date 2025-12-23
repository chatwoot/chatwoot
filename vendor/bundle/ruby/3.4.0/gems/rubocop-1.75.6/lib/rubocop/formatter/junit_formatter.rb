# frozen_string_literal: true

#
# This code is based on https://github.com/mikian/rubocop-junit-formatter.
#
# Copyright (c) 2015 Mikko Kokkonen
#
# MIT License
#
# https://github.com/mikian/rubocop-junit-formatter/blob/master/LICENSE.txt
#
module RuboCop
  module Formatter
    # This formatter formats the report data in JUnit format.
    class JUnitFormatter < BaseFormatter
      ESCAPE_MAP = {
        '"' => '&quot;',
        "'" => '&apos;',
        '<' => '&lt;',
        '>' => '&gt;',
        '&' => '&amp;'
      }.freeze

      def initialize(output, options = {})
        super

        @test_case_elements = []

        reset_count
      end

      def file_finished(file, offenses)
        @inspected_file_count += 1

        # TODO: Returns all cops with the same behavior as
        # the original rubocop-junit-formatter.
        # https://github.com/mikian/rubocop-junit-formatter/blob/v0.1.4/lib/rubocop/formatter/junit_formatter.rb#L9
        #
        # In the future, it would be preferable to return only enabled cops.
        Cop::Registry.all.each do |cop|
          target_offenses = offenses_for_cop(offenses, cop)
          @offense_count += target_offenses.count

          next unless relevant_for_output?(options, target_offenses)

          add_testcase_element_to_testsuite_element(file, target_offenses, cop)
        end
      end

      # rubocop:disable Layout/LineLength,Metrics/AbcSize,Metrics/MethodLength
      def finished(_inspected_files)
        output.puts %(<?xml version='1.0'?>)
        output.puts %(<testsuites>)
        output.puts %(  <testsuite name='rubocop' tests='#{@inspected_file_count}' failures='#{@offense_count}'>)

        @test_case_elements.each do |test_case_element|
          if test_case_element.failures.empty?
            output.puts %(    <testcase classname='#{xml_escape test_case_element.classname}' name='#{test_case_element.name}'/>)
          else
            output.puts %(    <testcase classname='#{xml_escape test_case_element.classname}' name='#{test_case_element.name}'>)
            test_case_element.failures.each do |failure_element|
              output.puts %(      <failure type='#{failure_element.type}' message='#{xml_escape failure_element.message}'>)
              output.puts %(        #{xml_escape failure_element.text})
              output.puts %(      </failure>)
            end
            output.puts %(    </testcase>)
          end
        end

        output.puts %(  </testsuite>)
        output.puts %(</testsuites>)
      end
      # rubocop:enable Layout/LineLength,Metrics/AbcSize,Metrics/MethodLength

      private

      def relevant_for_output?(options, target_offenses)
        !options[:display_only_failed] || target_offenses.any?
      end

      def offenses_for_cop(all_offenses, cop)
        all_offenses.select { |offense| offense.cop_name == cop.cop_name }
      end

      def add_testcase_element_to_testsuite_element(file, target_offenses, cop)
        @test_case_elements << TestCaseElement.new(
          classname: classname_attribute_value(file),
          name: cop.cop_name
        ).tap do |test_case_element|
          add_failure_to(test_case_element, target_offenses, cop.cop_name)
        end
      end

      def classname_attribute_value(file)
        @classname_attribute_value_cache ||= Hash.new do |hash, key|
          hash[key] = key.delete_suffix('.rb').gsub("#{Dir.pwd}/", '').tr('/', '.')
        end
        @classname_attribute_value_cache[file]
      end

      def reset_count
        @inspected_file_count = 0
        @offense_count = 0
      end

      def add_failure_to(testcase, offenses, cop_name)
        # One failure per offense. Zero failures is a passing test case,
        # for most surefire/nUnit parsers.
        offenses.each do |offense|
          testcase.failures << FailureElement.new(
            type: cop_name,
            message: offense.message,
            text: offense.location.to_s
          )
        end
      end

      def xml_escape(string)
        string.gsub(Regexp.union(ESCAPE_MAP.keys), ESCAPE_MAP)
      end

      class TestCaseElement # :nodoc:
        attr_reader :classname, :name, :failures

        def initialize(classname:, name:)
          @classname = classname
          @name = name
          @failures = []
        end
      end

      class FailureElement # :nodoc:
        attr_reader :type, :message, :text

        def initialize(type:, message:, text:)
          @type = type
          @message = message
          @text = text
        end
      end
    end
  end
end
