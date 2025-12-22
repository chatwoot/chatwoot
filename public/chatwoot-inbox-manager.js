(function() {
    var scriptTag = document.currentScript;
    var currentToken = scriptTag.dataset.websiteToken;
  
    window.addEventListener("message", function(event) {
      var raw = event.data;
      if (!raw || typeof raw !== "string") return;
      if (!raw.startsWith("chatwoot-widget:")) return;
  
      var data;
      try { data = JSON.parse(raw.replace("chatwoot-widget:", "")); } catch(e){ return; }
  
      if (data.event === "inbox_changed") {
        var newToken = data.website_token;
        if (!newToken || newToken === currentToken) return;
  
        currentToken = newToken;
  
        localStorage.setItem("cw_token", newToken);
  
        window.location.reload();
      }
    });
  })();
  