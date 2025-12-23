# frozen_string_literal: true

require "set"
require "yaml"
require "pathname"

require_relative "version"
require_relative "detect_version"
require_relative "accept_language"
require_relative "base"
require_relative "safari"
require_relative "chrome"
require_relative "internet_explorer"
require_relative "firefox"
require_relative "edge"
require_relative "opera"
require_relative "blackberry"
require_relative "unknown"
require_relative "phantom_js"
require_relative "uc_browser"
require_relative "nokia"
require_relative "micro_messenger"
require_relative "weibo"
require_relative "qq"
require_relative "alipay"
require_relative "electron"
require_relative "facebook"
require_relative "otter"
require_relative "instagram"
require_relative "yandex"
require_relative "sputnik"
require_relative "snapchat"
require_relative "duck_duck_go"
require_relative "samsung_browser"
require_relative "huawei_browser"
require_relative "miui_browser"
require_relative "maxthon"
require_relative "sougou_browser"
require_relative "google_search_app"

require_relative "bot"
require_relative "bot/empty_user_agent_matcher"
require_relative "bot/keyword_matcher"
require_relative "bot/known_bots_matcher"

require_relative "middleware"
require_relative "platform"
require_relative "device"
require_relative "meta"

module Browser
  EMPTY_STRING = ""

  Error = Class.new(StandardError)

  def self.root
    @root ||= Pathname.new(File.expand_path("../..", __dir__))
  end

  class << self
    attr_accessor :user_agent_size_limit, :accept_language_size_limit
  end

  self.user_agent_size_limit = 2048
  self.accept_language_size_limit = 2048

  # Hold the list of browser matchers.
  # Order is important.
  def self.matchers
    @matchers ||= [
      Nokia,
      UCBrowser,
      PhantomJS,
      BlackBerry,
      Opera,
      Edge,
      InternetExplorer,
      Firefox,
      Otter,
      Facebook,             # must be placed before Chrome and Safari
      Instagram,            # must be placed before Chrome and Safari
      Snapchat,             # must be placed before Chrome and Safari
      Weibo,                # must be placed before Chrome and Safari
      MicroMessenger,       # must be placed before QQ
      QQ,                   # must be placed before Chrome and Safari
      Alipay,               # must be placed before Chrome and Safari
      Electron,             # must be placed before Chrome and Safari
      Yandex,               # must be placed before Chrome and Safari
      Sputnik,              # must be placed before Chrome and Safari
      DuckDuckGo,           # must be placed before Chrome and Safari
      SamsungBrowser,       # must be placed before Chrome and Safari
      HuaweiBrowser,        # must be placed before Chrome and Safari
      MiuiBrowser,          # must be placed before Chrome and Safari
      Maxthon,              # must be placed before Chrome and Safari
      SougouBrowser,        # must be placed before Chrome and Safari
      GoogleSearchApp,      # must be placed before Chrome and Safari
      Chrome,
      Safari,
      Unknown
    ]
  end

  def self.new(user_agent, **kwargs)
    matchers
      .map {|klass| klass.new(user_agent || EMPTY_STRING, **kwargs) }
      .find(&:match?)
  end
end
