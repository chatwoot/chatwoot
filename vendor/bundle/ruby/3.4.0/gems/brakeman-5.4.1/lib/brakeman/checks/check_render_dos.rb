require 'brakeman/checks/base_check'

class Brakeman::CheckRenderDoS < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Warn about denial of service with render :text (CVE-2014-0082)"

  def run_check
    if version_between? "3.0.0", "3.0.20" or
       version_between? "3.1.0", "3.1.12" or
       version_between? "3.2.0", "3.2.16"

      tracker.find_call(:target => nil, :method => :render).each do |result|
        if text_render? result
          warn_about_text_render
          break
        end
      end
    end
  end

  def text_render? result
    node_type? result[:call], :render and
    result[:call].render_type == :text
  end

  def warn_about_text_render
    message = msg(msg_version(rails_version), " has a denial of service vulnerability ", msg_cve("CVE-2014-0082"), ". Upgrade to ", msg_version("3.2.17"))

    warn :warning_type => "Denial of Service",
      :warning_code => :CVE_2014_0082,
      :message => message,
      :confidence => :high,
      :link_path => "https://groups.google.com/d/msg/rubyonrails-security/LMxO_3_eCuc/ozGBEhKaJbIJ",
      :gem_info => gemfile_or_environment,
      :cwe_id => [20]
  end
end
