<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();

const headers = defineModel('headers', {
  type: Object,
  default: () => ({}),
});

const rows = ref(
  Object.entries(headers.value || {}).map(([name, value]) => ({ name, value }))
);
const showErrors = ref(false);

const isMissingName = row => !row.name.trim() && !!row.value;

watch(
  rows,
  newRows => {
    showErrors.value = false;
    headers.value = Object.fromEntries(
      newRows
        .filter(row => row.name.trim())
        .map(row => [row.name.trim(), row.value])
    );
  },
  { deep: true }
);

const addHeader = () => rows.value.push({ name: '', value: '' });
const removeHeader = index => rows.value.splice(index, 1);

const validate = () => {
  showErrors.value = true;
  return !rows.value.some(isMissingName);
};

defineExpose({ validate });
</script>

<template>
  <div class="flex flex-col gap-2">
    <p class="text-xs text-n-slate-11">
      {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.HEADERS.HELP_TEXT') }}
    </p>
    <ul v-if="rows.length" class="grid gap-2 list-none">
      <li v-for="(row, index) in rows" :key="index" class="flex gap-2">
        <Input
          v-model="row.name"
          :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.HEADERS.NAME_PLACEHOLDER')"
          :message="
            showErrors && isMissingName(row)
              ? t('CAPTAIN.CUSTOM_TOOLS.FORM.HEADERS.NAME_REQUIRED')
              : ''
          "
          message-type="error"
          class="flex-1 [&_input]:font-mono"
        />
        <Input
          v-model="row.value"
          :placeholder="
            t('CAPTAIN.CUSTOM_TOOLS.FORM.HEADERS.VALUE_PLACEHOLDER')
          "
          class="flex-1 [&_input]:font-mono"
        />
        <Button
          type="button"
          ghost
          slate
          icon="i-lucide-trash-2"
          class="flex-shrink-0"
          data-test="remove-header"
          @click="removeHeader(index)"
        />
      </li>
    </ul>
    <Button
      type="button"
      sm
      ghost
      blue
      icon="i-lucide-plus"
      :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.HEADERS.ADD')"
      data-test="add-header"
      @click="addHeader"
    />
  </div>
</template>
