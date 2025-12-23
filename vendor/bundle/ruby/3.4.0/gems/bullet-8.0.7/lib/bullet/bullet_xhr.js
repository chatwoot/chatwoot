(function () {
  var oldOpen = window.XMLHttpRequest.prototype.open;
  var oldSend = window.XMLHttpRequest.prototype.send;

  /**
   * Return early if we've already extended prototype. This prevents
   * "maximum call stack exceeded" errors when used with Turbolinks.
   * See https://github.com/flyerhzm/bullet/issues/454
   */
  if (isBulletInitiated()) return;

  function isBulletInitiated() {
    return oldOpen.name == "bulletXHROpen" && oldSend.name == "bulletXHRSend";
  }
  function bulletXHROpen(_, url) {
    this._storedUrl = url;
    return Reflect.apply(oldOpen, this, arguments);
  }
  function bulletXHRSend() {
    if (this.onload) {
      this._storedOnload = this.onload;
    }
    this.onload = null;
    this.addEventListener("load", bulletXHROnload);
    return Reflect.apply(oldSend, this, arguments);
  }
  function bulletXHROnload() {
    if (
      this._storedUrl.startsWith(window.location.protocol + "//" + window.location.host) ||
      !this._storedUrl.startsWith("http") // For relative paths
    ) {
      var bulletFooterText = this.getResponseHeader("X-bullet-footer-text");
      if (bulletFooterText) {
        setTimeout(function () {
          var oldHtml = document.querySelector("#bullet-footer").innerHTML.split("<br>");
          var header = oldHtml[0];
          oldHtml = oldHtml.slice(1, oldHtml.length);
          var newHtml = oldHtml.concat(JSON.parse(bulletFooterText));
          newHtml = newHtml.slice(newHtml.length - 10, newHtml.length); // rotate through 10 most recent
          document.querySelector("#bullet-footer").innerHTML = `${header}<br>${newHtml.join("<br>")}`;
        }, 0);
      }
      var bulletConsoleText = this.getResponseHeader("X-bullet-console-text");
      if (bulletConsoleText && typeof console !== "undefined" && console.log) {
        setTimeout(function () {
          JSON.parse(bulletConsoleText).forEach((message) => {
            if (console.groupCollapsed && console.groupEnd) {
              console.groupCollapsed("Uniform Notifier");
              console.log(message);
              console.groupEnd();
            } else {
              console.log(message);
            }
          });
        }, 0);
      }
    }
    if (this._storedOnload) {
      return Reflect.apply(this._storedOnload, this, arguments);
    }
  }
  window.XMLHttpRequest.prototype.open = bulletXHROpen;
  window.XMLHttpRequest.prototype.send = bulletXHRSend;
})();
