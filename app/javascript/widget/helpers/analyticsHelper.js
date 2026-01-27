// Fallback Google Analytics ID if not provided from database
const FALLBACK_GA_ID = 'G-R2XZRPDVQD';

export const loadGA = id => {
  // Use fallback ID if no ID is provided
  const gaId = id || FALLBACK_GA_ID;
  if (!gaId) return;

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