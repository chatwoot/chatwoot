(() => {
  const widget = document.querySelector('[data-chatwoot-website-token]');
  if (!widget || document.getElementById('chatwoot_live_chat_widget')) return;

  const baseUrl = 'https://app.chatwoot.com';
  const runWidget = () => {
    window.chatwootSDK.run({
      websiteToken: widget.dataset.chatwootWebsiteToken,
      baseUrl,
    });
  };

  if (window.chatwootSDK) {
    runWidget();
    return;
  }

  const sdk = document.createElement('script');
  sdk.src = baseUrl + '/packs/js/sdk.js';
  sdk.async = true;
  sdk.addEventListener('load', runWidget, { once: true });
  document.head.appendChild(sdk);
})();
