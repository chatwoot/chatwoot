// Web Share Target (Android): ?mobile_share=1&title=&text=&url= vindo do
// manifest. O param é capturado no load do módulo porque os redirects de boot
// do router reescrevem a URL e descartam a query antes do MobileLayout montar
// (mesmo racional de mobileDeepLink.js).
let initialShareText = null;
let pendingComposerPrefill = null;

if (typeof window !== 'undefined') {
  const params = new URLSearchParams(window.location.search);
  if (params.get('mobile_share') === '1') {
    const combined = [
      params.get('title'),
      params.get('text'),
      params.get('url'),
    ]
      .filter(Boolean)
      .join('\n')
      .trim();
    initialShareText = combined || null;
  }
}

export const consumeMobileShareText = () => {
  const text = initialShareText;
  initialShareText = null;
  return text;
};

// Ponte entre o sheet "Compartilhar em..." (MobileLayout) e o composer: o
// MobileChatView consome o prefill ao emitir FOCUS_REPLY_BOX após setActiveChat.
export const setShareComposerPrefill = text => {
  pendingComposerPrefill = text || null;
};

export const consumeShareComposerPrefill = () => {
  const text = pendingComposerPrefill;
  pendingComposerPrefill = null;
  return text;
};
