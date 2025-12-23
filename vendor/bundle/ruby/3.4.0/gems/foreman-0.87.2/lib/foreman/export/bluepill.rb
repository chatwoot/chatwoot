require "erb"
require "foreman/export"

class Foreman::Export::Bluepill < Foreman::Export::Base

  def export
    super
    clean "#{location}/#{app}.pill"
    write_template "bluepill/master.pill.erb", "#{app}.pill", binding
  end

end
