class SidekiqHealthCheckController < ActionController
  def check
    res = `ps -ef | grep -i sidekiq | wc -l`
    res = res.strip
    if res.to_i < 2
      render json: {
        error: 'sidekiq is not running'
      }, status: :internal_server_error and return
    end

    render json: {
      message: 'sidekiq is running'
    }, status: :ok and return
  end
end
