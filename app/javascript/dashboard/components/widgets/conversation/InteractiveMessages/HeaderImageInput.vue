<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import { isValidURL } from 'dashboard/helper/URLHelper';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  modelValue: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    default: '',
  },
  placeholder: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:modelValue', 'update:valid']);

const { t } = useI18n();

// idle | checking | valid | invalid
const status = ref('idle');

const checkImage = url => {
  if (!url) {
    status.value = 'idle';
    emit('update:valid', true);
    return;
  }

  if (!isValidURL(url)) {
    status.value = 'invalid';
    emit('update:valid', false);
    return;
  }

  status.value = 'checking';
  const image = new Image();
  image.onload = () => {
    if (props.modelValue !== url) return;
    status.value = 'valid';
    emit('update:valid', true);
  };
  image.onerror = () => {
    if (props.modelValue !== url) return;
    status.value = 'invalid';
    emit('update:valid', false);
  };
  image.src = url;
};

const debouncedCheckImage = debounce(checkImage, 500);

watch(
  () => props.modelValue,
  url => {
    status.value = url ? 'checking' : 'idle';
    debouncedCheckImage(url);
  },
  { immediate: true }
);

const errorMessage = t('INTERACTIVE_MESSAGES.FIELDS.INVALID_IMAGE_URL');
</script>

<template>
  <Input
    :model-value="modelValue"
    :label="label || t('INTERACTIVE_MESSAGES.FIELDS.HEADER_IMAGE_URL')"
    :placeholder="
      placeholder ||
      t('INTERACTIVE_MESSAGES.FIELDS.HEADER_IMAGE_URL_PLACEHOLDER')
    "
    :message="status === 'invalid' ? errorMessage : ''"
    :message-type="status === 'invalid' ? 'error' : 'info'"
    @update:model-value="value => emit('update:modelValue', value)"
  />
</template>
