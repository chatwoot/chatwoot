# The tools of an MCP server that an admin approved for Captain. Each approved tool is pinned to the definition the
# admin reviewed, so a change on the server never reaches Captain until an admin approves it.
module Concerns::McpToolApprovable
  extend ActiveSupport::Concern

  # Selected tool names that have no approved tool yet. Only these need the server's live definitions.
  def new_tool_names(names)
    names - tools.pluck(:name)
  end

  # Makes the approved tools match the selections, a hash of fields by tool name. A tool that is already approved keeps
  # its approved definition, so editing its parameters never approves a change the server made, and fields the
  # selection leaves out keep their values. A newly selected tool is pinned to its definition in live_definitions.
  def sync_tools(selections, live_definitions)
    transaction do
      approved = tools.index_by(&:name)
      tools.where.not(name: selections.keys).delete_all
      selections.each do |name, fields|
        tool = approved[name] || approved_tool(name, live_definitions[name])
        tool.update!(fields)
      end
    end
    # The loaded list still holds the deleted tools
    tools.reset
  end

  # Compares the server's live tools with the approved ones. Each live tool says whether it is approved and whether
  # it changed since, and missing lists the approved tools the server no longer offers.
  def compare_live_tools(live_definitions)
    approved = tools.index_by(&:name)
    compared = live_definitions.map do |definition|
      tool = approved[definition['name']]
      { definition: definition, approved: tool.present?, changed: tool.present? && !tool.approval_current?(definition) }
    end
    { tools: compared, missing: approved.keys - live_definitions.pluck('name') }
  end

  # Adds the error to the server and raises, so the API answers 422 with the reason
  def invalid_tool!(name, reason)
    errors.add(:tools, I18n.t("captain.mcp_server.tools.#{reason}", tool: name))
    raise ActiveRecord::RecordInvalid, self
  end

  private

  def approved_tool(name, definition)
    invalid_tool!(name, :missing) unless definition

    tools.new(account: account, name: name).tap { |tool| tool.approve(definition) }
  end
end
