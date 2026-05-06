<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  modelValue: {
    type: [String, Number],
    default: '',
  },
  agents: {
    type: Array,
    default: () => [],
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();
const UNASSIGNED_VALUE = '__account_owner_unassigned__';

const ownerOptions = computed(() => [
  ...(props.modelValue
    ? [{ label: t('ACCOUNT_OWNER.UNASSIGNED'), value: UNASSIGNED_VALUE }]
    : []),
  ...props.agents.map(agent => ({
    label:
      agent.available_name || agent.availableName || agent.name || agent.email,
    value: agent.id,
  })),
]);

const handleUpdate = value => {
  if (value === UNASSIGNED_VALUE) {
    emit('update:modelValue', '');
    return;
  }

  if (value === '') return;

  emit('update:modelValue', value);
};
</script>

<template>
  <ComboBox
    :model-value="modelValue || ''"
    :options="ownerOptions"
    :placeholder="t('ACCOUNT_OWNER.LABEL')"
    :search-placeholder="t('ACCOUNT_OWNER.SEARCH_PLACEHOLDER')"
    :empty-state="t('ACCOUNT_OWNER.EMPTY_STATE')"
    :disabled="disabled"
    @update:model-value="handleUpdate"
  />
</template>
