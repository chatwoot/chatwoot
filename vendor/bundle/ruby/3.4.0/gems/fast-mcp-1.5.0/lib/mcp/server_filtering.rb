# frozen_string_literal: true

module FastMcp
  # Module for handling server filtering functionality
  module ServerFiltering
    # Add filter for tools
    def filter_tools(&block)
      @tool_filters << block if block_given?
    end

    # Add filter for resources
    def filter_resources(&block)
      @resource_filters << block if block_given?
    end

    # Check if filters are configured
    def contains_filters?
      @tool_filters.any? || @resource_filters.any?
    end

    # Create a filtered copy for a specific request
    def create_filtered_copy(request)
      filtered_server = self.class.new(
        name: @name,
        version: @version,
        logger: @logger,
        capabilities: @capabilities
      )

      # Copy transport settings
      filtered_server.transport_klass = @transport_klass

      # Apply filters and register items
      register_filtered_tools(filtered_server, request)
      register_filtered_resources(filtered_server, request)

      filtered_server
    end

    private

    # Apply tool filters and register filtered tools
    def register_filtered_tools(filtered_server, request)
      filtered_tools = apply_tool_filters(request)

      # Register filtered tools
      filtered_tools.each do |tool|
        filtered_server.register_tool(tool)
      end
    end

    # Apply resource filters and register filtered resources
    def register_filtered_resources(filtered_server, request)
      filtered_resources = apply_resource_filters(request)

      # Register filtered resources
      filtered_resources.each do |resource|
        filtered_server.register_resource(resource)
      end
    end

    # Apply all tool filters to the tools collection
    def apply_tool_filters(request)
      filtered_tools = @tools.values
      @tool_filters.each do |filter|
        filtered_tools = filter.call(request, filtered_tools)
      end
      filtered_tools
    end

    # Apply all resource filters to the resources collection
    def apply_resource_filters(request)
      filtered_resources = @resources
      @resource_filters.each do |filter|
        filtered_resources = filter.call(request, filtered_resources)
      end
      filtered_resources
    end
  end
end
