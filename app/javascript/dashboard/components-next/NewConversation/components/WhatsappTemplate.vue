<script setup>
import WhatsAppTemplateParser from 'dashboard/components-next/whatsapp/WhatsAppTemplateParser.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useI18n } from 'vue-i18n';

defineProps({
  template: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['sendMessage', 'back']);

const { t } = useI18n();

const handleSendMessage = payload => {
  emit('sendMessage', payload);
};

const handleBack = () => {
  emit('back');
};
</script>

<template>
  <div
    class="absolute top-full mt-1.5 max-h-[30rem] overflow-y-auto ltr:left-0 rtl:right-0 flex flex-col gap-4 px-4 pt-6 pb-5 items-start w-[28.75rem] h-auto bg-n-solid-2 border border-n-strong shadow-sm rounded-lg"
  >
    <div class="w-full">
      <WhatsAppTemplateParser
        :template="template"
        @send-message="handleSendMessage"
        @back="handleBack"
      >
        <template #actions="{ sendMessage, goBack, disabled }">
          <div class="flex gap-3 justify-between items-end w-full h-14">
            <Button
              :label="
                t(
                  'COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_OPTIONS.TEMPLATE_PARSER.BACK'
                )
              "
              color="slate"
              variant="faded"
              class="w-full font-medium"
              @click="goBack"
            />
            <Button
              :label="
                t(
                  'COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_OPTIONS.TEMPLATE_PARSER.SEND_MESSAGE'
                )
              "
              class="w-full font-medium"
              :disabled="disabled"
              @click="sendMessage"
            />
          </div>
        </template>
      </WhatsAppTemplateParser>
    </div>
  </div>
</template>
