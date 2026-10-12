import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { getMaxUploadSizeByChannel } from '@chatwoot/utils';
import {
  getImageOptimizationPolicy,
  imageNeedsOptimization,
  getImageLadder,
  WHATSAPP_STANDARD_MAX_SIDE,
  WHATSAPP_HD_MAX_SIDE,
} from '../imageOptimizationPolicy';

const MB = 1024 * 1024;
const installationLimit = 40;

const channels = [
  {
    name: 'WhatsApp Cloud',
    channel_type: INBOX_TYPES.WHATSAPP,
    provider: 'whatsapp_cloud',
    limit: 5,
    hd: true,
  },
  {
    name: 'WhatsApp 360dialog',
    channel_type: INBOX_TYPES.WHATSAPP,
    provider: 'default',
    limit: 5,
    hd: true,
  },
  {
    name: 'Twilio WhatsApp',
    channel_type: INBOX_TYPES.TWILIO,
    medium: 'whatsapp',
    limit: 5,
  },
  {
    name: 'Twilio SMS',
    channel_type: INBOX_TYPES.TWILIO,
    medium: 'sms',
    limit: 5,
  },
  { name: 'Facebook', channel_type: INBOX_TYPES.FB, limit: 8 },
  { name: 'Instagram', channel_type: INBOX_TYPES.INSTAGRAM, limit: 16 },
  { name: 'Line', channel_type: INBOX_TYPES.LINE, limit: 10 },
  { name: 'TikTok', channel_type: INBOX_TYPES.TIKTOK, limit: 3 },
];

const noLimit = [
  INBOX_TYPES.WEB,
  INBOX_TYPES.EMAIL,
  INBOX_TYPES.API,
  INBOX_TYPES.TELEGRAM,
  INBOX_TYPES.SMS,
];

const policyFor = (inbox, mime = 'image/jpeg', limit = installationLimit) =>
  getImageOptimizationPolicy({ inbox, mime, installationLimit: limit });

describe('getImageOptimizationPolicy', () => {
  channels.forEach(({ name, limit, hd, ...inbox }) => {
    it(`returns the policy for ${name}`, () => {
      const channelLimit = getMaxUploadSizeByChannel({
        channelType: inbox.channel_type,
        medium: inbox.medium,
        mime: 'image/png',
      });
      expect(channelLimit).toBe(limit);

      const policy = policyFor(inbox, 'image/png');
      expect(policy.limitBytes).toBe(limit * MB);
      expect(policy.maxBytes).toBe(limit * MB * 0.9);
      expect(policy.maxBytes).toBeLessThan(channelLimit * MB);
      expect(policy.supportsHd).toBe(!!hd);
      if (hd) {
        expect(policy.standardMaxSide).toBe(1600);
        expect(policy.hdMaxSide).toBe(4096);
      } else {
        expect(policy.standardMaxSide).toBeNull();
        expect(policy.hdMaxSide).toBeNull();
        expect(policy.hdLadder).toBeNull();
      }
    });
  });

  it('uses 4.5 MB as maxBytes for WhatsApp', () => {
    expect(policyFor({ channel_type: INBOX_TYPES.WHATSAPP }).maxBytes).toBe(
      4.5 * MB
    );
  });

  noLimit.forEach(channelType => {
    it(`returns null for ${channelType}`, () => {
      expect(policyFor({ channel_type: channelType })).toBeNull();
    });
  });

  it('returns null without inbox or channel_type', () => {
    expect(policyFor(undefined)).toBeNull();
    expect(policyFor({})).toBeNull();
  });

  it('returns null for GIF and webp', () => {
    const inbox = { channel_type: INBOX_TYPES.WHATSAPP };
    expect(policyFor(inbox, 'image/gif')).toBeNull();
    expect(policyFor(inbox, 'image/webp')).toBeNull();
  });

  it('returns null when the installation limit is not above the channel limit', () => {
    const inbox = { channel_type: INBOX_TYPES.WHATSAPP };
    expect(policyFor(inbox, 'image/jpeg', 3)).toBeNull();
    expect(policyFor(inbox, 'image/jpeg', 5)).toBeNull();
  });

  it('builds an HD ladder above standard that ends with the standard steps', () => {
    const policy = policyFor({ channel_type: INBOX_TYPES.WHATSAPP });
    const { hdLadder, standardLadder } = policy;
    expect(hdLadder[0].maxSide).toBe(WHATSAPP_HD_MAX_SIDE);
    expect(hdLadder[0].maxSide).toBeGreaterThan(WHATSAPP_STANDARD_MAX_SIDE);
    expect(hdLadder.slice(-standardLadder.length)).toEqual(standardLadder);
    const sides = hdLadder.map(s => s.maxSide);
    expect([...sides].sort((a, b) => b - a)).toEqual(sides);
    hdLadder.forEach(s => {
      expect(s.quality).toBeGreaterThan(0);
      expect(s.quality).toBeLessThanOrEqual(1);
    });
  });
});

describe('imageNeedsOptimization', () => {
  const whatsapp = policyFor({ channel_type: INBOX_TYPES.WHATSAPP });
  const facebook = policyFor({ channel_type: INBOX_TYPES.FB });

  it('is true when size exceeds the channel limit', () => {
    expect(
      imageNeedsOptimization(whatsapp, 'hd', {
        size: 5 * MB + 1,
        longestSide: 100,
      })
    ).toBe(true);
    expect(
      imageNeedsOptimization(whatsapp, 'standard', {
        size: 5 * MB,
        longestSide: 100,
      })
    ).toBe(false);
  });

  it('crops by side with the profile cap, only on WhatsApp', () => {
    expect(
      imageNeedsOptimization(whatsapp, 'standard', {
        size: MB,
        longestSide: 1601,
      })
    ).toBe(true);
    expect(
      imageNeedsOptimization(whatsapp, 'standard', {
        size: MB,
        longestSide: 1600,
      })
    ).toBe(false);
    expect(
      imageNeedsOptimization(whatsapp, 'hd', { size: MB, longestSide: 6000 })
    ).toBe(true);
    expect(
      imageNeedsOptimization(whatsapp, 'hd', { size: MB, longestSide: 4096 })
    ).toBe(false);
    expect(
      imageNeedsOptimization(facebook, 'standard', {
        size: MB,
        longestSide: 6000,
      })
    ).toBe(false);
  });

  it('ignores the side when longestSide is missing', () => {
    expect(imageNeedsOptimization(whatsapp, 'standard', { size: MB })).toBe(
      false
    );
    expect(
      imageNeedsOptimization(whatsapp, 'standard', {
        size: MB,
        longestSide: null,
      })
    ).toBe(false);
  });
});

describe('getImageLadder', () => {
  const whatsapp = policyFor({ channel_type: INBOX_TYPES.WHATSAPP });
  const facebook = policyFor({ channel_type: INBOX_TYPES.FB });

  it('returns the HD ladder only for hd when it exists', () => {
    expect(getImageLadder(whatsapp, 'hd')).toBe(whatsapp.hdLadder);
    expect(getImageLadder(whatsapp, 'standard')).toBe(whatsapp.standardLadder);
    expect(getImageLadder(facebook, 'hd')).toBe(facebook.standardLadder);
  });
});
