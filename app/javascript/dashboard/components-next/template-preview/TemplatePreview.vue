<script setup>
import { computed } from 'vue';
import { TemplateNormalizer } from 'dashboard/services/TemplateNormalizer';

import TextTemplate from 'dashboard/components-next/message/bubbles/Template/Text.vue';
import CardTemplate from 'dashboard/components-next/message/bubbles/Template/Card.vue';
import DynamicCallToActionTemplate from './DynamicCallToActionTemplate.vue';
import DynamicMediaTemplate from './DynamicMediaTemplate.vue';
import WhatsAppTextTemplate from './WhatsAppTextTemplate.vue';
import DynamicQuickReplyTemplate from './DynamicQuickReplyTemplate.vue';

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
    validator: value => ['whatsapp', 'twilio'].includes(value),
  },
});

// Normalize template data and apply variables
const processedTemplate = computed(() => {
  const normalized =
    props.platform === 'whatsapp'
      ? TemplateNormalizer.normalizeWhatsApp(props.template)
      : TemplateNormalizer.normalizeTwilio(props.template);

  // Apply variable substitution to content
  const processText = text => {
    if (!text) return '';
    return text.replace(/\{\{([^}]+)\}\}/g, (match, variable) => {
      const value = props.variables[variable];
      return value !== undefined && value !== '' ? value : `[${variable}]`;
    });
  };

  // Extract content based on platform
  let content = '';
  let imageUrl = '';
  let title = '';
  let footer = '';

  if (props.platform === 'whatsapp') {
    // WhatsApp: get text from body component
    content = normalized.body?.text || '';

    // Get header content for media templates
    if (normalized.header) {
      if (
        normalized.header.format === 'IMAGE' ||
        normalized.header.format === 'VIDEO' ||
        normalized.header.format === 'DOCUMENT'
      ) {
        imageUrl = normalized.header.example?.header_handle?.[0] || '';
      }
      if (normalized.header.format === 'TEXT') {
        title = normalized.header.text || '';
      }
    }

    // Get footer content
    footer = normalized.footer?.text || '';
  } else {
    // Twilio: get body directly
    content = normalized.body || '';

    // Get media URL if available
    if (normalized.media && normalized.media.length > 0) {
      imageUrl = normalized.media[0];
    }
  }

  return {
    ...normalized,
    content: processText(content),
    title: processText(title),
    footer: processText(footer),
    image_url: imageUrl,
    buttons: normalized.buttons || [],
    actions: normalized.actions || [],
  };
});

// Component selection based on template type
const previewComponent = computed(() => {
  const type = processedTemplate.value.type;

  const componentMap = {
    // WhatsApp components
    'whatsapp-text': WhatsAppTextTemplate,
    'whatsapp-text-header': WhatsAppTextTemplate,
    'whatsapp-media-image': DynamicMediaTemplate,
    'whatsapp-media-video': DynamicMediaTemplate,
    'whatsapp-media-document': DynamicMediaTemplate,
    'whatsapp-interactive': DynamicCallToActionTemplate,
    'whatsapp-copy-code': DynamicCallToActionTemplate,

    // Twilio components
    'twilio-text': TextTemplate,
    'twilio-media': DynamicMediaTemplate,
    'twilio-quick-reply': DynamicQuickReplyTemplate,
    'twilio-card': CardTemplate,
  };

  return componentMap[type] || TextTemplate;
});
</script>

<template>
  <div class="template-preview">
    <component :is="previewComponent" :message="processedTemplate" />
  </div>
</template>
