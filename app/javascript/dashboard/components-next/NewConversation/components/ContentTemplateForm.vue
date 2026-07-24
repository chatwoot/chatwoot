<script setup>
import ContentTemplateParser from 'dashboard/components-next/content-templates/ContentTemplateParser.vue';
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
  <div class="flex flex-col gap-4 px-4 pt-6 pb-5 items-start w-[28.75rem]">
    <div class="w-full">
      <ContentTemplateParser
        :template="template"
        @send-message="handleSendMessage"
        @back="handleBack"
      >
        <template #actions="{ sendMessage, goBack, disabled }">
          <div class="flex gap-3 justify-between items-end w-full h-14">
            <Button
              :label="t('CONTENT_TEMPLATES.FORM.BACK_BUTTON')"
              color="slate"
              variant="faded"
              class="w-full font-medium"
              @click="goBack"
            />
            <Button
              :label="t('CONTENT_TEMPLATES.FORM.SEND_MESSAGE_BUTTON')"
              class="w-full font-medium"
              :disabled="disabled"
              @click="sendMessage"
            />
          </div>
        </template>
      </ContentTemplateParser>
    </div>
  </div>
</template>
