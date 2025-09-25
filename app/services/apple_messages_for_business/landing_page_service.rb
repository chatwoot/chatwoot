class AppleMessagesForBusiness::LandingPageService
  def initialize(channel)
    @channel = channel
  end

  def generate_landing_page(state, oauth2_provider)
    context = get_landing_context(state)
    return render_error_page('Invalid or expired authentication request') unless context

    {
      html: render_landing_page_html(oauth2_provider, context),
      content_type: 'text/html',
      status: 200
    }
  end

  def generate_success_page(user_data, provider)
    {
      html: render_success_page_html(user_data, provider),
      content_type: 'text/html',
      status: 200
    }
  end

  def generate_error_page(error_message)
    {
      html: render_error_page_html(error_message),
      content_type: 'text/html',
      status: 400
    }
  end

  private

  def get_landing_context(state)
    redis_key = "apple_auth_landing:#{state}"
    context_json = Redis.current.get(redis_key)

    return nil unless context_json

    JSON.parse(context_json)
  rescue JSON::ParserError
    nil
  end

  def render_landing_page_html(provider, context)
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Authentication - #{@channel.name}</title>
          <style>
              body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  margin: 0;
                  padding: 20px;
                  min-height: 100vh;
                  display: flex;
                  align-items: center;
                  justify-content: center;
              }
              .container {
                  background: white;
                  border-radius: 16px;
                  padding: 40px;
                  box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                  text-align: center;
                  max-width: 400px;
                  width: 100%;
              }
              .logo {
                  width: 60px;
                  height: 60px;
                  background: #007AFF;
                  border-radius: 12px;
                  margin: 0 auto 20px;
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  color: white;
                  font-size: 24px;
                  font-weight: bold;
              }
              h1 {
                  color: #333;
                  margin-bottom: 10px;
                  font-size: 24px;
              }
              p {
                  color: #666;
                  margin-bottom: 30px;
                  line-height: 1.5;
              }
              .auth-button {
                  display: inline-block;
                  background: ##{provider_color(provider)};
                  color: white;
                  padding: 12px 24px;
                  border-radius: 8px;
                  text-decoration: none;
                  font-weight: 500;
                  margin: 10px;
                  transition: transform 0.2s;
              }
              .auth-button:hover {
                  transform: translateY(-2px);
              }
              .cancel-button {
                  display: inline-block;
                  background: #f1f1f1;
                  color: #666;
                  padding: 12px 24px;
                  border-radius: 8px;
                  text-decoration: none;
                  font-weight: 500;
                  margin: 10px;
              }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="logo">💬</div>
              <h1>Authentication Required</h1>
              <p>#{@channel.name} is requesting access to your #{provider.capitalize} profile to complete this action.</p>

              <a href="#{context['success_url']}" class="auth-button">
                  Continue with #{provider.capitalize}
              </a>

              #{context['cancel_url'] ? "<a href=\"#{context['cancel_url']}\" class=\"cancel-button\">Cancel</a>" : ''}
          </div>
      </body>
      </html>
    HTML
  end

  def render_success_page_html(user_data, provider)
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Authentication Successful</title>
          <style>
              body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  margin: 0;
                  padding: 20px;
                  min-height: 100vh;
                  display: flex;
                  align-items: center;
                  justify-content: center;
              }
              .container {
                  background: white;
                  border-radius: 16px;
                  padding: 40px;
                  box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                  text-align: center;
                  max-width: 400px;
                  width: 100%;
              }
              .success-icon {
                  width: 60px;
                  height: 60px;
                  background: #34C759;
                  border-radius: 50%;
                  margin: 0 auto 20px;
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  color: white;
                  font-size: 30px;
              }
              h1 {
                  color: #333;
                  margin-bottom: 10px;
                  font-size: 24px;
              }
              p {
                  color: #666;
                  margin-bottom: 20px;
                  line-height: 1.5;
              }
              .user-info {
                  background: #f8f9fa;
                  border-radius: 8px;
                  padding: 20px;
                  margin: 20px 0;
              }
              .close-button {
                  background: #007AFF;
                  color: white;
                  padding: 12px 24px;
                  border: none;
                  border-radius: 8px;
                  font-weight: 500;
                  cursor: pointer;
                  margin-top: 20px;
              }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="success-icon">✓</div>
              <h1>Authentication Successful!</h1>
              <p>You have successfully authenticated with #{provider.capitalize}.</p>

              <div class="user-info">
                  <strong>#{user_data[:name]}</strong><br>
                  #{user_data[:email]}
              </div>

              <button class="close-button" onclick="window.close()">Close Window</button>
          </div>
      </body>
      </html>
    HTML
  end

  def render_error_page_html(error_message)
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Authentication Error</title>
          <style>
              body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  margin: 0;
                  padding: 20px;
                  min-height: 100vh;
                  display: flex;
                  align-items: center;
                  justify-content: center;
              }
              .container {
                  background: white;
                  border-radius: 16px;
                  padding: 40px;
                  box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                  text-align: center;
                  max-width: 400px;
                  width: 100%;
              }
              .error-icon {
                  width: 60px;
                  height: 60px;
                  background: #FF3B30;
                  border-radius: 50%;
                  margin: 0 auto 20px;
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  color: white;
                  font-size: 30px;
              }
              h1 {
                  color: #333;
                  margin-bottom: 10px;
                  font-size: 24px;
              }
              p {
                  color: #666;
                  margin-bottom: 20px;
                  line-height: 1.5;
              }
              .close-button {
                  background: #666;
                  color: white;
                  padding: 12px 24px;
                  border: none;
                  border-radius: 8px;
                  font-weight: 500;
                  cursor: pointer;
                  margin-top: 20px;
              }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="error-icon">✗</div>
              <h1>Authentication Failed</h1>
              <p>#{error_message}</p>

              <button class="close-button" onclick="window.close()">Close Window</button>
          </div>
      </body>
      </html>
    HTML
  end

  def provider_color(provider)
    case provider.downcase
    when 'google'
      '4285F4'
    when 'linkedin'
      '0A66C2'
    when 'facebook'
      '1877F2'
    else
      '007AFF'
    end
  end
end