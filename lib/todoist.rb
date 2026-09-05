class Todoist
  include HTTParty

  base_uri 'https://api.todoist.com/rest/v2'
  format :json

  def initialize(access_token)
    @headers = { 'Authorization' => "Bearer #{access_token}" }
  end

  def create_task(content, project_id: nil, due_string: nil, description: nil)
    payload = { content: content }
    payload[:project_id] = project_id if project_id
    payload[:due_string] = due_string if due_string
    payload[:description] = description if description

    self.class.post('/tasks', headers: @headers, body: payload.to_json)
  end
end