class RequestIdLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    request_id = env['action_dispatch.request_id']
    Thread.current[:request_id] = request_id
    @app.call(env)
  ensure
    Thread.current[:request_id] = nil
  end
end

Rails.application.config.middleware.insert_after ActionDispatch::RequestId, RequestIdLogger
