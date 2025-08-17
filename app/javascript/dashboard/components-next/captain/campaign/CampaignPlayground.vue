<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  selectedTemplate: {
    type: Object,
    default: null,
  },
  templateVariables: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

// Template data based on templates.json examples
const templateExamples = {
  training_video: {
    header: { type: 'VIDEO', content: '🎥 Video Header' },
    body: "Hi {{name}}, here's your training video. Please watch by {{date}}.",
    variables: { name: 'John', date: ' July 31' },
  },
  discount_coupon: {
    body: '🎉 Special offer for you! Get {{discount_percentage}}% off your next purchase. Use the code below at checkout',
    buttons: [{ type: 'COPY_CODE', text: 'Copy offer code' }],
    variables: { discount_percentage: '30' },
  },
  support_callback: {
    body: 'Hello {{name}}, our support team will call you regarding ticket # {{ticket_id}}.',
    buttons: [{ type: 'PHONE_NUMBER', text: 'Call Support' }],
    variables: { name: 'muhsin', ticket_id: '232323' },
  },
  feedback_request: {
    body: "Hey {{name}}, how was your experience with Puma? We'd love your feedback!",
    buttons: [{ type: 'URL', text: 'Leave Feedback' }],
    variables: { name: 'muhsin' },
  },
  order_confirmation: {
    header: { type: 'IMAGE', content: '🖼️ Product Image' },
    body: 'Welcome to our Diwali sale! Get flat 50% off on select items. Hurry now!',
  },
  technician_visit: {
    header: { type: 'TEXT', content: 'Technician visit' },
    body: "Hi {{1}}, we're scheduling a technician visit to {{2}} on {{3}} between {{4}} and {{5}}. Please confirm if this time slot works for you.",
    buttons: [
      { type: 'QUICK_REPLY', text: 'Confirm' },
      { type: 'QUICK_REPLY', text: 'Reschedule' },
    ],
    variables: {
      1: 'John',
      2: '123 Maple St',
      3: '2025-12-31',
      4: '10:00 AM',
      5: '2:00 PM',
    },
  },
};

const getTemplatePreview = () => {
  // If no template selected, return null to show empty state
  if (!props.selectedTemplate) {
    return null;
  }

  const templateName = props.selectedTemplate.name;
  const templateExample = templateExamples[templateName];

  if (templateExample) {
    let processedBody = templateExample.body;

    // Use actual template variables if provided, otherwise fall back to examples
    const variablesToUse =
      Object.keys(props.templateVariables).length > 0
        ? props.templateVariables
        : templateExample.variables;

    // Replace variables with actual or example values
    if (variablesToUse) {
      Object.entries(variablesToUse).forEach(([key, value]) => {
        // Handle both positional ({{1}}) and named ({{name}}) variables
        const pattern = `{{${key}}}`;
        processedBody = processedBody.replace(
          new RegExp(pattern.replace(/[{}]/g, '\\$&'), 'g'),
          value || `{{${key}}}`
        );
      });
    }

    return {
      header: templateExample.header,
      body: processedBody,
      buttons: templateExample.buttons,
    };
  }

  // Fallback for templates not in our examples - use raw template data
  if (props.selectedTemplate.components) {
    const components = props.selectedTemplate.components;
    const headerComponent = components.find(c => c.type === 'HEADER');
    const bodyComponent = components.find(c => c.type === 'BODY');
    const buttonComponent = components.find(c => c.type === 'BUTTONS');

    let processedBody = bodyComponent
      ? bodyComponent.text || 'Message content'
      : 'No message content';

    // Replace variables in body text with actual values
    if (
      props.templateVariables &&
      Object.keys(props.templateVariables).length > 0
    ) {
      Object.entries(props.templateVariables).forEach(([key, value]) => {
        const pattern = `{{${key}}}`;
        processedBody = processedBody.replace(
          new RegExp(pattern.replace(/[{}]/g, '\\$&'), 'g'),
          value || `{{${key}}}`
        );
      });
    }

    return {
      header: headerComponent
        ? {
            type: headerComponent.format || 'TEXT',
            content: headerComponent.text || 'Header',
          }
        : null,
      body: processedBody,
      buttons: buttonComponent ? buttonComponent.buttons : null,
    };
  }

  return null;
};

