import { INBOX_TYPES } from 'dashboard/helper/inbox';

export const WHATSAPP_ANALYTICS_STATUSES = ['processing', 'completed'];

export const canShowWhatsAppCampaignAnalytics = (campaign, isEnterprise) =>
  isEnterprise &&
  campaign?.inbox?.channel_type === INBOX_TYPES.WHATSAPP &&
  WHATSAPP_ANALYTICS_STATUSES.includes(campaign?.campaign_status);
