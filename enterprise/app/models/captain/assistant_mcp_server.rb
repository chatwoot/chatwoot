# == Schema Information
#
# Table name: captain_assistant_mcp_servers
#
#  id                    :bigint           not null, primary key
#  enabled               :boolean          default(TRUE), not null
#  tool_filters          :jsonb
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  captain_assistant_id  :bigint           not null
#  captain_mcp_server_id :bigint           not null
#
# Indexes
#
#  idx_captain_assistant_mcp_server_unique                        (captain_assistant_id,captain_mcp_server_id) UNIQUE
#  index_captain_assistant_mcp_servers_on_captain_assistant_id    (captain_assistant_id)
#  index_captain_assistant_mcp_servers_on_captain_mcp_server_id   (captain_mcp_server_id)
#
class Captain::AssistantMcpServer < ApplicationRecord
  self.table_name = 'captain_assistant_mcp_servers'

  belongs_to :assistant,
             class_name: 'Captain::Assistant',
             foreign_key: :captain_assistant_id,
             inverse_of: :assistant_mcp_servers
  belongs_to :mcp_server,
             class_name: 'Captain::McpServer',
             foreign_key: :captain_mcp_server_id,
             inverse_of: :assistant_mcp_servers

  validates :captain_assistant_id, uniqueness: { scope: :captain_mcp_server_id }

  scope :enabled, -> { where(enabled: true) }

  def filtered_tools
    all_tools = mcp_server.cached_tools || []
    return all_tools if tool_filters.blank?

    all_tools.select { |tool| matches_filters?(tool) }
  end

  private

  def matches_filters?(tool)
    include_list = tool_filters['include']
    exclude_list = tool_filters['exclude']

    return true if include_list.blank? && exclude_list.blank?

    included = include_list.blank? || include_list.include?(tool['name'])
    excluded = exclude_list.present? && exclude_list.include?(tool['name'])

    included && !excluded
  end
end
