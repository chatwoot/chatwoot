require "erb"
require "foreman/export"

class Foreman::Export::Daemon < Foreman::Export::Base

  def export
    super

    (Dir["#{location}/#{app}-*.conf"] << "#{location}/#{app}.conf").each do |file|
      clean file
    end

    write_template "daemon/master.conf.erb", "#{app}.conf", binding

    engine.each_process do |name, process|
      next if engine.formation[name] < 1
      write_template "daemon/process_master.conf.erb", "#{app}-#{name}.conf", binding

      1.upto(engine.formation[name]) do |num|
        port = engine.port_for(process, num)
        arguments = process.command.split(" ")
        executable = arguments.slice!(0)
        arguments = arguments.size > 0 ? " -- #{arguments.join(' ')}" : ""
        write_template "daemon/process.conf.erb", "#{app}-#{name}-#{num}.conf", binding
      end
    end
  end
end
