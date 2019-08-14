module Constants::Report
  ACCOUNT_METRICS = [ :conversations_count,
                      :incoming_messages_count,
                      :outgoing_messages_count,
                      :avg_first_response_time,
                      :avg_resolution_time,
                      :resolutions_count
                    ]

  AVG_ACCOUNT_METRICS = [:avg_first_response_time, :avg_resolution_time]


  AGENT_METRICS = [ :avg_first_response_time,
                    :avg_resolution_time,
                    :resolutions_count
                  ]

  AVG_AGENT_METRICS = [:avg_first_response_time, :avg_resolution_time]
end
