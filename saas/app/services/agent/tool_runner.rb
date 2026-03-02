# frozen_string_literal: true

# Executes HTTP tool calls and the built-in "handoff_to_human" tool.
# Resolves Liquid templates in URL / body / headers before making external requests.
module Agent
  class ToolRunner
    TIMEOUT = 15
    HANDOFF_TOOL_NAME = 'handoff_to_human'

    Result = Struct.new(:name, :content, :handoff?, keyword_init: true)

    def initialize(ai_agent:, conversation: nil)
      @ai_agent = ai_agent
      @conversation = conversation
      @tools_by_name = ai_agent.agent_tools.active.index_by { |t| t.name.parameterize(separator: '_') }
    end

    # Execute a single tool call returned by the LLM.
    # tool_call: { 'id' => '...', 'function' => { 'name' => '...', 'arguments' => '...' } }
    def run(tool_call)
      fn = tool_call.dig('function') || tool_call
      name = fn['name']
      args = parse_arguments(fn['arguments'])

      return handle_handoff(args) if name == HANDOFF_TOOL_NAME

      tool = @tools_by_name[name]
      return Result.new(name: name, content: "Unknown tool: #{name}", handoff?: false) unless tool

      execute_tool(tool, args)
    end

    private

    def handle_handoff(args)
      reason = args['reason'] || 'Customer requested human agent'

      if @conversation
        # Toggle the conversation to a human agent
        @conversation.update!(assignee_id: nil)
        @conversation.messages.create!(
          message_type: :activity,
          content: "AI agent handed off to human: #{reason}",
          account_id: @conversation.account_id
        )
      end

      Result.new(name: HANDOFF_TOOL_NAME, content: "Handed off to human agent. Reason: #{reason}", handoff?: true)
    end

    def execute_tool(tool, args)
      variables = build_variables(args)

      case tool.tool_type
      when 'http'
        execute_http(tool, variables)
      when 'built_in'
        Result.new(name: tool.name, content: "Built-in tool '#{tool.name}' executed", handoff?: false)
      else
        Result.new(name: tool.name, content: "Unsupported tool type: #{tool.tool_type}", handoff?: false)
      end
    rescue UrlSsrfValidator::SsrfError => e
      Result.new(name: tool.name, content: "Blocked: #{e.message}", handoff?: false)
    rescue StandardError => e
      Result.new(name: tool.name, content: "Tool error: #{e.message}", handoff?: false)
    end

    def execute_http(tool, variables)
      url = tool.rendered_url(variables)
      UrlSsrfValidator.validate!(url)

      body = tool.rendered_body(variables)
      headers = render_headers(tool, variables)

      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.read_timeout = TIMEOUT
      http.open_timeout = 10

      request = build_http_request(tool.http_method, uri, body)
      headers.each { |k, v| request[k] = v }

      # Add auth if configured
      request['Authorization'] = "Bearer #{tool.auth_token}" if tool.auth_token.present?

      response = http.request(request)
      content = truncate_response(response.body)

      Result.new(name: tool.name.parameterize(separator: '_'), content: content, handoff?: false)
    end

    def build_http_request(method, uri, body)
      case method&.upcase
      when 'POST'
        req = Net::HTTP::Post.new(uri)
        req.body = body
        req['Content-Type'] = 'application/json'
        req
      when 'PUT', 'PATCH'
        req = Net::HTTP::Put.new(uri)
        req.body = body
        req['Content-Type'] = 'application/json'
        req
      when 'DELETE'
        Net::HTTP::Delete.new(uri)
      else
        Net::HTTP::Get.new(uri)
      end
    end

    def render_headers(tool, variables)
      return {} if tool.headers_template.blank?

      tool.headers_template.transform_values do |v|
        Liquid::Template.parse(v).render(variables.stringify_keys)
      end
    end

    def build_variables(args)
      vars = args.dup
      vars['conversation_id'] = @conversation&.display_id
      vars['account_id'] = @ai_agent.account_id
      vars
    end

    def parse_arguments(arguments)
      return {} if arguments.blank?

      arguments.is_a?(String) ? JSON.parse(arguments) : arguments
    rescue JSON::ParserError
      {}
    end

    def truncate_response(body)
      return '' if body.blank?

      body.truncate(4000)
    end
  end
end
