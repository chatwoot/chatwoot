require 'date'
require 'brakeman/checks/base_check'

# Not used directly - base check for EOLRails and EOLRuby
class Brakeman::EOLCheck < Brakeman::BaseCheck
  def check_eol_version library, eol_dates
    version = case library
              when :rails
                tracker.config.rails_version
              when :ruby
                tracker.config.ruby_version
              else
                raise 'Implement using tracker.config.gem_version'
              end

    eol_dates.each do |(start_version, end_version), eol_date|
      if version_between? start_version, end_version, version
        case
        when Date.today >= eol_date
          warn_about_unsupported_version library, eol_date, version
        when (Date.today + 30) >= eol_date
          warn_about_soon_unsupported_version library, eol_date, version, :medium
        when (Date.today + 60) >= eol_date
          warn_about_soon_unsupported_version library, eol_date, version, :low
        end

        break
      end
    end
  end

  def warn_about_soon_unsupported_version library, eol_date, version, confidence
    warn warning_type: 'Unmaintained Dependency',
      warning_code: :"pending_eol_#{library}",
      message: msg("Support for ", msg_version(version, library.capitalize), " ends on #{eol_date}"),
      confidence: confidence,
      gem_info: gemfile_or_environment(library),
      :cwe_id => [1104]
  end

  def warn_about_unsupported_version library, eol_date, version
    warn warning_type: 'Unmaintained Dependency',
      warning_code: :"eol_#{library}",
      message: msg("Support for ", msg_version(version, library.capitalize), " ended on #{eol_date}"),
      confidence: :high,
      gem_info: gemfile_or_environment(library),
      :cwe_id => [1104]
  end
end
