// Deep link das manifest shortcuts (?mobile_tab=inbox|conversations|settings).
// O param é capturado no load do módulo porque os redirects de boot do router
// (login → conta → dashboard) reescrevem a URL e descartam a query antes do
// MobileLayout montar.
let initialMobileTab = null;

if (typeof window !== 'undefined') {
  initialMobileTab = new URLSearchParams(window.location.search).get(
    'mobile_tab'
  );
}

export const consumeMobileTabDeepLink = () => {
  const tab = initialMobileTab;
  initialMobileTab = null;
  return tab;
};
