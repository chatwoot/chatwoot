# The tools an assistant has: the built-in tools, its custom tools and the tools of its MCP servers. Scenarios, the
# assistant API and the runner read the same catalog, so they agree on which tools exist.
module Concerns::AssistantToolCatalog
  extend ActiveSupport::Concern

  def available_agent_tools
    tools = self.class.built_in_agent_tools.dup

    tools.concat(custom_tools.enabled.map(&:to_tool_metadata))
    tools.concat(Captain::McpServer.enabled_for(self).flat_map(&:tool_metadata))

    tools
  end

  def available_tool_ids
    available_agent_tools.pluck(:id)
  end

  def known_tool_ids
    self.class.built_in_tool_ids + custom_tools.pluck(:slug) + mcp_tools.pluck(:captain_name)
  end

  # One instance per assistant record, so the agents of a run share one connection per MCP server, and a server is
  # listed at most once when the model calls its tools. A run loads the assistant once, so the instance lasts as long as
  # the run.
  def mcp_agent_tools
    @mcp_agent_tools ||= Captain::Mcp::AgentTools.new(self)
  end
end
