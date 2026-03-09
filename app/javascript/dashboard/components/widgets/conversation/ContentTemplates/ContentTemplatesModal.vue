<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import TemplatesPicker from './ContentTemplatesPicker.vue';
import TemplateParser from '../../../../components-next/content-templates/ContentTemplateParser.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  inboxId: {
    type: Number,
    default: undefined,
  },
});

const emit = defineEmits(['onSend', 'cancel', 'update:show']);

const { t } = useI18n();

const selectedContentTemplate = ref(null);

const localShow = computed({
  get() {
    return props.show;
  },
  set(value) {
    emit('update:show', value);
  },
});

const modalHeaderContent = computed(() => {
  return selectedContentTemplate.value
    ? t('CONTENT_TEMPLATES.MODAL.TEMPLATE_SELECTED_SUBTITLE', {
        templateName: selectedContentTemplate.value.friendly_name,
      })
    : t('CONTENT_TEMPLATES.MODAL.SUBTITLE');
});

const pickTemplate = template => {
  selectedContentTemplate.value = template;
};

const onResetTemplate = () => {
  selectedContentTemplate.value = null;
};

const onSendMessage = message => {
  emit('onSend', message);
};

const onClose = () => {
  emit('cancel');
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onClose" size="modal-big">
    <woot-modal-header
      :header-title="$t('CONTENT_TEMPLATES.MODAL.TITLE')"
      :header-content="modalHeaderContent"
    />
    <div class="px-8 py-6 row">
      <TemplatesPicker
        v-if="!selectedContentTemplate"
        :inbox-id="inboxId"
        @on-select="pickTemplate"
      />
      <TemplateParser
        v-else
        :template="selectedContentTemplate"
        @reset-template="onResetTemplate"
        @send-message="onSendMessage"
      >
        <template #actions="{ sendMessage, resetTemplate, disabled }">
          <div class="flex gap-2 mt-6">
            <Button
              :label="t('CONTENT_TEMPLATES.PARSER.GO_BACK_LABEL')"
              color="slate"
              variant="faded"
              class="flex-1"
              @click="resetTemplate"
            />
            <Button
              :label="t('CONTENT_TEMPLATES.PARSER.SEND_MESSAGE_LABEL')"
              class="flex-1"
              :disabled="disabled"
              @click="sendMessage"
            />
          </div>
        </template>
      </TemplateParser>
    </div>
  </woot-modal>
</template>
