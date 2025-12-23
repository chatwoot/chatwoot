# This is copied so I can have two slightly different versions of the same thing
desc "LS things, such as tasks or contexts"
long_desc %(
  List a whole lot of things that you might be keeping track of 
  in your overall todo list.

  This is your go-to place or finding all of the things that you
  might have 
  stored in 
  your todo databases.
)
command [:ls] do |c|
  c.desc "Show long form"
  c.switch [:l,:long]

  c.desc "List tasks"
  c.long_desc %(
    Lists all of your tasks that you have, in varying orders, and
    all that stuff.  Yes, this is long, but I need a long description.
  )
  c.command :tasks do |tasks|
    tasks.desc "blah blah crud x whatever"
    tasks.flag [:x]
    tasks.action do |global,options,args|
      puts "ls tasks: #{args.join(',')}"
    end
  end

  c.desc "List contexts"
  c.long_desc %(
    Lists all of your contexts, which are places you might be 
    where you can do stuff and all that.
  )
  c.command :contexts do |contexts|

    contexts.desc "Foobar"
    contexts.switch [:f,'foobar']

    contexts.desc "Blah"
    contexts.switch [:b]

    contexts.action do |global,options,args|
      puts "ls contexts: #{args.join(',')}"
    end
  end
end