const templatePreview = computed(() => getTemplatePreview());
</script>

<template>
  <div class="h-full bg-white rounded-lg border border-n-slate-4">
    <!-- Header -->
    <div class="p-4 border-b border-n-slate-4">
      <h3 class="text-lg font-semibold text-n-slate-12">
        {{ t('CAMPAIGN.PLAYGROUND.TITLE') }}
      </h3>
    </div>

    <!-- WhatsApp Preview Container -->
    <div class="flex flex-col p-4 h-96">
      <!-- Empty State (No Template Selected) -->
      <div
        v-if="!templatePreview"
        class="flex flex-col flex-1 justify-center items-center"
      >
        <div class="text-center">
          <h4 class="mb-1 text-sm font-medium text-n-slate-12">
            {{ t('CAMPAIGN.PLAYGROUND.EMPTY_STATE.TITLE') }}
          </h4>
          <p class="text-xs text-n-slate-11">
            {{ t('CAMPAIGN.PLAYGROUND.EMPTY_STATE.SUBTITLE') }}
          </p>
        </div>
      </div>

      <!-- Template Preview (Template Selected) -->
      <div v-else>
        <!-- WhatsApp-style Message Bubble -->
        <div class="flex justify-center">
          <div
            class="p-3 rounded-lg border bg-n-slate-2 text-n-slate-12 border-n-slate-4"
          >
            <!-- Header Media/Text (if exists) -->
            <div v-if="templatePreview.header" class="mb-2">
              <div
                v-if="templatePreview.header.type === 'IMAGE'"
                class="p-2 -m-3 mb-2 text-xs text-center rounded-t-lg bg-n-slate-3"
              >
                {{ templatePreview.header.content }}
              </div>
              <div
                v-else-if="templatePreview.header.type === 'VIDEO'"
                class="p-2 -m-3 mb-2 text-xs text-center rounded-t-lg bg-n-slate-3"
              >
                {{ templatePreview.header.content }}
              </div>
              <div
                v-else-if="templatePreview.header.type === 'TEXT'"
                class="mb-1 text-sm font-semibold"
              >
                {{ templatePreview.header.content }}
              </div>
            </div>

            <!-- Message Body -->
            <div class="text-sm leading-relaxed whitespace-pre-wrap">
              {{ templatePreview.body }}
            </div>

            <!-- Action Buttons -->
            <div v-if="templatePreview.buttons" class="-m-3 mt-2 mt-3">
              <div class="pt-2 border-t border-n-slate-4">
                <div
                  v-for="(button, index) in templatePreview.buttons"
                  :key="index"
                  class="py-2 text-sm font-medium text-center border-b transition-colors cursor-pointer border-n-slate-4 last:border-b-0 hover:bg-n-slate-3 text-n-slate-12"
                >
                  <!-- eslint-disable-next-line vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
                  <span v-if="button.type === 'URL'">🔗</span>
                  <!-- eslint-disable-next-line vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
                  <span v-else-if="button.type === 'PHONE_NUMBER'">📞</span>
                  <!-- eslint-disable-next-line vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
                  <span v-else-if="button.type === 'COPY_CODE'">📋</span>
                  {{ button.text }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Spacer -->
        <div class="flex-1 min-h-4" />

        <!-- Preview Note -->
        <div class="p-3 rounded-lg bg-n-alpha-2">
          <!-- eslint-disable-next-line vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
          <p class="text-xs leading-relaxed text-center text-n-slate-11">
            This is a preview of how your WhatsApp message will appear to
            recipients and may vary slightly depending on the device. Perform a
            test send to confirm the final appearance.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
