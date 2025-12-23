require "foreman/export"

class Foreman::Export::Inittab < Foreman::Export::Base

  def export
    error("Must specify a location") unless location

    inittab = []
    inittab << "# ----- foreman #{app} processes -----"

    index = 1
    engine.each_process do |name, process|
      1.upto(engine.formation[name]) do |num|
        id = app.slice(0, 2).upcase + sprintf("%02d", index)
        port = engine.port_for(process, num)

        commands = []
        commands << "cd #{engine.root}"
        commands << "export PORT=#{port}"
        engine.env.each_pair do |var, env|
          commands << "export #{var.upcase}=#{shell_quote(env)}"
        end
        commands << "#{process.command} >> #{log}/#{name}-#{num}.log 2>&1"

        inittab << "#{id}:4:respawn:/bin/su - #{user} -c '#{commands.join(";")}'"
        index += 1
      end
    end

    inittab << "# ----- end foreman #{app} processes -----"

    inittab = inittab.join("\n") + "\n"

    if location == "-"
      puts inittab
    else
      say "writing: #{location}"
      File.open(location, "w") { |file| file.puts inittab }
    end
  end

end
