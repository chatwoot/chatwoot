import { TemplateTypeDetector } from 'dashboard/services/TemplateTypeDetector';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import {
  PLATFORMS,
  TEMPLATE_TYPES,
} from 'dashboard/services/TemplateConstants';

const TEMPLATE_TYPE_KEYS = {
  [TEMPLATE_TYPES.WHATSAPP_TEXT]: 'TEXT',
  [TEMPLATE_TYPES.WHATSAPP_TEXT_HEADER]: 'TEXT',
  [TEMPLATE_TYPES.WHATSAPP_MEDIA_IMAGE]: 'IMAGE',
  [TEMPLATE_TYPES.WHATSAPP_MEDIA_VIDEO]: 'VIDEO',
  [TEMPLATE_TYPES.WHATSAPP_MEDIA_DOCUMENT]: 'DOCUMENT',
  [TEMPLATE_TYPES.WHATSAPP_INTERACTIVE]: 'CALL_TO_ACTION',
  [TEMPLATE_TYPES.WHATSAPP_COPY_CODE]: 'COPY_CODE',
  [TEMPLATE_TYPES.TWILIO_TEXT]: 'TEXT',
  [TEMPLATE_TYPES.TWILIO_MEDIA]: 'MEDIA',
  [TEMPLATE_TYPES.TWILIO_QUICK_REPLY]: 'QUICK_REPLY',
  [TEMPLATE_TYPES.TWILIO_CALL_TO_ACTION]: 'CALL_TO_ACTION',
  [TEMPLATE_TYPES.TWILIO_CARD]: 'CATALOG',
};

export const groupTemplates = templateRecords => {
  const groupedTemplates = new Map();

  templateRecords.forEach(({ template, inbox, lastUpdatedAt }) => {
    const platform =
      inbox.channel_type === INBOX_TYPES.TWILIO
        ? PLATFORMS.TWILIO
        : PLATFORMS.WHATSAPP;
    const providerAccountId =
      inbox.provider_config?.business_account_id ||
      inbox.account_sid ||
      inbox.id;
    const name = template.name || template.friendly_name;
    const providerTemplateIdentifier = template.id || template.content_sid;
    const templateIdentifier = providerTemplateIdentifier || name;
    const key = JSON.stringify(
      providerTemplateIdentifier
        ? [
            platform,
            providerAccountId,
            providerTemplateIdentifier,
            template.language,
          ]
        : [platform, inbox.id, name, template.language, template]
    );
    const searchableContent = JSON.stringify(
      template.components || template.types || template.body || []
    );
    const normalizedTemplate = {
      ...template,
      id: templateIdentifier,
      name,
      platform,
      key,
      inboxes: [inbox],
      inboxNames: inbox.name,
      lastUpdatedAt,
      searchableContent,
    };
    const existingTemplate = groupedTemplates.get(key);

    if (existingTemplate) {
      const inboxes = [...existingTemplate.inboxes, inbox];
      const incomingIsNewer =
        lastUpdatedAt &&
        (!existingTemplate.lastUpdatedAt ||
          new Date(lastUpdatedAt) > new Date(existingTemplate.lastUpdatedAt));

      groupedTemplates.set(key, {
        ...(incomingIsNewer ? normalizedTemplate : existingTemplate),
        inboxes,
        inboxNames: inboxes.map(item => item.name).join(', '),
        lastUpdatedAt: incomingIsNewer
          ? lastUpdatedAt
          : existingTemplate.lastUpdatedAt,
      });
      return;
    }

    groupedTemplates.set(key, normalizedTemplate);
  });

  return [...groupedTemplates.values()].sort((first, second) =>
    first.name.localeCompare(second.name)
  );
};

export const formatTemplateLabel = value => {
  if (!value) return '—';

  return value
    .toLowerCase()
    .replaceAll('_', ' ')
    .replace(/\b\w/g, character => character.toUpperCase());
};

export const formatTemplateLanguage = language => {
  if (!language) return '—';

  const locale = language.replace('_', '-');
  const languageCode = locale.split('-')[0];
  const displayName = new Intl.DisplayNames([locale], {
    type: 'language',
  }).of(languageCode);

  return `${displayName} (${locale})`;
};

export const formatTemplateDate = value => {
  if (!value) return '—';

  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
  }).format(new Date(value));
};

export const templateStatusClasses = status => {
  const classes = {
    approved: 'bg-n-teal-3 text-n-teal-11',
    pending: 'bg-n-amber-3 text-n-amber-11',
    rejected: 'bg-n-ruby-3 text-n-ruby-11',
    paused: 'bg-n-amber-3 text-n-amber-11',
    disabled: 'bg-n-alpha-2 text-n-slate-11',
  };

  return classes[status?.toLowerCase()] || 'bg-n-alpha-2 text-n-slate-11';
};

export const templateTypeKey = template => {
  const type =
    template.platform === PLATFORMS.TWILIO
      ? TemplateTypeDetector.detectTwilioType(template)
      : TemplateTypeDetector.detectWhatsAppType(template);
  return TEMPLATE_TYPE_KEYS[type] || 'TEXT';
};
