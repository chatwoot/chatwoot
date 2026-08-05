<script setup>
import { ref, watch, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import AudienceGroup from './audience/AudienceGroup.vue';
import { useAudienceFilterTypes } from './audience/useAudienceFilterTypes.js';

const props = defineProps({
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();
const { filterTypes } = useAudienceFilterTypes();

const MODE = {
  EVERYONE: 'everyone',
  SPECIFIC: 'specific',
};

let uid = 0;
const nextId = () => {
  uid += 1;
  return `audience-root-${uid}`;
};

const hasConditions = node =>
  node && Object.prototype.hasOwnProperty.call(node, 'conditions');

const defaultRoot = () => ({ id: nextId(), operator: 'and', conditions: [] });

const root = ref(defaultRoot());
const mode = ref(MODE.EVERYONE);
const showEmptyAudienceError = ref(false);

const findOption = (filterType, value) =>
  filterType?.options?.find(option => String(option.id) === String(value));

const hydrateValues = (leaf, filterType) => {
  const raw = Array.isArray(leaf.values) ? leaf.values : [leaf.values];
  const inputType = filterType?.inputType;
  if (inputType === 'multiSelect') {
    return raw.map(
      value => findOption(filterType, value) ?? { id: value, name: value }
    );
  }
  if (['searchSelect', 'booleanSelect'].includes(inputType)) {
    return findOption(filterType, raw[0]) ?? { id: raw[0], name: raw[0] };
  }
  return raw[0] ?? '';
};

const hydrateNode = node => {
  if (hasConditions(node)) {
    return {
      id: nextId(),
      operator: node.operator || 'and',
      conditions: (node.conditions || []).map(hydrateNode),
    };
  }

  const filterType = filterTypes.value.find(
    type => type.attributeKey === node.attribute_key
  );
  return {
    id: nextId(),
    attributeKey: node.attribute_key,
    filterOperator: node.filter_operator,
    values: hydrateValues(node, filterType),
    attributeModel: filterType?.attributeModel || 'standard',
  };
};

const hydrateRoot = audience => {
  if (!audience) return defaultRoot();
  const hydrated = hydrateNode(audience);
  return hasConditions(hydrated)
    ? hydrated
    : { id: nextId(), operator: 'and', conditions: [hydrated] };
};

const serializeValues = values => {
  if (Array.isArray(values)) {
    return values[0]?.id ? values.map(value => value.id) : values;
  }
  if (values && typeof values === 'object') {
    return [values.id];
  }
  if (values === '' || values === null || values === undefined) {
    return [];
  }
  return [values];
};

const serializeNode = node => {
  if (hasConditions(node)) {
    return {
      operator: node.operator,
      conditions: node.conditions.map(serializeNode),
    };
  }
  return {
    attribute_key: node.attributeKey,
    filter_operator: node.filterOperator,
    values: serializeValues(node.values),
  };
};

const groupRef = useTemplateRef('groupRef');

const handleSubmit = () => {
  const isSpecific = mode.value === MODE.SPECIFIC;
  if (isSpecific && !root.value.conditions.length) {
    showEmptyAudienceError.value = true;
    return;
  }

  showEmptyAudienceError.value = false;
  if (isSpecific && !groupRef.value.validate()) return;

  const audience =
    isSpecific && root.value.conditions.length
      ? serializeNode(root.value)
      : null;

  emit('submit', {
    config: {
      ...props.assistant.config,
      audience,
    },
  });
};

watch(
  () => props.assistant,
  newAssistant => {
    if (!newAssistant) return;
    const audience = newAssistant.config?.audience;
    root.value = hydrateRoot(audience);
    mode.value = audience ? MODE.SPECIFIC : MODE.EVERYONE;
  },
  { immediate: true }
);

watch(
  () => root.value.conditions.length,
  () => {
    showEmptyAudienceError.value = false;
  }
);
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex flex-col gap-3">
      <RadioCard
        :id="MODE.EVERYONE"
        :label="t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.EVERYONE.LABEL')"
        :description="t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.EVERYONE.DESC')"
        :is-active="mode === MODE.EVERYONE"
        @select="mode = MODE.EVERYONE"
      />
      <RadioCard
        :id="MODE.SPECIFIC"
        :label="t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.SPECIFIC.LABEL')"
        :description="t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.SPECIFIC.DESC')"
        :is-active="mode === MODE.SPECIFIC"
        @select="mode = MODE.SPECIFIC"
      >
        <AudienceGroup
          v-if="mode === MODE.SPECIFIC"
          ref="groupRef"
          v-model="root"
          is-root
          class="w-full mt-2"
          :filter-types="filterTypes"
        />
        <p v-if="showEmptyAudienceError" class="mt-2 text-sm text-n-ruby-11">
          {{ t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.EMPTY_ERROR') }}
        </p>
      </RadioCard>
    </div>
    <div>
      <Button
        :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
        @click="handleSubmit"
      />
    </div>
  </div>
</template>
