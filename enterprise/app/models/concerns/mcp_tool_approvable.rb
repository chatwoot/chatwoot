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

  # Stores how each approved tool compares with a live listing. Captain, the tools page and the server's Needs review
  # badge read these states. Captain runs, the live tools page, approve_tool and the hourly check record their listings
  # here. ServerUpdateService does not, because it lists the server only to pin newly selected tools. A tool is written
  # only when its state changes. update_columns skips validations: a tool saved under older rules may fail today's, and
  # that must not stop Chatwoot from flagging a change.
  def record_live_tools(live_definitions)
    live = live_definitions.index_by { |definition| definition['name'] }
    tools.each do |tool|
      state = tool.review_state_for(live[tool.name])
      tool.update_columns(review_state: state) unless tool.review_state == state # rubocop:disable Rails/SkipsModelValidations
    end
  end

  # An approved tool changed on the server or is no longer listed, so an admin should review it
  def needs_review?
    tools.any? { |tool| !tool.review_current? }
  end

  # Marks each live tool with whether an admin approved it and whether it changed since, from the recorded states.
  # Missing lists the approved tools the server no longer offers.
  def live_tool_entries(live_definitions)
    approved = tools.index_by(&:name)
    entries = live_definitions.map do |definition|
      tool = approved[definition['name']]
      { definition: definition, approved: tool.present?, changed: tool.present? && tool.review_changed? }
    end
    { tools: entries, missing: tools.select(&:review_missing?).map(&:name) }
  end

  # Pins an approved tool to its live definition after an admin reviewed the change. The admin approves the version
  # they saw, so a server that answers this listing with another version is refused. Parameter sources stay, so a
  # parameter the server removed must lose its source first, and a new parameter is filled by Captain.
  def approve_tool(name, reviewed_digest, live_definitions)
    definition = live_definitions.find { |live| live['name'] == name }
    tool = tools.find { |approved| approved.name == name }
    invalid_tool!(name, :not_approved) unless tool
    invalid_tool!(name, :missing) unless definition
    invalid_tool!(name, :changed_again) unless Captain::McpTool.definition_digest(definition) == reviewed_digest

    tool.approve(definition)
    tool.save!
    record_live_tools(live_definitions)
  end

  # Adds the error to the server and raises, so the API answers 422 with the reason. The reason is a full sentence, so
  # it goes on the record and not on an attribute, whose name Rails would put in front of it.
  def invalid_tool!(name, reason)
    errors.add(:base, I18n.t("captain.mcp_server.tools.#{reason}", tool: name))
    raise ActiveRecord::RecordInvalid, self
  end

  private

  def approved_tool(name, definition)
    invalid_tool!(name, :missing) unless definition

    tools.new(account: account, name: name).tap { |tool| tool.approve(definition) }
  end
end
