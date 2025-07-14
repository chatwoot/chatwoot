import { openBlock, createElementBlock } from "vue";
const SCRIPT_ID = "hcaptcha-api-script-id";
const HCAPTCHA_LOAD_FN_NAME = "_hcaptchaOnLoad";
let resolveFn;
let rejectFn;
const promise = new Promise((resolve, reject) => {
  resolveFn = resolve;
  rejectFn = reject;
});
function loadApiEndpointIfNotAlready(config) {
  if (window.hcaptcha) {
    resolveFn();
    return promise;
  }
  if (document.getElementById(SCRIPT_ID)) {
    return promise;
  }
  window[HCAPTCHA_LOAD_FN_NAME] = resolveFn;
  const scriptSrc = getScriptSrc(config);
  const script = document.createElement("script");
  script.id = SCRIPT_ID;
  script.src = scriptSrc;
  script.async = true;
  script.defer = true;
  script.onerror = (event) => {
    console.error("Failed to load api: " + scriptSrc, event);
    rejectFn("Failed to load api.js");
  };
  document.head.appendChild(script);
  return promise;
}
function getScriptSrc(config) {
  let scriptSrc = config.apiEndpoint;
  scriptSrc = addQueryParamIfDefined(scriptSrc, "render", "explicit");
  scriptSrc = addQueryParamIfDefined(scriptSrc, "onload", HCAPTCHA_LOAD_FN_NAME);
  scriptSrc = addQueryParamIfDefined(scriptSrc, "recaptchacompat", config.reCaptchaCompat === false ? "off" : null);
  scriptSrc = addQueryParamIfDefined(scriptSrc, "hl", config.language);
  scriptSrc = addQueryParamIfDefined(scriptSrc, "sentry", config.sentry);
  scriptSrc = addQueryParamIfDefined(scriptSrc, "custom", config.custom);
  scriptSrc = addQueryParamIfDefined(scriptSrc, "endpoint", config.endpoint);
  scriptSrc = addQueryParamIfDefined(scriptSrc, "assethost", config.assethost);
  scriptSrc = addQueryParamIfDefined(scriptSrc, "imghost", config.imghost);
  scriptSrc = addQueryParamIfDefined(scriptSrc, "reportapi", config.reportapi);
  return scriptSrc;
}
function addQueryParamIfDefined(url, queryName, queryValue) {
  if (queryValue !== void 0 && queryValue !== null) {
    const link = url.includes("?") ? "&" : "?";
    return url + link + queryName + "=" + encodeURIComponent(queryValue);
  }
  return url;
}
var _export_sfc = (sfc, props) => {
  for (const [key, val] of props) {
    sfc[key] = val;
  }
  return sfc;
};
const _sfc_main = {
  name: "VueHcaptcha",
  props: {
    sitekey: {
      type: String,
      required: true
    },
    theme: {
      type: String,
      default: void 0
    },
    size: {
      type: String,
      default: void 0
    },
    tabindex: {
      type: String,
      default: void 0
    },
    language: {
      type: String,
      default: void 0
    },
    reCaptchaCompat: {
      type: Boolean,
      default: true
    },
    challengeContainer: {
      type: String,
      default: void 0
    },
    rqdata: {
      type: String,
      default: void 0
    },
    sentry: {
      type: Boolean,
      default: true
    },
    custom: {
      type: Boolean,
      default: void 0
    },
    apiEndpoint: {
      type: String,
      default: "https://hcaptcha.com/1/api.js"
    },
    endpoint: {
      type: String,
      default: void 0
    },
    reportapi: {
      type: String,
      default: void 0
    },
    assethost: {
      type: String,
      default: void 0
    },
    imghost: {
      type: String,
      default: void 0
    }
  },
  data: () => {
    return {
      widgetId: null,
      hcaptcha: null,
      renderedCb: null
    };
  },
  mounted() {
    return loadApiEndpointIfNotAlready(this.$props).then(this.onApiLoaded).catch(this.onError);
  },
  unmounted() {
    this.teardown();
  },
  destroyed() {
    this.teardown();
  },
  methods: {
    teardown() {
      if (this.widgetId) {
        this.hcaptcha.reset(this.widgetId);
        this.hcaptcha.remove(this.widgetId);
      }
    },
    onApiLoaded() {
      this.hcaptcha = window.hcaptcha;
      const opt = {
        sitekey: this.sitekey,
        theme: this.theme,
        size: this.size,
        tabindex: this.tabindex,
        "callback": this.onVerify,
        "expired-callback": this.onExpired,
        "chalexpired-callback": this.onChallengeExpired,
        "error-callback": this.onError,
        "open-callback": this.onOpen,
        "close-callback": this.onClose
      };
      if (this.challengeContainer) {
        opt["challenge-container"] = this.challengeContainer;
      }
      this.widgetId = this.hcaptcha.render(this.$el, opt);
      if (this.rqdata) {
        this.hcaptcha.setData(this.widgetId, { rqdata: this.rqdata });
      }
      this.onRendered();
    },
    execute() {
      if (this.widgetId) {
        this.hcaptcha.execute(this.widgetId);
        this.onExecuted();
      } else {
        this.renderedCb = () => {
          this.renderedCb = null;
          this.execute();
        };
      }
    },
    executeAsync() {
      if (this.widgetId) {
        this.onExecuted();
        return this.hcaptcha.execute(this.widgetId, { async: true });
      }
      let resolveFn2;
      const promiseFn = new Promise((resolve) => {
        resolveFn2 = resolve;
      });
      this.renderedCb = () => {
        this.renderedCb = null;
        resolveFn2();
      };
      return promiseFn.then(this.executeAsync);
    },
    reset() {
      if (this.widgetId) {
        this.hcaptcha.reset(this.widgetId);
        this.onReset();
      } else {
        this.$emit("error", "Element is not rendered yet and thus cannot reset it. Wait for `rendered` event to safely call reset.");
      }
    },
    onRendered() {
      this.$emit("rendered");
      this.renderedCb && this.renderedCb();
    },
    onExecuted() {
      this.$emit("executed");
    },
    onReset() {
      this.$emit("reset");
    },
    onError(e) {
      this.$emit("error", e);
      this.reset();
    },
    onVerify() {
      const token = this.hcaptcha.getResponse(this.widgetId);
      const eKey = this.hcaptcha.getRespKey(this.widgetId);
      this.$emit("verify", token, eKey);
    },
    onExpired() {
      this.$emit("expired");
    },
    onChallengeExpired() {
      this.$emit("challengeExpired");
    },
    onOpen() {
      this.$emit("opened");
    },
    onClose() {
      this.$emit("closed");
    }
  }
};
const _hoisted_1 = { id: "hcap-script" };
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", _hoisted_1);
}
var hcaptcha = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export { hcaptcha as default };
