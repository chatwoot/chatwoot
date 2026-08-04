<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { isValidURL } from 'dashboard/helper/URLHelper';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import HeaderImageInput from './HeaderImageInput.vue';

const props = defineProps({
  modelValue: {
    type: Object,
    required: true,
  },
});
const emit = defineEmits(['update:modelValue', 'update:headerImageValid']);
const BODY_TEXT_MAX_LENGTH = 1024;
const FOOTER_TEXT_MAX_LENGTH = 60;
const BUTTON_TEXT_MAX_LENGTH = 20;

const { t } = useI18n();

const updateField = (field, value) => {
  emit('update:modelValue', { ...props.modelValue, [field]: value });
};

const buttonUrlError = computed(() => {
  const { buttonUrl } = props.modelValue;
  return buttonUrl && !isValidURL(buttonUrl)
    ? t('INTERACTIVE_MESSAGES.FIELDS.INVALID_URL')
    : '';
});
</script>

<template>
  <div class="flex flex-col gap-4">
    <TextArea
      :model-value="modelValue.bodyText"
      :label="t('INTERACTIVE_MESSAGES.FIELDS.BODY_TEXT')"
      :placeholder="t('INTERACTIVE_MESSAGES.FIELDS.BODY_TEXT_PLACEHOLDER')"
      :max-length="BODY_TEXT_MAX_LENGTH"
      show-character-count
      auto-height
      @update:model-value="value => updateField('bodyText', value)"
    />
    <Input
      :model-value="modelValue.footerText"
      :label="t('INTERACTIVE_MESSAGES.FIELDS.FOOTER_TEXT')"
      :placeholder="t('INTERACTIVE_MESSAGES.FIELDS.FOOTER_TEXT_PLACEHOLDER')"
      :maxlength="FOOTER_TEXT_MAX_LENGTH"
      @update:model-value="value => updateField('footerText', value)"
    />
    <HeaderImageInput
      :model-value="modelValue.headerMediaUrl"
      @update:model-value="value => updateField('headerMediaUrl', value)"
      @update:valid="value => emit('update:headerImageValid', value)"
    />
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <Input
        :model-value="modelValue.buttonText"
        :label="t('INTERACTIVE_MESSAGES.FIELDS.BUTTON_TEXT')"
        :placeholder="t('INTERACTIVE_MESSAGES.FIELDS.BUTTON_TEXT_PLACEHOLDER')"
        :maxlength="BUTTON_TEXT_MAX_LENGTH"
        @update:model-value="value => updateField('buttonText', value)"
      />
      <Input
        :model-value="modelValue.buttonUrl"
        :label="t('INTERACTIVE_MESSAGES.FIELDS.BUTTON_URL')"
        :placeholder="t('INTERACTIVE_MESSAGES.FIELDS.BUTTON_URL_PLACEHOLDER')"
        :message="buttonUrlError"
        :message-type="buttonUrlError ? 'error' : 'info'"
        @update:model-value="value => updateField('buttonUrl', value)"
      />
    </div>
  </div>
</template>
