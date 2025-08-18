<script setup>
/**
 * This component handles parsing and sending WhatsApp message templates.
 * It works as follows:
 * 1. Displays the template text with variable placeholders.
 * 2. Generates input fields for each variable in the template.
 * 3. Validates that all variables are filled before sending.
 * 4. Replaces placeholders with user-provided values.
 * 5. Emits events to send the processed message or reset the template.
 */
import WhatsAppTemplateParser from 'dashboard/components-next/whatsapp/WhatsAppTemplateParser.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

defineProps({
  template: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['sendMessage', 'resetTemplate']);

const handleSendMessage = payload => {
  emit('sendMessage', payload);
};

const handleResetTemplate = () => {
  emit('resetTemplate');
};
</script>

<template>
  <div class="w-full">
    <WhatsAppTemplateParser
      :template="template"
      @send-message="handleSendMessage"
      @reset-template="handleResetTemplate"
    >
      <template #actions="{ sendMessage, resetTemplate, disabled }">
        <footer class="flex gap-2 justify-end">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('WHATSAPP_TEMPLATES.PARSER.GO_BACK_LABEL')"
            @click="resetTemplate"
          />
          <NextButton
            type="button"
            :label="$t('WHATSAPP_TEMPLATES.PARSER.SEND_MESSAGE_LABEL')"
            :disabled="disabled"
            @click="sendMessage"
          />
        </footer>
      </template>
    </WhatsAppTemplateParser>
  </div>
</template>
