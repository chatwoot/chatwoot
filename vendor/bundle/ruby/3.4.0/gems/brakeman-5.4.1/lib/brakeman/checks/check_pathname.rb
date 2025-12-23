require 'brakeman/checks/base_check'

class Brakeman::CheckPathname < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for unexpected Pathname behavior"

  def run_check
    check_rails_root_join
    check_pathname_join

  end

  def check_rails_root_join
    tracker.find_call(target: :'Rails.root', method: :join, nested: true).each do |result|
      check_result result
    end
  end

  def check_pathname_join
    pathname_methods = [
      :'Pathname.new',
      :'Pathname.getwd',
      :'Pathname.glob',
      :'Pathname.pwd',
    ]

    tracker.find_call(targets: pathname_methods, method: :join, nested: true).each do |result|
      check_result result
    end
  end

  def check_result result
    return unless original? result

    result[:call].each_arg do |arg|
      if match = has_immediate_user_input?(arg)
        warn :result => result,
          :warning_type => "Path Traversal",
          :warning_code => :pathname_traversal,
          :message => "Absolute paths in `Pathname#join` cause the entire path to be relative to the absolute path, ignoring any prior values",
          :user_input => match,
          :confidence => :high,
          :cwe_id => [22]
      end
    end
  end
end
