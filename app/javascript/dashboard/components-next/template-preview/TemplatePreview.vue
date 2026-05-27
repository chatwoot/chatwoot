<script setup>
import { computed } from 'vue';
import { TemplateNormalizer } from 'dashboard/services/TemplateNormalizer';
import {
  PLATFORMS,
  TEMPLATE_TYPES,
  WA_HEADER_FORMATS,
  WA_MEDIA_FORMATS,
} from 'dashboard/services/TemplateConstants';

import CardTemplate from './CardTemplate.vue';
import CallToActionTemplate from './CallToActionTemplate.vue';
import MediaTemplate from './MediaTemplate.vue';
import WhatsAppTextTemplate from './WhatsAppTextTemplate.vue';
import QuickReplyTemplate from './QuickReplyTemplate.vue';

const props = defineProps({
  template: {
    type: Object,
    required: true,
  },
  variables: {
    type: Object,
    default: () => ({}),
  },
  platform: {
    type: String,
    required: true,
    validator: value => Object.values(PLATFORMS).includes(value),
  },
});

const COMPONENT_MAP = {
  [TEMPLATE_TYPES.WHATSAPP_TEXT]: WhatsAppTextTemplate,
  [TEMPLATE_TYPES.WHATSAPP_TEXT_HEADER]: WhatsAppTextTemplate,
  [TEMPLATE_TYPES.WHATSAPP_MEDIA_IMAGE]: MediaTemplate,
  [TEMPLATE_TYPES.WHATSAPP_MEDIA_VIDEO]: MediaTemplate,
  [TEMPLATE_TYPES.WHATSAPP_MEDIA_DOCUMENT]: MediaTemplate,
  [TEMPLATE_TYPES.WHATSAPP_INTERACTIVE]: CallToActionTemplate,
  [TEMPLATE_TYPES.WHATSAPP_COPY_CODE]: CallToActionTemplate,
  [TEMPLATE_TYPES.TWILIO_TEXT]: WhatsAppTextTemplate,
  [TEMPLATE_TYPES.TWILIO_MEDIA]: MediaTemplate,
  [TEMPLATE_TYPES.TWILIO_QUICK_REPLY]: QuickReplyTemplate,
  [TEMPLATE_TYPES.TWILIO_CALL_TO_ACTION]: CallToActionTemplate,
  [TEMPLATE_TYPES.TWILIO_CARD]: CardTemplate,
};

const substituteVariables = (text, variables) => {
  if (!text) return '';
  return text.replace(/\{\{([^}]+)\}\}/g, (match, variable) => {
    const value = variables[variable];
    return value !== undefined && value !== '' ? value : `[${variable}]`;
  });
};

const processedTemplate = computed(() => {
  const normalized = TemplateNormalizer.normalize(
    props.template,
    props.platform
  );

  let content = '';
  let imageUrl = '';
  let title = '';
  let footer = '';

  if (props.platform === PLATFORMS.WHATSAPP) {
    content = normalized.body?.text || '';

    if (normalized.header) {
      if (WA_MEDIA_FORMATS.includes(normalized.header.format)) {
        imageUrl = normalized.header.example?.header_handle?.[0] || '';
      }
      if (normalized.header.format === WA_HEADER_FORMATS.TEXT) {
        title = normalized.header.text || '';
      }
    }

    footer = normalized.footer?.text || '';
  } else {
    content = normalized.body || '';

    if (normalized.media && normalized.media.length > 0) {
      imageUrl = normalized.media[0];
    }
  }

  const buttons = normalized.buttons?.length
    ? normalized.buttons
    : normalized.actions || [];

  return {
    ...normalized,
    content: substituteVariables(content, props.variables),
    title: substituteVariables(title, props.variables),
    footer: substituteVariables(footer, props.variables),
    image_url: substituteVariables(imageUrl, props.variables),
    buttons,
    actions: normalized.actions || [],
  };
});

const previewComponent = computed(
  () => COMPONENT_MAP[processedTemplate.value.type] || WhatsAppTextTemplate
);
</script>

<template>
  <div class="template-preview">
    <component :is="previewComponent" :message="processedTemplate" />
  </div>
</template>
