<script setup>
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import HeaderImageInput from './HeaderImageInput.vue';

const props = defineProps({
  modelValue: {
    type: Object,
    required: true,
  },
  showHeaderImage: {
    type: Boolean,
    default: true,
  },
  showFooterText: {
    type: Boolean,
    default: true,
  },
});
const emit = defineEmits(['update:modelValue', 'update:headerImageValid']);
const MAX_BUTTONS = 3;
const BUTTON_TITLE_MAX_LENGTH = 20;
const BODY_TEXT_MAX_LENGTH = 1024;

const { t } = useI18n();

const updateField = (field, value) => {
  emit('update:modelValue', { ...props.modelValue, [field]: value });
};

const updateButton = (index, value) => {
  const buttons = props.modelValue.buttons.map((button, buttonIndex) =>
    buttonIndex === index ? { ...button, text: value } : button
  );
  updateField('buttons', buttons);
};

const addButton = () => {
  if (props.modelValue.buttons.length >= MAX_BUTTONS) return;
  updateField('buttons', [
    ...props.modelValue.buttons,
    { id: `btn_${props.modelValue.buttons.length + 1}`, text: '' },
  ]);
};

const removeButton = index => {
  updateField(
    'buttons',
    props.modelValue.buttons.filter((_, buttonIndex) => buttonIndex !== index)
  );
};
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
      v-if="showFooterText"
      :model-value="modelValue.footerText"
      :label="t('INTERACTIVE_MESSAGES.FIELDS.FOOTER_TEXT')"
      :placeholder="t('INTERACTIVE_MESSAGES.FIELDS.FOOTER_TEXT_PLACEHOLDER')"
      @update:model-value="value => updateField('footerText', value)"
    />
    <HeaderImageInput
      v-if="showHeaderImage"
      :model-value="modelValue.headerMediaUrl"
      @update:model-value="value => updateField('headerMediaUrl', value)"
      @update:valid="value => emit('update:headerImageValid', value)"
    />
    <div class="flex flex-col gap-2">
      <div
        v-for="(button, index) in modelValue.buttons"
        :key="button.id"
        class="flex items-end gap-2"
      >
        <Input
          :model-value="button.text"
          class="flex-1"
          :label="t('INTERACTIVE_MESSAGES.FIELDS.BUTTON_TEXT')"
          :placeholder="
            t('INTERACTIVE_MESSAGES.FIELDS.BUTTON_TEXT_PLACEHOLDER')
          "
          :maxlength="BUTTON_TITLE_MAX_LENGTH"
          @update:model-value="value => updateButton(index, value)"
        />
        <Button
          icon="i-lucide-trash"
          color="ruby"
          variant="faded"
          size="sm"
          :aria-label="t('INTERACTIVE_MESSAGES.BUTTONS.REMOVE_BUTTON')"
          @click="removeButton(index)"
        />
      </div>
      <Button
        v-if="modelValue.buttons.length < MAX_BUTTONS"
        icon="i-lucide-plus"
        color="slate"
        variant="faded"
        size="sm"
        class="self-start"
        :label="t('INTERACTIVE_MESSAGES.BUTTONS.ADD_BUTTON')"
        @click="addButton"
      />
    </div>
  </div>
</template>
