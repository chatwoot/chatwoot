// Kiraid: unified campaign channel abstraction (frontend mirror of
// app/services/campaigns/channel_strategy.rb).
//
// Every connected inbox is, conceptually, a candidate campaign channel. Which
// channels can actually run an outbound one_off campaign depends on the send
// tooling — so we keep a single map here instead of sprinkling allow-lists across
// the campaign forms.
//
// === REMOVE THIS ABSTRACTION ===
// Delete this file and import sites, then restore the per-channel inbox getters
// (getEmailInboxes / getWhatsAppInboxes / getSMSInboxes / getWebsiteInboxes)
// and the per-channel campaign forms/dialogs/pages. See
// app/services/campaigns/channel_strategy.rb removal notes for the backend side.
import { INBOX_TYPES } from 'dashboard/helper/inbox';

// Maps the dashboard channel-type key (INBOX_TYPES value) -> campaign strategy.
//   campaignable: the channel can host a campaign (ongoing or one_off)
//   oneOff:       a one_off (outbound cold-outreach) send path exists
//   labelKey:     i18n key fragment under CAMPAIGN for the channel display name
const CHANNEL_STRATEGIES = {
  [INBOX_TYPES.WEB]: { campaignable: true, oneOff: false, labelKey: 'WEBSITE' },
  [INBOX_TYPES.TWILIO]: {
    campaignable: true,
    oneOff: true,
    labelKey: 'TWILIO',
  },
  [INBOX_TYPES.SMS]: { campaignable: true, oneOff: true, labelKey: 'SMS' },
  [INBOX_TYPES.WHATSAPP]: {
    campaignable: true,
    oneOff: true,
    labelKey: 'WHATSAPP',
  },
  [INBOX_TYPES.EMAIL]: { campaignable: true, oneOff: true, labelKey: 'EMAIL' },
  // Connected inboxes with no campaign send path yet. They render in the inbox
  // picker as "not supported yet" so the channel list stays complete.
  [INBOX_TYPES.FB]: {
    campaignable: false,
    oneOff: false,
    labelKey: 'FACEBOOK',
  },
  [INBOX_TYPES.INSTAGRAM]: {
    campaignable: false,
    oneOff: false,
    labelKey: 'INSTAGRAM',
  },
  [INBOX_TYPES.TWITTER]: {
    campaignable: false,
    oneOff: false,
    labelKey: 'TWITTER',
  },
  [INBOX_TYPES.TELEGRAM]: {
    campaignable: false,
    oneOff: false,
    labelKey: 'TELEGRAM',
  },
  [INBOX_TYPES.LINE]: { campaignable: false, oneOff: false, labelKey: 'LINE' },
  [INBOX_TYPES.API]: { campaignable: false, oneOff: false, labelKey: 'API' },
  [INBOX_TYPES.TIKTOK]: {
    campaignable: false,
    oneOff: false,
    labelKey: 'TIKTOK',
  },
};

export const CAMPAIGN_CHANNEL_STRATEGIES = CHANNEL_STRATEGIES;

// Channel-type keys that can host a campaign of any kind.
export const CAMPAIGNABLE_CHANNEL_TYPES = Object.keys(
  CHANNEL_STRATEGIES
).filter(channelType => CHANNEL_STRATEGIES[channelType].campaignable);

// Channel-type keys that support a one_off (outbound) campaign send path.
export const ONE_OFF_CHANNEL_TYPES = Object.keys(CHANNEL_STRATEGIES).filter(
  channelType => CHANNEL_STRATEGIES[channelType].oneOff
);

// Whether a given inbox (raw API shape with a channel_type string) can run a
// one_off campaign. Twilio is special-cased because a Twilio inbox may be either
// an SMS inbox or a WhatsApp inbox depending on channel.medium.
export const isOneOffCampaignableInbox = inbox => {
  if (!inbox) return false;

  const { channel_type: channelType, medium } = inbox;
  if (channelType === INBOX_TYPES.TWILIO && medium === 'whatsapp') {
    return true; // WhatsApp-over-Twilio reuses the WhatsApp send path
  }

  return ONE_OFF_CHANNEL_TYPES.includes(channelType);
};

// Build inbox picker options that include EVERY connected inbox, marking the ones
// that do not yet support campaigns as disabled with a clear secondary label.
// Returns [{ value, label, disabled, secondaryLabel }].
export const buildCampaignInboxOptions = (inboxes, t) => {
  if (!Array.isArray(inboxes)) return [];

  const unsupportedKey = 'CAMPAIGN.FORM.INBOX.UNSUPPORTED_CHANNEL';

  return inboxes
    .map(inbox => {
      const channelType = inbox.channel_type;
      const strategy = CHANNEL_STRATEGIES[channelType];
      const isCampaignable = strategy ? strategy.campaignable : false;

      return {
        value: inbox.id,
        label: inbox.name,
        disabled: !isCampaignable,
        secondaryLabel: isCampaignable
          ? ''
          : t(unsupportedKey, { channel: inbox.name }),
      };
    })
    .sort((a, b) => a.label.localeCompare(b.label));
};
