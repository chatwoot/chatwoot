export const loadGA = id => {
  // Only load GA if ID is provided from database/settings
  if (!id) return;
  const gaId = id;

  const script = document.createElement('script');
  script.async = true;
  script.src = `https://www.googletagmanager.com/gtag/js?id=${gaId}`;
  document.head.appendChild(script);

  window.dataLayer = window.dataLayer || [];
  function gtag() {
    // eslint-disable-next-line no-undef, prefer-rest-params
    dataLayer.push(arguments);
  }
  window.gtag = gtag;
  gtag('js', new Date());
  gtag('config', gaId);
};

export const trackEvent = (eventName, eventParams = {}) => {
  // eslint-disable-next-line no-console
  console.log(`Chatwoot SDK: Event Triggered - ${eventName}`, eventParams);
  if (window.gtag) {
    window.gtag('event', eventName, eventParams);
  }
};