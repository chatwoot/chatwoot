# Provides helper methods for working with Captain agent tools including
# tool resolution, text parsing, and metadata retrieval.
module Concerns::CaptainToolsHelpers
  extend ActiveSupport::Concern

  # Regular expression pattern for matching tool references in text.
  # Matches patterns like [Tool name](tool://tool_id) following markdown link syntax.
  TOOL_REFERENCE_REGEX = %r{\[[^\]]+\]\(tool://([^/)]+)\)}

  class_methods do
    # Returns all built-in agent tools with their metadata.
    # Only includes tools that have corresponding class files and can be resolved.
    #
    # @return [Array<Hash>] Array of tool hashes with :id, :title, :description, :icon
    def built_in_agent_tools
      @built_in_agent_tools ||= load_agent_tools
    end

    # Resolves a tool class from a tool ID.
    # Converts snake_case tool IDs to PascalCase class names and constantizes them.
    #
    # @param tool_id [String] The snake_case tool identifier
    # @return [Class, nil] The tool class if found, nil if not resolvable
    def resolve_tool_class(tool_id)
      class_name = "Captain::Tools::#{tool_id.classify}Tool"
      class_name.safe_constantize
    end

    # Returns an array of all built-in tool IDs.
    # Convenience method that extracts just the IDs from built_in_agent_tools.
    #
    # @return [Array<String>] Array of built-in tool IDs
    def built_in_tool_ids
      @built_in_tool_ids ||= built_in_agent_tools.map { |tool| tool[:id] }
    end

    private

    # Loads agent tools from the YAML configuration file.
    # Filters out tools that cannot be resolved to actual classes.
    #
    # @return [Array<Hash>] Array of resolvable tools with metadata
    # @api private
    def load_agent_tools
      tools_config = YAML.load_file(Rails.root.join('config/agents/tools.yml'))

      tools_config.filter_map do |tool_config|
        tool_class = resolve_tool_class(tool_config['id'])

        if tool_class
          {
            id: tool_config['id'],
            title: tool_config['title'],
            description: tool_config['description'],
            icon: tool_config['icon']
          }
        else
          Rails.logger.warn "Tool class not found for ID: #{tool_config['id']}"
          nil
        end
      end
    end
  end

  # Extracts tool IDs from text containing tool references.
  # Parses text for (tool://tool_id) patterns and returns unique tool IDs.
  #
  # @param text [String] Text to parse for tool references
  # @return [Array<String>] Array of unique tool IDs found in the text
  def extract_tool_ids_from_text(text)
    return [] if text.blank?

    tool_matches = text.scan(TOOL_REFERENCE_REGEX)
    tool_matches.flatten.uniq
  end
end
