require "erb"
require "foreman/export"

class Foreman::Export::Supervisord < Foreman::Export::Base

  def export
    super

    Dir["#{location}/#{app}.conf"].each do |file|
      clean file
    end

    write_template "supervisord/app.conf.erb", "#{app}.conf", binding
  end

end
