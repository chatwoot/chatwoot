# frozen_string_literal: true

module Browser
  class Safari < Base
    def id
      :safari
    end

    def name
      "Safari"
    end

    def full_version
      ua[%r{Version/([\d.]+)}, 1] ||
        ua[%r{Safari/([\d.]+)}, 1] ||
        ua[%r{AppleWebKit/([\d.]+)}, 1] ||
        "0.0"
    end

    def match?
      ua.include?("Safari") &&
        !ua.match?(/PhantomJS|FxiOS/) &&
        !edge? &&
        !chrome? &&
        !opera? &&
        !samsung_browser? &&
        !huawei_browser? &&
        !miui_browser? &&
        !duck_duck_go? &&
        !yandex? &&
        !sputnik? &&
        !maxthon? &&
        !qq? &&
        !alipay? &&
        !sougou_browser? &&
        !google_search_app?
    end
  end
end
