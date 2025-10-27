module Enterprise::ActivityMessageHandler
  def automation_status_change_activity_content
    debug_file = "tmp/conversation-#{id}.txt"

    File.open(debug_file, "a") do |f|
      f.puts "\n----- Enterprise automation_status_change_activity_content START -----"
      f.puts "Time: #{Time.current}"
      f.puts "Current.executed_by: #{Current.executed_by&.class&.name} - #{Current.executed_by&.id}"
      f.puts "Is Captain::Assistant?: #{Current.executed_by.instance_of?(Captain::Assistant)}"
      f.puts "Status: #{status}"
      f.puts "resolved?: #{resolved?}"
      f.puts "open?: #{open?}"
    end

    result = if Current.executed_by.instance_of?(Captain::Assistant)
               locale = Current.executed_by.account.locale
               File.open(debug_file, "a") do |f|
                 f.puts "Captain::Assistant detected!"
                 f.puts "Locale: #{locale}"
                 f.puts "Assistant name: #{Current.executed_by.name}"
               end

               if resolved?
                 content = I18n.t(
                   'conversations.activity.captain.resolved',
                   user_name: Current.executed_by.name,
                   locale: locale
                 )
                 File.open(debug_file, "a") { |f| f.puts "Generated resolved message: #{content}" }
                 content
               elsif open?
                 content = I18n.t(
                   'conversations.activity.captain.open',
                   user_name: Current.executed_by.name,
                   locale: locale
                 )
                 File.open(debug_file, "a") { |f| f.puts "Generated open message: #{content}" }
                 content
               else
                 File.open(debug_file, "a") { |f| f.puts "Neither resolved nor open - returning nil" }
                 nil
               end
             else
               File.open(debug_file, "a") { |f| f.puts "Not Captain::Assistant, calling super" }
               super
             end

    File.open(debug_file, "a") do |f|
      f.puts "Final result: #{result.inspect}"
      f.puts "----- Enterprise automation_status_change_activity_content END -----\n"
    end

    result
  end
end
