<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  modelValue: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const EMPTY_ROW = () => ({ name: '', value: '' });

const rows = ref([EMPTY_ROW()]);

const toRows = headers => {
  const entries = Object.entries(headers || {});
  return entries.length
    ? entries.map(([name, value]) => ({ name, value: String(value ?? '') }))
    : [EMPTY_ROW()];
};

watch(
  () => props.modelValue,
  headers => {
    rows.value = toRows(headers);
  },
  { immediate: true }
);

const sync = () => {
  const headers = {};
  rows.value.forEach(({ name, value }) => {
    const trimmed = (name || '').trim();
    if (trimmed) headers[trimmed] = value ?? '';
  });
  emit('update:modelValue', headers);
};

const addRow = () => {
  rows.value.push(EMPTY_ROW());
};

const removeRow = index => {
  rows.value.splice(index, 1);
  sync();
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <div
      v-for="(row, index) in rows"
      :key="index"
      class="flex items-start gap-2"
    >
      <Input
        v-model="row.name"
        :placeholder="
          t('CAPTAIN.CUSTOM_TOOLS.FORM.ADDITIONAL_HEADERS.NAME_PLACEHOLDER')
        "
        class="flex-1"
        @update:model-value="sync"
      />
      <Input
        v-model="row.value"
        :placeholder="
          t('CAPTAIN.CUSTOM_TOOLS.FORM.ADDITIONAL_HEADERS.VALUE_PLACEHOLDER')
        "
        class="flex-1"
        @update:model-value="sync"
      />
      <Button
        type="button"
        variant="faded"
        color="slate"
        icon="i-lucide-x"
        size="xs"
        class="mt-1.5 shrink-0"
        @click="removeRow(index)"
      />
    </div>
    <Button
      type="button"
      sm
      ghost
      blue
      icon="i-lucide-plus"
      :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.ADDITIONAL_HEADERS.ADD')"
      @click="addRow"
    />
  </div>
</template>
