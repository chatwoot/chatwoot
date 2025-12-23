# frozen_string_literal: true

module Browser
  class Base
    include DetectVersion

    attr_reader :ua

    def initialize(ua, accept_language: nil)
      validate_size(:user_agent, ua.to_s)

      @ua = ua
      @accept_language_raw = accept_language.to_s
    end

    # Return a meta info about this browser.
    def meta
      Meta.get(self)
    end

    # Return an array with all preferred languages that this browser accepts.
    def accept_language
      @accept_language ||= begin
        validate_size(:accept_language, @accept_language_raw)
        AcceptLanguage.parse(@accept_language_raw)
      end
    end

    alias_method :to_a, :meta

    # Return meta representation as string.
    def to_s
      meta.to_a.join(" ")
    end

    def version
      full_version.split(".").first
    end

    # Return the platform.
    def platform
      @platform ||= Platform.new(ua)
    end

    # Return the bot info.
    def bot
      @bot ||= Bot.new(ua)
    end

    # Detect if current user agent is from a bot.
    def bot?
      bot.bot?
    end

    # Return the device info.
    def device
      @device ||= Device.new(ua)
    end

    # Detect if browser is Microsoft Internet Explorer.
    def ie?(expected_version = nil)
      InternetExplorer.new(ua).match? &&
        detect_version?(full_version, expected_version)
    end

    # Detect if browser is Microsoft Edge.
    def edge?(expected_version = nil)
      Edge.new(ua).match? && detect_version?(full_version, expected_version)
    end

    def compatibility_view?
      false
    end

    def msie_full_version
      "0.0"
    end

    def msie_version
      "0"
    end

    # Detect if browser is Instagram.
    def instagram?(expected_version = nil)
      Instagram.new(ua).match? &&
        detect_version?(full_version, expected_version)
    end

    # Detect if browser is Snapchat.
    def snapchat?(expected_version = nil)
      Snapchat.new(ua).match? &&
        detect_version?(full_version, expected_version)
    end

    # Detect if browser if Facebook.
    def facebook?(expected_version = nil)
      Facebook.new(ua).match? &&
        detect_version?(full_version, expected_version)
    end

    # Detect if browser is Otter.
    def otter?(expected_version = nil)
      Otter.new(ua).match? &&
        detect_version?(full_version, expected_version)
    end

    # Detect if browser is WebKit-based.
    def webkit?(expected_version = nil)
      ua.match?(/AppleWebKit/i) &&
        (!edge? || Edge.new(ua).chrome_based?) &&
        detect_version?(webkit_full_version, expected_version)
    end

    # Detect if browser is QuickTime
    def quicktime?(expected_version = nil)
      ua.match?(/QuickTime/i) && detect_version?(full_version, expected_version)
    end

    # Detect if browser is Apple CoreMedia.
    def core_media?(expected_version = nil)
      ua.include?("CoreMedia") && detect_version?(full_version,
                                                  expected_version)
    end

    # Detect if browser is PhantomJS
    def phantom_js?(expected_version = nil)
      PhantomJS.new(ua).match? &&
        detect_version?(full_version, expected_version)
    end

    # Detect if browser is Safari.
    def safari?(expected_version = nil)
      Safari.new(ua).match? && detect_version?(full_version, expected_version)
    end

    def safari_webapp_mode?
      (device.ipad? || device.iphone?) && ua.include?("AppleWebKit")
    end

    # Detect if browser is Firefox.
    def firefox?(expected_version = nil)
      Firefox.new(ua).match? && detect_version?(full_version, expected_version)
    end

    # Detect if browser is Chrome.
    def chrome?(expected_version = nil)
      Chrome.new(ua).match? && detect_version?(full_version, expected_version)
    end

    # Detect if browser is Opera.
    def opera?(expected_version = nil)
      Opera.new(ua).match? && detect_version?(full_version, expected_version)
    end

    # Detect if browser is Sputnik.
    def sputnik?(expected_version = nil)
      Sputnik.new(ua).match? && detect_version?(full_version, expected_version)
    end

    # Detect if browser is Yandex.
    def yandex?(expected_version = nil)
      Yandex.new(ua).match? && detect_version?(full_version, expected_version)
    end
    alias_method :yandex_browser?, :yandex?

    # Detect if browser is UCBrowser.
    def uc_browser?(expected_version = nil)
      UCBrowser.new(ua).match? &&
        detect_version?(full_version, expected_version)
    end

    # Detect if browser is Nokia S40 Ovi Browser.
    def nokia?(expected_version = nil)
      Nokia.new(ua).match? && detect_version?(full_version, expected_version)
    end

    # Detect if browser is MicroMessenger.
    def micro_messenger?(expected_version = nil)
      MicroMessenger.new(ua).match? &&
        detect_version?(full_version, expected_version)
    end

    alias_method :wechat?, :micro_messenger?

    def weibo?(expected_version = nil)
      Weibo.new(ua).match? && detect_version?(full_version, expected_version)
    end

    def alipay?(expected_version = nil)
      Alipay.new(ua).match? && detect_version?(full_version, expected_version)
    end

    # Detect if browser is Opera Mini.
    def opera_mini?(expected_version = nil)
      ua.include?("Opera Mini") && detect_version?(full_version,
                                                   expected_version)
    end

    # Detect if browser is DuckDuckGo.
    def duck_duck_go?(expected_version = nil)
      ua.include?("DuckDuckGo") && detect_version?(full_version,
                                                   expected_version)
    end

    # Detect if browser is Samsung.
    def samsung_browser?(expected_version = nil)
      ua.include?("SamsungBrowser") && detect_version?(full_version,
                                                       expected_version)
    end

    # Detect if browser is Huawei.
    def huawei_browser?(expected_version = nil)
      HuaweiBrowser.new(ua).match? &&
        detect_version?(full_version, expected_version)
    end

    # Detect if browser is Xiaomi Miui.
    def miui_browser?(expected_version = nil)
      MiuiBrowser.new(ua).match? &&
        detect_version?(full_version, expected_version)
    end

    # Detect if browser is Maxthon.
    def maxthon?(expected_version = nil)
      Maxthon.new(ua).match? && detect_version?(full_version, expected_version)
    end

    # Detect if browser is QQ.
    def qq?(expected_version = nil)
      QQ.new(ua).match? && detect_version?(full_version, expected_version)
    end

    # Detect if browser is Sougou.
    def sougou_browser?(expected_version = nil)
      SougouBrowser.new(ua).match? &&
        detect_version?(full_version, expected_version)
    end

    # Detect if browser is Google Search App
    def google_search_app?(expected_version = nil)
      ua.include?("GSA") && detect_version?(full_version, expected_version)
    end

    def webkit_full_version
      ua[%r{AppleWebKit/([\d.]+)}, 1] || "0.0"
    end

    def known?
      !unknown?
    end

    def unknown?
      id == :unknown_browser
    end

    # Detect if browser is a proxy browser.
    def proxy?
      nokia? || uc_browser? || opera_mini?
    end

    # Detect if the browser is Electron.
    def electron?(expected_version = nil)
      Electron.new(ua).match? && detect_version?(full_version, expected_version)
    end

    private def validate_size(subject, input)
      actual_bytesize = input.bytesize
      size_limit = Browser.public_send("#{subject}_size_limit")

      return if actual_bytesize < size_limit

      raise Error,
            "#{subject} cannot be larger than #{size_limit} bytes; " \
            "actual size is #{actual_bytesize} bytes"
    end
  end
end
