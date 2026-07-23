import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import {
  SOCIAL_PLATFORMS,
  EMAIL_PROVIDERS,
  DEFAULT_CHANNEL_TYPES,
} from './constants';
import { findConnectedInbox } from './channelMatchers';
import { useChannelConfig } from './useChannelConfig';

// How many channel rows to show, whether detected or defaulted. DEFAULT_CHANNEL_TYPES
// is config-gated like everything else, then sliced to this limit.
const DISPLAYED_CHANNEL_LIMIT = 3;

// Pull the handle/username out of a detected social URL, formatted per channel.
const extractHandle = ({ type, url }) => {
  try {
    const { pathname } = new URL(url);
    const path = pathname.replace(/^\/+|\/+$/g, '');
    if (type === 'whatsapp') {
      const digits = path.replace(/\D/g, '');
      return digits ? `+${digits}` : '';
    }
    if (type === 'line') return path;
    return path.startsWith('@') ? path : `@${path}`;
  } catch {
    return '';
  }
};

// Derives the channel rows for the inbox-setup step from the account's detected
// brand_info (socials + mailbox provider) and the real connected inboxes,
// keeping InboxSetup.vue focused on layout, connect routing, and completion.
export function useDetectedChannels() {
  const { currentAccount } = useAccount();
  const inboxes = useMapGetter('inboxes/getInboxes');
  const { isConfigured } = useChannelConfig();

  const brandSocials = computed(
    () => currentAccount.value?.custom_attributes?.brand_info?.socials || []
  );

  const connectedChannels = computed(() =>
    brandSocials.value
      .filter(social => SOCIAL_PLATFORMS[social.type] && social.url)
      .map(social => ({
        type: social.type,
        handle: extractHandle(social),
        labelKey: SOCIAL_PLATFORMS[social.type].labelKey,
        inbox: { channel_type: SOCIAL_PLATFORMS[social.type].channelType },
      }))
  );

  const detectedEmailChannel = computed(() => {
    const brandInfo = currentAccount.value?.custom_attributes?.brand_info;
    const provider = brandInfo?.email_provider;
    if (!EMAIL_PROVIDERS[provider]) return null;

    return {
      type: 'email',
      handle: brandInfo?.email || '',
      labelKey: EMAIL_PROVIDERS[provider].labelKey,
      inbox: { channel_type: 'Channel::Email', provider },
    };
  });

  // The real inbox backing a channel, if one exists — returned (not just a
  // boolean) so the row can show the connected account's real name.
  const connectedInbox = channel =>
    findConnectedInbox(inboxes.value, channel.inbox);

  // A channel row built from a social type, with no detected handle — used for
  // the default suggestions when nothing was detected.
  const toChannelRow = type => ({
    type,
    handle: '',
    labelKey: SOCIAL_PLATFORMS[type].labelKey,
    inbox: { channel_type: SOCIAL_PLATFORMS[type].channelType },
  });

  const detectedChannels = computed(() =>
    [detectedEmailChannel.value, ...connectedChannels.value]
      .filter(Boolean)
      // Email channels (including Gmail/Outlook OAuth) are disabled for this
      // phase; they will be enabled in a future PR.
      .filter(channel => channel.type !== 'email')
      // Hide channels whose installation OAuth credentials are missing — their
      // connect flow would only error.
      .filter(channel => isConfigured(channel.type))
  );

  const defaultChannels = computed(() =>
    DEFAULT_CHANNEL_TYPES.filter(isConfigured)
      .slice(0, DISPLAYED_CHANNEL_LIMIT)
      .map(toChannelRow)
  );

  // Show the detected channels, or fall back to the default suggestions so the
  // step is never an empty list.
  const displayedChannels = computed(() =>
    detectedChannels.value.length
      ? detectedChannels.value
      : defaultChannels.value
  );

  const remainingChannels = computed(() => {
    // Exclude whatever is already shown as a row (detected or defaulted) so the
    // footer preview doesn't duplicate it.
    const shownTypes = new Set(displayedChannels.value.map(c => c.type));
    return Object.entries(SOCIAL_PLATFORMS)
      .filter(([type]) => !shownTypes.has(type))
      .filter(([type]) => isConfigured(type))
      .slice(0, 3)
      .map(([type, { labelKey, channelType }]) => ({
        type,
        labelKey,
        inbox: { channel_type: channelType },
      }));
  });

  const hasDetectedChannels = computed(() => detectedChannels.value.length > 0);

  return {
    displayedChannels,
    remainingChannels,
    connectedInbox,
    hasDetectedChannels,
  };
}
