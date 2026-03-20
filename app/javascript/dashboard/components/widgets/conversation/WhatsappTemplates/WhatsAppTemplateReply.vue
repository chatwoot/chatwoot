<script setup>
import WhatsAppTemplateParser from 'dashboard/components-next/whatsapp/WhatsAppTemplateParser.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  template: {
    type: Object,
    default: () => ({}),
  },
  sendButtonLabel: {
    type: String,
    default: '',
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
      :template="props.template"
      :send-button-label="props.sendButtonLabel"
      @send-message="handleSendMessage"
      @reset-template="handleResetTemplate"
    >
      <template
        #actions="{ sendMessage, resetTemplate, disabled, sendButtonText }"
      >
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
            :label="sendButtonText"
            :disabled="disabled"
            @click="sendMessage"
          />
        </footer>
      </template>
    </WhatsAppTemplateParser>
  </div>
</template>
