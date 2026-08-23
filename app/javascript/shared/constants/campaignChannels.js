// Kiraid: unified campaign channel abstraction (frontend mirror of
// app/services/campaigns/channel_strategy.rb).
//
// Every connected inbox is, conceptually, a candidate campaign channel. Which
// channels can actually run an outbound one_off campaign depends on the send
// tooling — so we keep a single map here instead of sprinkling allow-lists across
// the campaign forms.
//
// The campaign capability (campaignable / oneOff) lives on each channel in
// channelDefinitions.js; this file only reshapes it into a strategy map plus the
// inbox-picker helpers.
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { CHANNEL_DEFINITIONS } from 'dashboard/constants/channelDefinitions';

// Maps the dashboard channel-type key (INBOX_TYPES value) -> campaign strategy,
// derived from the single channelDefinitions source of truth.
//   campaignable: the channel can host a campaign (ongoing or one_off)
//   oneOff:       a one_off (outbound cold-outreach) send path exists
//   labelKey:     i18n key fragment under CAMPAIGN for the channel display name
const CHANNEL_STRATEGIES = Object.fromEntries(
  CHANNEL_DEFINITIONS.map(definition => [
    definition.type,
    {
      campaignable: definition.campaign.campaignable,
      oneOff: definition.campaign.oneOff,
      labelKey: definition.name.toUpperCase(),
    },
  ])
);

export const CAMPAIGN_CHANNEL_STRATEGIES = CHANNEL_STRATEGIES;

// Which channel types each campaign page may target. The inbox picker on a page
// is restricted to these so an admin can only attach an inbox whose channel
// matches the campaign they are creating (a WhatsApp campaign must use a
// WhatsApp inbox, an email campaign an email inbox, and so on).
export const CAMPAIGN_PAGE_CHANNEL_TYPES = {
  whatsapp: [INBOX_TYPES.WHATSAPP],
  email: [INBOX_TYPES.EMAIL],
  sms: [INBOX_TYPES.SMS, INBOX_TYPES.TWILIO],
};

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

// Build inbox picker options for a campaign page. `allowedChannelTypes` restricts
// the list to inboxes whose channel matches the page (see
// CAMPAIGN_PAGE_CHANNEL_TYPES); when omitted every connected inbox is returned.
// A WhatsApp-over-Twilio inbox is always excluded: it has no WhatsApp send path
// on this fork, so selecting it would produce a campaign that fails on dispatch.
// Returns [{ value, label, disabled, secondaryLabel }].
export const buildCampaignInboxOptions = (
  inboxes,
  t,
  allowedChannelTypes = null
) => {
  if (!Array.isArray(inboxes)) return [];

  const unsupportedKey = 'CAMPAIGN.FORM.INBOX.UNSUPPORTED_CHANNEL';

  return inboxes
    .filter(inbox => {
      const { channel_type: channelType, medium } = inbox;
      if (channelType === INBOX_TYPES.TWILIO && medium === 'whatsapp') {
        return false;
      }
      if (allowedChannelTypes) {
        return allowedChannelTypes.includes(channelType);
      }
      return true;
    })
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
          : // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
            t(unsupportedKey, { channel: inbox.name }),
      };
    })
    .sort((a, b) => a.label.localeCompare(b.label));
};
