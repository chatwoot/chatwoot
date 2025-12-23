class App
  command [:make] do |c|
    c.desc "Show long form"
    c.flag [:l,:long]

    c.desc 'make a new task'
    c.command :task do |task|
      task.desc 'make the task a long task'
      task.flag [:l,:long]

      task.action do |g,o,a|
        puts 'new task'
        puts a.join(',')
        puts o[:long]
      end

      task.desc 'make a bug'
      task.arg :argument, [:multiple, :optional]
      task.command :bug do |bug|
        bug.desc 'make this bug in the legacy system'
        bug.flag [:l,:legacy]

        bug.action do |g,o,a|
          puts 'new task bug'
          puts a.join(',')
          # All this .to_s is to make sure 1.8.7/REE don't convert nil to the string "nil"
          puts o[:legacy].to_s
          puts o[:long].to_s
          puts o[:l].to_s
          puts o[GLI::Command::PARENT][:l].to_s
          puts o[GLI::Command::PARENT][:long].to_s
          puts o[GLI::Command::PARENT][:legacy].to_s
          puts o[GLI::Command::PARENT][GLI::Command::PARENT][:l].to_s
          puts o[GLI::Command::PARENT][GLI::Command::PARENT][:long].to_s
          puts o[GLI::Command::PARENT][GLI::Command::PARENT][:legacy].to_s
        end
      end
    end

    c.desc 'make a new context'
    c.command :context do |context|
      context.desc 'make the context a local context'
      context.flag [:l,:local]

      context.action do |g,o,a|
        puts 'new context'
        puts a.join(',')
        puts o[:local].to_s
        puts o[:long].to_s
        puts o[:l].to_s
      end
    end

  end
end
