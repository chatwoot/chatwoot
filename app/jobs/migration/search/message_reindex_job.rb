class Migration::Search::MessageReindexJob < ApplicationJob
  queue :searchkick

  
end
