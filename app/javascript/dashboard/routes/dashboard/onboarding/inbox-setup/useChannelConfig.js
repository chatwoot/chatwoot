import { useMapGetter } from 'dashboard/composables/store';

// OAuth/SDK channels need installation-level app credentials to be usable. When
// the credential is missing the channel is "not configured" and is hidden from
// onboarding entirely. Channels without an entry (Website, Telegram, Line, …)
// need no installation credential and are always considered configured.
// Mirrors the availability checks in ChannelItem.vue.
export function useChannelConfig() {
  const globalConfig = useMapGetter('globalConfig/get');
  const installationConfig = window.chatwootConfig || {};

  const CHANNEL_CONFIGURED = {
    // WhatsApp is onboarded only via Meta embedded signup, which needs both the
    // app id (not the 'none' sentinel) and the signup configuration id.
    whatsapp: () =>
      Boolean(installationConfig.whatsappAppId) &&
      installationConfig.whatsappAppId !== 'none' &&
      Boolean(installationConfig.whatsappConfigurationId),
    facebook: () => Boolean(installationConfig.fbAppId),
    instagram: () => Boolean(installationConfig.instagramAppId),
    tiktok: () => Boolean(installationConfig.tiktokAppId),
    gmail: () => Boolean(installationConfig.googleOAuthClientId),
    outlook: () => Boolean(globalConfig.value.azureAppId),
  };

  const isConfigured = type => CHANNEL_CONFIGURED[type]?.() ?? true;

  return { isConfigured };
}
