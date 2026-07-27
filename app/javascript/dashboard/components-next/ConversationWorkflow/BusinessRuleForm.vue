<script setup>
import { computed, reactive, ref, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import {
  GUARD_RULE_TYPES,
  emptyConfigForType,
} from 'dashboard/components-next/ConversationWorkflow/businessRulesConstants';

const props = defineProps({
  modelValue: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();
const conversationAttributes = useMapGetter(
  'attributes/getConversationAttributes'
);

const STATUS_OPTIONS = ['open', 'resolved', 'pending', 'snoozed'];
const syncing = ref(false);

const draft = reactive({
  id: null,
  name: '',
  type: GUARD_RULE_TYPES[0],
  enabled: true,
  preset_id: null,
  config: emptyConfigForType(GUARD_RULE_TYPES[0]),
});

const applyModel = value => {
  if (!value) return;
  syncing.value = true;
  draft.id = value.id;
  draft.name = value.name || '';
  draft.type = value.type || GUARD_RULE_TYPES[0];
  draft.enabled = value.enabled !== false;
  draft.preset_id = value.preset_id ?? null;
  draft.config = {
    ...emptyConfigForType(draft.type),
    ...(value.config || {}),
  };
  if (!Array.isArray(draft.config.attribute_keys)) {
    draft.config.attribute_keys = [];
  }
  if (!Array.isArray(draft.config.require_attribute_keys)) {
    draft.config.require_attribute_keys = [];
  }
  if (!Array.isArray(draft.config.when_values)) {
    draft.config.when_values = [];
  }
  if (!Array.isArray(draft.config.statuses)) {
    draft.config.statuses = [];
  }
  nextTick(() => {
    syncing.value = false;
  });
};

watch(
  () => props.modelValue,
  value => applyModel(value),
  { immediate: true, deep: true }
);

watch(
  draft,
  () => {
    if (syncing.value) return;
    emit('update:modelValue', {
      id: draft.id,
      name: draft.name,
      type: draft.type,
      enabled: draft.enabled,
      preset_id: draft.preset_id,
      config: { ...draft.config },
    });
  },
  { deep: true }
);

const attributeOptions = computed(() =>
  (conversationAttributes.value || [])
    .filter(attr => !attr.formula)
    .map(attr => ({
      value: attr.attributeKey || attr.attribute_key,
      label: attr.attributeDisplayName || attr.attribute_display_name,
    }))
);

const typeLabel = type => t(`BUSINESS_RULES.TYPES.${type}`);

const onTypeChange = type => {
  draft.type = type;
  draft.preset_id = null;
  draft.config = emptyConfigForType(type);
};

const toggleKey = (listKey, key) => {
  const list = Array.isArray(draft.config[listKey])
    ? [...draft.config[listKey]]
    : [];
  const idx = list.indexOf(key);
  if (idx >= 0) list.splice(idx, 1);
  else list.push(key);
  draft.config[listKey] = list;
};

const isChecked = (listKey, key) =>
  Array.isArray(draft.config[listKey]) && draft.config[listKey].includes(key);

const whenValuesText = computed({
  get: () =>
    Array.isArray(draft.config.when_values)
      ? draft.config.when_values.join(', ')
      : '',
  set: text => {
    draft.config.when_values = text
      .split(',')
      .map(s => s.trim())
      .filter(Boolean);
  },
});

const statusesText = computed({
  get: () =>
    Array.isArray(draft.config.statuses)
      ? draft.config.statuses.join(', ')
      : '',
  set: text => {
    draft.config.statuses = text
      .split(',')
      .map(s => s.trim())
      .filter(Boolean);
  },
});
</script>

<template>
  <div class="flex flex-col gap-4">
    <p class="m-0 text-sm text-n-slate-11">
      {{ $t('BUSINESS_RULES.FORM_HELP') }}
    </p>

    <label class="text-xs text-n-slate-11">
      {{ $t('BUSINESS_RULES.FIELDS.NAME') }}
      <input
        v-model="draft.name"
        type="text"
        class="mt-1 w-full"
        :placeholder="$t('BUSINESS_RULES.FIELDS.NAME_PLACEHOLDER')"
      />
    </label>

    <label class="text-xs text-n-slate-11">
      {{ $t('BUSINESS_RULES.FIELDS.TYPE') }}
      <select
        class="mt-1 w-full"
        :value="draft.type"
        @change="onTypeChange($event.target.value)"
      >
        <option v-for="type in GUARD_RULE_TYPES" :key="type" :value="type">
          {{ typeLabel(type) }}
        </option>
      </select>
    </label>

    <template v-if="draft.type === 'require_attributes_on_status'">
      <label class="text-xs text-n-slate-11">
        {{ $t('BUSINESS_RULES.FIELDS.STATUS') }}
        <select v-model="draft.config.status" class="mt-1 w-full">
          <option
            v-for="status in STATUS_OPTIONS"
            :key="status"
            :value="status"
          >
            {{ $t(`BUSINESS_RULES.STATUSES.${status}`) }}
          </option>
        </select>
      </label>
      <div>
        <p class="m-0 text-xs font-medium text-n-slate-12">
          {{ $t('BUSINESS_RULES.FIELDS.ATTRIBUTES') }}
        </p>
        <p class="mb-2 mt-1 text-xs text-n-slate-11">
          {{ $t('BUSINESS_RULES.FIELDS.ATTRIBUTES_HELP') }}
        </p>
        <div
          class="flex max-h-48 flex-col gap-2 overflow-y-auto rounded-md border border-n-weak p-2"
        >
          <label
            v-for="opt in attributeOptions"
            :key="opt.value"
            class="flex items-center gap-2 text-sm text-n-slate-12"
          >
            <input
              type="checkbox"
              :checked="isChecked('attribute_keys', opt.value)"
              @change="toggleKey('attribute_keys', opt.value)"
            />
            {{ opt.label }}
          </label>
          <p
            v-if="!attributeOptions.length"
            class="m-0 text-xs text-n-slate-11"
          >
            {{ $t('BUSINESS_RULES.NO_ATTRIBUTES') }}
          </p>
        </div>
      </div>
    </template>

    <template v-else-if="draft.type === 'if_attribute_then_require'">
      <label class="text-xs text-n-slate-11">
        {{ $t('BUSINESS_RULES.FIELDS.STATUS') }}
        <select v-model="draft.config.on_status" class="mt-1 w-full">
          <option
            v-for="status in STATUS_OPTIONS"
            :key="status"
            :value="status"
          >
            {{ $t(`BUSINESS_RULES.STATUSES.${status}`) }}
          </option>
        </select>
      </label>
      <label class="text-xs text-n-slate-11">
        {{ $t('BUSINESS_RULES.FIELDS.WHEN_ATTRIBUTE') }}
        <select v-model="draft.config.when_attribute" class="mt-1 w-full">
          <option value="">
            {{ $t('BUSINESS_RULES.FIELDS.NONE') }}
          </option>
          <option
            v-for="opt in attributeOptions"
            :key="opt.value"
            :value="opt.value"
          >
            {{ opt.label }}
          </option>
        </select>
      </label>
      <label class="text-xs text-n-slate-11">
        {{ $t('BUSINESS_RULES.FIELDS.WHEN_VALUES') }}
        <input
          v-model="whenValuesText"
          type="text"
          class="mt-1 w-full"
          :placeholder="$t('BUSINESS_RULES.FIELDS.WHEN_VALUES_PLACEHOLDER')"
        />
      </label>
      <div>
        <p class="m-0 text-xs font-medium text-n-slate-12">
          {{ $t('BUSINESS_RULES.FIELDS.REQUIRE_ATTRIBUTES') }}
        </p>
        <p class="mb-2 mt-1 text-xs text-n-slate-11">
          {{ $t('BUSINESS_RULES.FIELDS.ATTRIBUTES_HELP') }}
        </p>
        <div
          class="flex max-h-48 flex-col gap-2 overflow-y-auto rounded-md border border-n-weak p-2"
        >
          <label
            v-for="opt in attributeOptions"
            :key="opt.value"
            class="flex items-center gap-2 text-sm text-n-slate-12"
          >
            <input
              type="checkbox"
              :checked="isChecked('require_attribute_keys', opt.value)"
              @change="toggleKey('require_attribute_keys', opt.value)"
            />
            {{ opt.label }}
          </label>
        </div>
      </div>
    </template>

    <template v-else-if="draft.type === 'require_reason_on_status'">
      <label class="text-xs text-n-slate-11">
        {{ $t('BUSINESS_RULES.FIELDS.STATUSES') }}
        <input
          v-model="statusesText"
          type="text"
          class="mt-1 w-full"
          :placeholder="$t('BUSINESS_RULES.FIELDS.STATUSES_PLACEHOLDER')"
        />
      </label>
      <label class="flex items-center gap-2 text-xs text-n-slate-11">
        <input v-model="draft.config.require_private_note" type="checkbox" />
        {{ $t('BUSINESS_RULES.FIELDS.REQUIRE_PRIVATE_NOTE') }}
      </label>
      <label class="text-xs text-n-slate-11">
        {{ $t('BUSINESS_RULES.FIELDS.REASON_ATTRIBUTE') }}
        <select v-model="draft.config.reason_attribute_key" class="mt-1 w-full">
          <option value="">
            {{ $t('BUSINESS_RULES.FIELDS.NONE') }}
          </option>
          <option
            v-for="opt in attributeOptions"
            :key="opt.value"
            :value="opt.value"
          >
            {{ opt.label }}
          </option>
        </select>
      </label>
    </template>

    <template v-else-if="draft.type === 'forbid_status_if'">
      <label class="text-xs text-n-slate-11">
        {{ $t('BUSINESS_RULES.FIELDS.STATUS') }}
        <select v-model="draft.config.status" class="mt-1 w-full">
          <option
            v-for="status in STATUS_OPTIONS"
            :key="status"
            :value="status"
          >
            {{ $t(`BUSINESS_RULES.STATUSES.${status}`) }}
          </option>
        </select>
      </label>
      <label class="text-xs text-n-slate-11">
        {{ $t('BUSINESS_RULES.FIELDS.LABEL') }}
        <input v-model="draft.config.label" type="text" class="mt-1 w-full" />
      </label>
    </template>

    <template v-else-if="draft.type === 'require_assignee_on_status'">
      <label class="text-xs text-n-slate-11">
        {{ $t('BUSINESS_RULES.FIELDS.STATUS') }}
        <select v-model="draft.config.status" class="mt-1 w-full">
          <option
            v-for="status in STATUS_OPTIONS"
            :key="status"
            :value="status"
          >
            {{ $t(`BUSINESS_RULES.STATUSES.${status}`) }}
          </option>
        </select>
      </label>
      <label class="flex items-center gap-2 text-xs text-n-slate-11">
        <input v-model="draft.config.require_team_or_agent" type="checkbox" />
        {{ $t('BUSINESS_RULES.FIELDS.REQUIRE_TEAM_OR_AGENT') }}
      </label>
    </template>
  </div>
</template>
