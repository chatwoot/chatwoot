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
      class="flex items-start gap-2 p-3 rounded-lg border border-n-weak bg-n-alpha-2"
      :class="{
        'animate-wiggle border-n-ruby-9': showErrors && validationError,
      }"
    >
      <div class="flex flex-col flex-1 gap-3">
        <div class="grid grid-cols-3 gap-2">
          <Input
            v-model="name"
            :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_NAME.PLACEHOLDER')"
            class="col-span-2"
          />
          <ComboBox
            v-model="type"
            :options="paramTypeOptions"
            :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_TYPE.PLACEHOLDER')"
            class="[&>div>button]:bg-n-alpha-black2"
          />
        </div>
        <Input
          v-model="description"
          :placeholder="
            t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_DESCRIPTION.PLACEHOLDER')
          "
        />
        <label class="flex items-center gap-2 cursor-pointer">
          <Checkbox v-model="required" />
          <span class="text-sm text-n-slate-11">
            {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAM_REQUIRED.LABEL') }}
          </span>
        </label>
      </div>
      <Button
        solid
        slate
        icon="i-lucide-trash"
        class="flex-shrink-0"
        @click.stop="emit('remove')"
      />
    </div>
    <span
      v-if="showErrors && validationError"
      class="block mt-1 text-sm text-n-ruby-11"
    >
      {{ t(`CAPTAIN.CUSTOM_TOOLS.FORM.ERRORS.${validationError}`) }}
    </span>
  </li>
</template>
