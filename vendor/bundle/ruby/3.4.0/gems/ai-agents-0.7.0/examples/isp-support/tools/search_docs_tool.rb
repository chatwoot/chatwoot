# frozen_string_literal: true

module ISPSupport
  # Tool for searching the knowledge base documentation.
  class SearchDocsTool < Agents::Tool
    description "Search knowledge base for troubleshooting steps and solutions"
    param :query, type: "string", desc: "Search terms or description of the issue"

    def perform(_tool_context, query:)
      case query.downcase
      when /slow|speed/
        "Try restarting your modem and router. Unplug for 30 seconds, then plug back in. Test speed at speedtest.net."
      when /no internet|down|offline/
        "Check modem lights are solid green. Unplug modem for 30 seconds, then plug back in. Wait 3 minutes for restart."
      when /wifi|wireless/
        "Check WiFi is enabled on device. Verify correct password. Move closer to router. Restart router if needed."
      else
        "General troubleshooting: Restart modem and router, check cable connections, test with different device."
      end
    end
  end
end
