require 'yaml'

module FacebookComment
  def self.config
    @config ||= config_for_environment
  end

  def self.config_for_environment
    config = YAML.safe_load(ERB.new(File.read("#{Rails.root}/config/facebook_comment.yml")).result)
    config[Rails.env.to_s].with_indifferent_access
  end

  def self.verify_token
    config[:verify_token]
  end
end

Rails.application.config.after_initialize do
  # Đăng ký cấu hình Facebook Comment vào GlobalConfig
  InstallationConfig.where(name: 'FB_COMMENT_VERIFY_TOKEN').first_or_create(
    value: FacebookComment.verify_token,
    locked: false
  )
end
