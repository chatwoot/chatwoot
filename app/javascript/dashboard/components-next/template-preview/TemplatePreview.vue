<script setup>
import { computed } from 'vue';
import { TemplateNormalizer } from 'dashboard/services/TemplateNormalizer';

import TextTemplate from 'dashboard/components-next/message/bubbles/Template/Text.vue';
import MediaTemplate from 'dashboard/components-next/message/bubbles/Template/Media.vue';
import CallToActionTemplate from 'dashboard/components-next/message/bubbles/Template/CallToAction.vue';
import QuickReplyTemplate from 'dashboard/components-next/message/bubbles/Template/QuickReply.vue';
import CardTemplate from 'dashboard/components-next/message/bubbles/Template/Card.vue';

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
    image_url: imageUrl,
    buttons: normalized.buttons || [],
  };
});

// Component selection based on template type
const previewComponent = computed(() => {
  const type = processedTemplate.value.type;

  const componentMap = {
    // WhatsApp components
    'whatsapp-text': TextTemplate,
    'whatsapp-text-header': TextTemplate,
    'whatsapp-media-image': MediaTemplate,
    'whatsapp-media-video': MediaTemplate,
    'whatsapp-media-document': MediaTemplate,
    'whatsapp-interactive': CallToActionTemplate,
    'whatsapp-copy-code': CallToActionTemplate,

    // Twilio components
    'twilio-text': TextTemplate,
    'twilio-media': MediaTemplate,
    'twilio-quick-reply': QuickReplyTemplate,
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
