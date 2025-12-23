require 'brakeman/checks/base_check'

#Check for uses of quote_table_name in Rails versions before 2.3.13 and 3.0.10
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/6a1e473744bc389b
class Brakeman::CheckQuoteTableName < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for quote_table_name vulnerability in versions before 2.3.14 and 3.0.10"

  def run_check
    if (version_between?('2.0.0', '2.3.13') or 
        version_between?('3.0.0', '3.0.9'))

      if uses_quote_table_name?
        confidence = :high
      else
        confidence = :medium
      end

      if rails_version =~ /^3/
        message = msg("Rails versions before 3.0.10 have a vulnerability in ", msg_code("quote_table_name"), " ", msg_cve("CVE-2011-2930"))
      else
        message = msg("Rails versions before 2.3.14 have a vulnerability in ", msg_code("quote_table_name"), " ", msg_cve("CVE-2011-2930"))
      end

      warn :warning_type => "SQL Injection",
        :warning_code => :CVE_2011_2930,
        :message => message,
        :confidence => confidence,
        :gem_info => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/ah5HN0S8OJs/discussion",
        :cwe_id => [89]
    end
  end

  def uses_quote_table_name?
    Brakeman.debug "Finding calls to quote_table_name()"

    not tracker.find_call(:target => false, :method => :quote_table_name).empty?
  end
end
