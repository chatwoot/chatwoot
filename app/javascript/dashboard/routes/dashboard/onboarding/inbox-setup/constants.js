import { CHANNEL_TYPES } from 'dashboard/helper/inbox';

// Channels whose connect flow opens the channels dialog preselected to their
// in-dialog step — Facebook (page picker) and the credential-form channels
// (Telegram, Line) — rather than redirecting through OAuth.
export const DIALOG_CHANNELS = [
  CHANNEL_TYPES.FACEBOOK,
  CHANNEL_TYPES.TELEGRAM,
  CHANNEL_TYPES.LINE,
];

// Suggested channels (in priority order) to offer as rows when nothing is
// detected, so the step isn't empty. The mainstream OAuth channels show on
// configured installs, while credential-free Telegram/LINE keep the list
// non-empty on a bare self-host.
export const DEFAULT_CHANNEL_TYPES = [
  CHANNEL_TYPES.WHATSAPP,
  CHANNEL_TYPES.FACEBOOK,
  CHANNEL_TYPES.INSTAGRAM,
  CHANNEL_TYPES.TELEGRAM,
  CHANNEL_TYPES.LINE,
];

// Channels offered in the onboarding "View all" dialog. `inbox` is a stub shaped
// like a real inbox so ChannelIcon can resolve the icon from the shared provider.
// With `use-brand-icon`, ChannelIcon renders the full-color brand logo when one
// exists and falls back to the monochrome glyph otherwise, so no per-channel
// style flag is needed. Entries without a channel type (Voice, Other Email
// Providers) render `fallbackIcon` instead. `form: true` swaps the grid for an
// inline credential form; `setupLater: true` defers the channel to in-app setup
// for this phase. `labelKey` is an i18n key — most reuse the shared channel
// titles from the inbox settings (INBOX_MGMT.ADD.AUTH.CHANNEL.*.TITLE) so the
// names translate without duplicating strings; resolve it with `t()` at display.
export const CHANNEL_LIST = [
  {
    type: 'website',
    labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.WEBSITE.TITLE',
    inbox: { channel_type: 'Channel::WebWidget' },
  },
  {
    type: 'whatsapp',
    labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.WHATSAPP.TITLE',
    inbox: { channel_type: 'Channel::Whatsapp' },
  },
  {
    type: 'instagram',
    labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.INSTAGRAM.TITLE',
    inbox: { channel_type: 'Channel::Instagram' },
  },
  {
    type: 'facebook',
    labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.FACEBOOK.TITLE',
    inbox: { channel_type: 'Channel::FacebookPage' },
  },
  {
    type: 'tiktok',
    labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.TIKTOK.TITLE',
    inbox: { channel_type: 'Channel::Tiktok' },
  },
  {
    type: 'telegram',
    labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.TELEGRAM.TITLE',
    inbox: { channel_type: 'Channel::Telegram' },
    form: true,
  },
  {
    type: 'line',
    labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.LINE.TITLE',
    inbox: { channel_type: 'Channel::Line' },
    form: true,
  },
  // Email channels (including Gmail/Outlook OAuth) are set up later in-app for
  // this phase; they will be enabled in a future PR.
  {
    type: 'gmail',
    labelKey: 'ONBOARDING_INBOX_SETUP.CHANNELS.GMAIL',
    inbox: { channel_type: 'Channel::Email', provider: 'google' },
    setupLater: true,
  },
  {
    type: 'outlook',
    labelKey: 'ONBOARDING_INBOX_SETUP.CHANNELS.OUTLOOK',
    inbox: { channel_type: 'Channel::Email', provider: 'microsoft' },
    setupLater: true,
  },
  {
    type: 'sms',
    labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.SMS.TITLE',
    inbox: { channel_type: 'Channel::Sms' },
    setupLater: true,
  },
  {
    type: 'api',
    labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.API.TITLE',
    inbox: { channel_type: 'Channel::Api' },
    setupLater: true,
  },
  {
    type: 'voice',
    labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.VOICE.TITLE',
    fallbackIcon: 'i-woot-voice',
    setupLater: true,
  },
  {
    type: 'email',
    labelKey: 'ONBOARDING_INBOX_SETUP.CHANNELS.OTHER_EMAIL',
    fallbackIcon: 'i-woot-mail',
    setupLater: true,
  },
];

const channelByType = type =>
  CHANNEL_LIST.find(channel => channel.type === type);

// Icons shown next to "View all" when every detected channel is already
// connected — a representative trio sourced from CHANNEL_LIST so the inbox stubs
// aren't duplicated.
export const FALLBACK_PREVIEW_CHANNELS = ['gmail', 'tiktok', 'whatsapp'].map(
  channelByType
);

// Social channels that detected brand_info socials map to, keyed by social type
// in the order they're offered as rows. Derived from CHANNEL_LIST so channel
// identity (label, channel_type) has a single source. Keys mirror
// SocialLinkParser::SOCIAL_DOMAIN_MAP.
const SOCIAL_PLATFORM_TYPES = [
  'whatsapp',
  'facebook',
  'line',
  'instagram',
  'telegram',
  'tiktok',
];

export const SOCIAL_PLATFORMS = Object.fromEntries(
  SOCIAL_PLATFORM_TYPES.map(type => {
    const { labelKey, inbox } = channelByType(type);
    return [type, { labelKey, channelType: inbox.channel_type }];
  })
);

// Mailbox providers inferred from the signup domain's MX records, keyed by
// Channel::Email#provider. Derived from CHANNEL_LIST's email entries.
export const EMAIL_PROVIDERS = Object.fromEntries(
  CHANNEL_LIST.filter(channel => channel.inbox?.provider).map(channel => [
    channel.inbox.provider,
    { labelKey: channel.labelKey },
  ])
);
