require 'time'
require 'stringio'
Brakeman.load_brakeman_dependency 'rexml/document'

class Brakeman::Report::JUnit < Brakeman::Report::Base
  def generate_report
    io = StringIO.new
    doc = REXML::Document.new
    doc.add REXML::XMLDecl.new '1.0', 'UTF-8'

    test_suites = REXML::Element.new 'testsuites'
    test_suites.add_attribute 'xmlns:brakeman', 'https://brakemanscanner.org/'
    properties = test_suites.add_element 'brakeman:properties', { 'xml:id' => 'scan_info' }
    properties.add_element 'brakeman:property', { 'brakeman:name' => 'app_path', 'brakeman:value' => tracker.app_path }
    properties.add_element 'brakeman:property', { 'brakeman:name' => 'rails_version', 'brakeman:value' => rails_version }
    properties.add_element 'brakeman:property', { 'brakeman:name' => 'security_warnings', 'brakeman:value' => all_warnings.length }
    properties.add_element 'brakeman:property', { 'brakeman:name' => 'start_time', 'brakeman:value' => tracker.start_time.iso8601 }
    properties.add_element 'brakeman:property', { 'brakeman:name' => 'end_time', 'brakeman:value' => tracker.end_time.iso8601 }
    properties.add_element 'brakeman:property', { 'brakeman:name' => 'duration', 'brakeman:value' => tracker.duration }
    properties.add_element 'brakeman:property', { 'brakeman:name' => 'checks_performed', 'brakeman:value' => checks.checks_run.join(',') }
    properties.add_element 'brakeman:property', { 'brakeman:name' => 'number_of_controllers', 'brakeman:value' => tracker.controllers.length }
    properties.add_element 'brakeman:property', { 'brakeman:name' => 'number_of_models', 'brakeman:value' => tracker.models.length - 1 }
    properties.add_element 'brakeman:property', { 'brakeman:name' => 'ruby_version', 'brakeman:value' => number_of_templates(@tracker) }
    properties.add_element 'brakeman:property', { 'brakeman:name' => 'number_of_templates', 'brakeman:value' => RUBY_VERSION }
    properties.add_element 'brakeman:property', { 'brakeman:name' => 'brakeman_version', 'brakeman:value' => Brakeman::Version }

    errors = test_suites.add_element 'brakeman:errors'
    tracker.errors.each { |e|
      error = errors.add_element 'brakeman:error'
      error.add_attribute 'brakeman:message', e[:error]
      e[:backtrace].each { |b|
        backtrace = error.add_element 'brakeman:backtrace'
        backtrace.add_text b
      }
    }

    obsolete = test_suites.add_element 'brakeman:obsolete'
    tracker.unused_fingerprints.each { |fingerprint|
      obsolete.add_element 'brakeman:warning', { 'brakeman:fingerprint' => fingerprint }
    }

    ignored = test_suites.add_element 'brakeman:ignored'
    ignored_warnings.each { |w|
      warning = ignored.add_element 'brakeman:warning'
      warning.add_attribute 'brakeman:message', w.message
      warning.add_attribute 'brakeman:category', w.warning_type
      warning.add_attribute 'brakeman:file', warning_file(w)
      warning.add_attribute 'brakeman:line', w.line
      warning.add_attribute 'brakeman:fingerprint', w.fingerprint
      warning.add_attribute 'brakeman:confidence', w.confidence_name 
      warning.add_attribute 'brakeman:code', w.format_code
      warning.add_text w.to_s
    }

    hostname = `hostname`.strip
    i = 0
    all_warnings
      .map { |warning| [warning.file, [warning]] }
      .reduce({}) { |entries, entry|
        key, value = entry
        entries[key] = entries[key] ? entries[key].concat(value) : value
        entries
      }
      .each { |file, warnings|
        i += 1
        test_suite = test_suites.add_element 'testsuite'
        test_suite.add_attribute 'id', i
        test_suite.add_attribute 'package', 'brakeman'
        test_suite.add_attribute 'name', file.relative
        test_suite.add_attribute 'timestamp', tracker.start_time.strftime('%FT%T')
        test_suite.add_attribute 'hostname', hostname == '' ? 'localhost' : hostname
        test_suite.add_attribute 'tests', checks.checks_run.length
        test_suite.add_attribute 'failures', warnings.length
        test_suite.add_attribute 'errors', '0'
        test_suite.add_attribute 'time', '0'

        test_suite.add_element 'properties'

        warnings.each { |warning|
          test_case = test_suite.add_element 'testcase'
          test_case.add_attribute 'name', 'run_check'
          test_case.add_attribute 'classname', warning.check
          test_case.add_attribute 'time', '0'

          failure = test_case.add_element 'failure'
          failure.add_attribute 'message', warning.message
          failure.add_attribute 'type', warning.warning_type
          failure.add_attribute 'brakeman:fingerprint', warning.fingerprint
          failure.add_attribute 'brakeman:file', warning_file(warning)
          failure.add_attribute 'brakeman:line', warning.line
          failure.add_attribute 'brakeman:confidence', warning.confidence_name 
          failure.add_attribute 'brakeman:code', warning.format_code
          failure.add_text warning.to_s
        }

        test_suite.add_element 'system-out'
        test_suite.add_element 'system-err'
      }

    doc.add test_suites
    doc.write io
    io.string
  end
end
