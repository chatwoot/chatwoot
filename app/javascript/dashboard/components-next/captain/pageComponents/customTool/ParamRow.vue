<script setup>
import { computed, defineModel, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const emit = defineEmits(['remove']);
const { t } = useI18n();
const showErrors = ref(false);

const name = defineModel('name', {
  type: String,
  required: true,
});

const type = defineModel('type', {
  type: String,
  required: true,
});

const description = defineModel('description', {
  type: String,
  default: '',
});

const required = defineModel('required', {
  type: Boolean,
  default: false,
});

const paramTypeOptions = computed(() => [
  { value: 'string', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.STRING') },
  { value: 'number', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.NUMBER') },
  {
    value: 'boolean',
    label: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.BOOLEAN'),
  },
  { value: 'array', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.ARRAY') },
  { value: 'object', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPES.OBJECT') },
]);

const validationError = computed(() => {
  if (!name.value || name.value.trim() === '') {
    return 'PARAM_NAME_REQUIRED';
  }
  return null;
});

watch([name, type, description, required], () => {
  showErrors.value = false;
});

const validate = () => {
  showErrors.value = true;
  return !validationError.value;
};

defineExpose({ validate });
</script>

<template>
  <li class="list-none">
    <div
      class="flex items-start gap-2 rounded-lg border border-outline-variant/10 bg-surface-container-lowest p-3"
      :class="{
        'animate-wiggle border-error': showErrors && validationError,
      }"
    >
      <div class="flex min-w-0 flex-1 flex-col gap-3">
        <div class="grid grid-cols-1 gap-2 sm:grid-cols-3">
          <Input
            v-model="name"
            :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_NAME.PLACEHOLDER')"
            class="min-w-0 sm:col-span-2"
          />
          <ComboBox
            v-model="type"
            :options="paramTypeOptions"
            :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPE.PLACEHOLDER')"
            class="min-w-0"
          />
        </div>
        <Input
          v-model="description"
          :placeholder="
            t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_DESCRIPTION.PLACEHOLDER')
          "
        />
        <label class="flex cursor-pointer items-center gap-2">
          <Checkbox v-model="required" />
          <span class="text-sm text-on-surface-variant">
            {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_REQUIRED.LABEL') }}
          </span>
        </label>
      </div>
      <Button
        type="button"
        ghost
        ruby
        xs
        icon="i-lucide-trash"
        class="mt-0.5 shrink-0 rounded-md"
        @click.stop="emit('remove')"
      />
    </div>
    <span
      v-if="showErrors && validationError"
      class="mt-1 block text-sm text-error"
    >
      {{ t(`CAPTAIN.CUSTOM_TOOLS.FORM.ERRORS.${validationError}`) }}
    </span>
  </li>
</template>
