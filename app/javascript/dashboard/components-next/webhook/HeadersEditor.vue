<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  modelValue: {
    type: Object,
    default: () => ({}),
  },
  label: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const rows = computed({
  get() {
    const entries = Object.entries(props.modelValue || {});
    return entries.length ? entries.map(([name, value]) => ({ name, value })) : [{ name: '', value: '' }];
  },
  set(value) {
    const headers = {};
    value.forEach(({ name, value: headerValue }) => {
      const trimmedName = (name || '').trim();
      if (trimmedName) headers[trimmedName] = headerValue ?? '';
    });
    emit('update:modelValue', headers);
  },
});

const updateRow = (index, key, value) => {
  const next = rows.value.map((row, idx) => (idx === index ? { ...row, [key]: value } : row));
  rows.value = next;
};

const addRow = () => {
  rows.value = [...rows.value, { name: '', value: '' }];
};

const removeRow = index => {
  const next = rows.value.filter((_, idx) => idx !== index);
  rows.value = next.length ? next : [{ name: '', value: '' }];
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <label v-if="label" class="text-sm font-medium text-n-slate-12">
      {{ label }}
    </label>
    <p v-if="description" class="text-xs text-n-slate-11">
      {{ description }}
    </p>
    <div class="flex flex-col gap-2">
      <div
        v-for="(row, index) in rows"
        :key="index"
        class="flex items-center gap-2"
      >
        <input
          :value="row.name"
          type="text"
          class="!mb-0 flex-1 font-mono"
          :placeholder="t('WEBHOOK_HEADERS.NAME_PLACEHOLDER')"
          @input="event => updateRow(index, 'name', event.target.value)"
        />
        <input
          :value="row.value"
          type="text"
          class="!mb-0 flex-1 font-mono"
          :placeholder="t('WEBHOOK_HEADERS.VALUE_PLACEHOLDER')"
          @input="event => updateRow(index, 'value', event.target.value)"
        />
        <NextButton
          v-tooltip.top="t('WEBHOOK_HEADERS.REMOVE')"
          type="button"
          icon="i-lucide-trash-2"
          slate
          faded
          @click="removeRow(index)"
        />
      </div>
    </div>
    <div>
      <NextButton
        type="button"
        icon="i-lucide-plus"
        slate
        faded
        :label="t('WEBHOOK_HEADERS.ADD')"
        @click="addRow"
      />
    </div>
  </div>
</template>
