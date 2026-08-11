<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['update:modelValue', 'isInvalid']);

const MODE = {
  EVERYONE: 'everyone',
  SPECIFIC: 'specific',
};

const { t } = useI18n();
const store = useStore();

const agents = useMapGetter('agents/getVerifiedAgents');

const mode = ref(props.modelValue.length ? MODE.SPECIFIC : MODE.EVERYONE);

const administratorOptions = computed(() =>
  agents.value
    .filter(agent => agent.role === 'administrator')
    .map(agent => ({ value: agent.id, label: agent.name }))
);

const selectedIds = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value),
});

const selectMode = value => {
  mode.value = value;
  if (value === MODE.EVERYONE) emit('update:modelValue', []);
};

watch(
  () => props.modelValue,
  value => {
    mode.value = value.length ? MODE.SPECIFIC : MODE.EVERYONE;
  }
);

watch(
  () => mode.value === MODE.SPECIFIC && !props.modelValue.length,
  isInvalid => emit('isInvalid', isInvalid),
  { immediate: true }
);

onMounted(() => {
  if (!agents.value.length) store.dispatch('agents/get');
});
</script>

<template>
  <div class="flex flex-col w-full gap-2 mt-4">
    <label class="text-sm font-medium text-n-slate-12">
      {{ t('SLA.FORM.ALERT_RECIPIENTS.LABEL') }}
    </label>
    <RadioCard
      :id="MODE.EVERYONE"
      :label="t('SLA.FORM.ALERT_RECIPIENTS.EVERYONE.LABEL')"
      :description="t('SLA.FORM.ALERT_RECIPIENTS.EVERYONE.DESC')"
      :is-active="mode === MODE.EVERYONE"
      @select="selectMode(MODE.EVERYONE)"
    />
    <RadioCard
      :id="MODE.SPECIFIC"
      :label="t('SLA.FORM.ALERT_RECIPIENTS.SPECIFIC.LABEL')"
      :description="t('SLA.FORM.ALERT_RECIPIENTS.SPECIFIC.DESC')"
      :is-active="mode === MODE.SPECIFIC"
      @select="selectMode(MODE.SPECIFIC)"
    >
      <TagMultiSelectComboBox
        v-if="mode === MODE.SPECIFIC"
        v-model="selectedIds"
        class="w-full mt-2"
        :options="administratorOptions"
        :placeholder="t('SLA.FORM.ALERT_RECIPIENTS.SPECIFIC.PLACEHOLDER')"
        :search-placeholder="t('SLA.FORM.ALERT_RECIPIENTS.SPECIFIC.SEARCH')"
        :empty-state="t('SLA.FORM.ALERT_RECIPIENTS.SPECIFIC.EMPTY')"
        :has-error="!selectedIds.length"
        :message="
          selectedIds.length ? '' : t('SLA.FORM.ALERT_RECIPIENTS.EMPTY_ERROR')
        "
      />
    </RadioCard>
  </div>
</template>
