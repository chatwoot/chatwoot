import { useI18n } from 'vue-i18n';

export const CRM_ORIGIN_SOURCE_META = {
  meta_ctwa: {
    icon: 'i-lucide-message-circle',
    labelKey: 'CRM_KANBAN.ORIGIN.META_CTWA',
  },
  meta_organic: {
    icon: 'i-lucide-facebook',
    labelKey: 'CRM_KANBAN.ORIGIN.META_ORGANIC',
  },
  google_ads: {
    icon: 'i-lucide-search',
    labelKey: 'CRM_KANBAN.ORIGIN.GOOGLE_ADS',
  },
  tiktok_ads: {
    icon: 'i-lucide-music-2',
    labelKey: 'CRM_KANBAN.ORIGIN.TIKTOK_ADS',
  },
  meta_paid: {
    icon: 'i-lucide-megaphone',
    labelKey: 'CRM_KANBAN.ORIGIN.META_PAID',
  },
  tracked_link: {
    icon: 'i-lucide-link',
    labelKey: 'CRM_KANBAN.ORIGIN.TRACKED_LINK',
  },
};

const FALLBACK_SOURCE = 'meta_ctwa';
const UNKNOWN_SOURCE_META = {
  icon: 'i-lucide-circle-help',
  labelKey: 'CRM_KANBAN.ORIGIN.UNKNOWN',
};

const normalizeSource = source => String(source || FALLBACK_SOURCE).trim();

const sourceMetaFor = source =>
  CRM_ORIGIN_SOURCE_META[normalizeSource(source)] || UNKNOWN_SOURCE_META;

const headlineFor = campaign =>
  campaign?.headline ||
  campaign?.utm_campaign ||
  campaign?.name ||
  campaign?.source_id ||
  '';

export const buildCrmOrigin = campaign => {
  if (!campaign || typeof campaign !== 'object') return null;

  const source = normalizeSource(campaign.source);
  const meta = sourceMetaFor(source);
  const name = String(headlineFor(campaign)).trim();

  return {
    source,
    icon: meta.icon,
    labelKey: meta.labelKey,
    name,
    sourceId: campaign.source_id,
  };
};

export const buildCrmOriginFromCampaigns = campaigns => {
  const origins = Array.isArray(campaigns)
    ? campaigns.map(buildCrmOrigin).filter(Boolean)
    : [];

  if (!origins.length) return null;

  return {
    ...origins[0],
    extraCount: origins.length - 1,
    origins,
  };
};

export function useCrmOrigin() {
  const { t } = useI18n();

  const sourceLabel = origin => {
    switch (origin?.source) {
      case 'meta_ctwa':
        return t('CRM_KANBAN.ORIGIN.META_CTWA');
      case 'meta_organic':
        return t('CRM_KANBAN.ORIGIN.META_ORGANIC');
      case 'google_ads':
        return t('CRM_KANBAN.ORIGIN.GOOGLE_ADS');
      case 'tiktok_ads':
        return t('CRM_KANBAN.ORIGIN.TIKTOK_ADS');
      case 'meta_paid':
        return t('CRM_KANBAN.ORIGIN.META_PAID');
      case 'tracked_link':
        return t('CRM_KANBAN.ORIGIN.TRACKED_LINK');
      default:
        return t('CRM_KANBAN.ORIGIN.UNKNOWN');
    }
  };

  const formatOriginLabel = origin => {
    if (!origin) return '';
    const label = sourceLabel(origin);
    return origin.name ? `${label}: ${origin.name}` : label;
  };

  const formatOriginTitle = origin => {
    if (!origin) return '';
    const origins = origin.origins || [origin];
    return origins.map(formatOriginLabel).join(' · ');
  };

  return {
    originFromCampaign: buildCrmOrigin,
    originFromCampaigns: buildCrmOriginFromCampaigns,
    formatOriginLabel,
    formatOriginTitle,
  };
}
