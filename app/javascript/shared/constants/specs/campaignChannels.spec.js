import { describe, it, expect } from 'vitest';
import {
  CAMPAIGN_CHANNEL_STRATEGIES,
  CAMPAIGNABLE_CHANNEL_TYPES,
  ONE_OFF_CHANNEL_TYPES,
  isOneOffCampaignableInbox,
  buildCampaignInboxOptions,
} from '../campaignChannels';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

// Minimal i18n stub so buildCampaignInboxOptions can render the secondary label.
const t = key => `i18n:${key}`;

const inbox = (id, channelType, extra = {}) => ({
  id,
  name: `${channelType} inbox`,
  channel_type: channelType,
  ...extra,
});

describe('campaignChannels abstraction', () => {
  it('marks the four real send channels as one_off campaignable', () => {
    [
      INBOX_TYPES.WHATSAPP,
      INBOX_TYPES.EMAIL,
      INBOX_TYPES.SMS,
      INBOX_TYPES.TWILIO,
    ].forEach(type => {
      expect(CAMPAIGN_CHANNEL_STRATEGIES[type].oneOff).toBe(true);
      expect(CAMPAIGN_CHANNEL_STRATEGIES[type].campaignable).toBe(true);
    });
  });

  it('keeps Website campaignable but not one_off', () => {
    expect(CAMPAIGN_CHANNEL_STRATEGIES[INBOX_TYPES.WEB].campaignable).toBe(
      true
    );
    expect(CAMPAIGN_CHANNEL_STRATEGIES[INBOX_TYPES.WEB].oneOff).toBe(false);
  });

  it('keeps unsupported channels present but not campaignable', () => {
    [
      INBOX_TYPES.FB,
      INBOX_TYPES.TELEGRAM,
      INBOX_TYPES.LINE,
      INBOX_TYPES.API,
    ].forEach(type => {
      expect(CAMPAIGN_CHANNEL_STRATEGIES[type].campaignable).toBe(false);
      expect(CAMPAIGN_CHANNEL_STRATEGIES[type].oneOff).toBe(false);
    });
  });

  it('isOneOffCampaignableInbox special-cases WhatsApp-over-Twilio', () => {
    expect(
      isOneOffCampaignableInbox(
        inbox(1, INBOX_TYPES.TWILIO, { medium: 'whatsapp' })
      )
    ).toBe(true);
    expect(
      isOneOffCampaignableInbox(inbox(1, INBOX_TYPES.TWILIO, { medium: 'sms' }))
    ).toBe(true);
    expect(isOneOffCampaignableInbox(inbox(1, INBOX_TYPES.FB))).toBe(false);
    expect(isOneOffCampaignableInbox(null)).toBe(false);
  });

  it('buildCampaignInboxOptions lists every connected inbox and disables unsupported ones', () => {
    const inboxes = [
      inbox(1, INBOX_TYPES.EMAIL),
      inbox(2, INBOX_TYPES.FB),
      inbox(3, INBOX_TYPES.WHATSAPP),
    ];

    const options = buildCampaignInboxOptions(inboxes, t);

    expect(options).toHaveLength(3);
    const facebook = options.find(o => o.value === 2);
    expect(facebook.disabled).toBe(true);
    expect(facebook.secondaryLabel).toBe(
      'i18n:CAMPAIGN.FORM.INBOX.UNSUPPORTED_CHANNEL'
    );
    const email = options.find(o => o.value === 1);
    expect(email.disabled).toBe(false);
    expect(email.secondaryLabel).toBe('');
  });

  it('is resilient to unknown channel types', () => {
    const options = buildCampaignInboxOptions(
      [inbox(9, 'Channel::Unknown')],
      t
    );
    expect(options[0].disabled).toBe(true);
  });

  it('exports lists of campaignable / one_off channel types', () => {
    expect(CAMPAIGNABLE_CHANNEL_TYPES).toContain(INBOX_TYPES.EMAIL);
    expect(ONE_OFF_CHANNEL_TYPES).toContain(INBOX_TYPES.WHATSAPP);
    expect(ONE_OFF_CHANNEL_TYPES).not.toContain(INBOX_TYPES.WEB);
  });
});
