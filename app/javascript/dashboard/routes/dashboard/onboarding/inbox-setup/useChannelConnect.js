import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { useWhatsappEmbeddedSignup } from 'dashboard/composables/useWhatsappEmbeddedSignup';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import googleClient from 'dashboard/api/channel/googleClient';
import microsoftClient from 'dashboard/api/channel/microsoftClient';
import instagramClient from 'dashboard/api/channel/instagramClient';
import tiktokClient from 'dashboard/api/channel/tiktokClient';

// Channels that complete via an OAuth redirect. Email channels are keyed by their
// Channel::Email provider, others by channel type. The request is tagged with a
// return hint so the callback brings the user back to onboarding instead of the
// inbox settings page.
const OAUTH_CLIENTS = {
  google: googleClient,
  microsoft: microsoftClient,
  instagram: instagramClient,
  tiktok: tiktokClient,
};

export function useChannelConnect() {
  const { t } = useI18n();
  const store = useStore();
  const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();

  const connectViaOAuth = async provider => {
    const client = OAUTH_CLIENTS[provider];
    if (!client) return;

    try {
      const {
        data: { url },
      } = await client.generateAuthorization({ return_to: 'onboarding' });
      window.location.href = url;
    } catch {
      useAlert(t('ONBOARDING_INBOX_SETUP.ERROR'));
    }
  };

  // WhatsApp connects via Meta's embedded-signup popup instead of the redirect
  // OAuth flow above. Collect the signup credentials, exchange them for an
  // inbox, and surface the result inline — then refetch so the connected state
  // reflects the freshly created inbox (and renders its real channel icon).
  const connectWhatsapp = async () => {
    let credentials;
    try {
      credentials = await runEmbeddedSignup();
    } catch {
      useAlert(t('ONBOARDING_INBOX_SETUP.ERROR'));
      return;
    }
    if (!credentials) return; // user dismissed the popup

    try {
      await store.dispatch('inboxes/createWhatsAppEmbeddedSignup', credentials);
      await store.dispatch('inboxes/get');
      useAlert(t('ONBOARDING_INBOX_SETUP.WHATSAPP_CONNECTED'));
    } catch (error) {
      useAlert(
        parseAPIErrorResponse(error) || t('ONBOARDING_INBOX_SETUP.ERROR')
      );
    }
  };

  return { connectViaOAuth, connectWhatsapp };
}
