import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import googleClient from 'dashboard/api/channel/googleClient';
import microsoftClient from 'dashboard/api/channel/microsoftClient';
import instagramClient from 'dashboard/api/channel/instagramClient';

// Channels that complete via an OAuth redirect. Email channels are keyed by their
// Channel::Email provider, others by channel type. The request is tagged with a
// return hint so the callback brings the user back to onboarding instead of the
// inbox settings page.
const OAUTH_CLIENTS = {
  google: googleClient,
  microsoft: microsoftClient,
  instagram: instagramClient,
};

export function useChannelConnect() {
  const { t } = useI18n();

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

  return { connectViaOAuth };
}
