class App
  desc "Create a new task or context"
  command [:create,:new] do |c|
    c.desc "Make a new task"
    c.arg_name 'task_name', :multiple
    c.arg :should_ignore_this
    c.command :tasks do |tasks|
      tasks.action do |global,options,args|
        puts "#{args}"
      end
    end

    c.desc "Make a new context"
    c.arg :should_ignore_this
    c.arg_name 'context_name', :optional
    c.command :contexts do |contexts|
      contexts.action do |global,options,args|
        puts "#{args}"
      end
    end

    c.default_desc "Makes a new task"
    c.action do
      puts "default action"
    end

    c.arg "first"
    c.arg "second"
    c.arg "name", :optional
    c.command :"relation_1-1" do |remote|
      remote.action do |global,options,args|
        puts "relation: #{args}"
      end
    end

    c.arg "first", :multiple
    c.arg "second"
    c.arg "name", :optional
    c.command :"relation_n-1" do |remote|
      remote.action do |global,options,args|
        puts "relation: #{args}"
      end
    end

    c.arg "first"
    c.arg "second", :multiple
    c.arg "name", :optional
    c.command :"relation_1-n" do |remote|
      remote.action do |global,options,args|
        puts "relation: #{args}"
      end
    end
  end
end
