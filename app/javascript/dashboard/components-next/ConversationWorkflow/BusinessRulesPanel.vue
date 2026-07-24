<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import {
  BUSINESS_RULE_PRESETS,
  GUARD_RULE_TYPES,
  newRuleId,
} from './businessRulesConstants';

const STATUS_OPTIONS = ['open', 'resolved', 'pending', 'snoozed'];

const emptyConfigForType = type => {
  switch (type) {
    case 'require_attributes_on_status':
      return { status: 'resolved', attribute_keys: [] };
    case 'if_attribute_then_require':
      return {
        when_attribute: '',
        when_values: [],
        require_attribute_keys: [],
        on_status: 'resolved',
      };
    case 'require_reason_on_status':
      return {
        statuses: ['pending', 'snoozed'],
        require_private_note: true,
        reason_attribute_key: '',
      };
    case 'forbid_status_if':
      return { status: 'resolved', label: '' };
    case 'require_assignee_on_status':
      return { status: 'open', require_team_or_agent: true };
    default:
      return {};
  }
};

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();
const conversationAttributes = useMapGetter(
  'attributes/getConversationAttributes'
);
const saving = ref(false);
const showCreate = ref(false);
const newRuleType = ref(GUARD_RULE_TYPES[0]);
const newRuleName = ref('');

const attributeOptions = computed(() =>
  (conversationAttributes.value || []).map(attr => ({
    value: attr.attributeKey || attr.attribute_key,
    label: attr.attributeDisplayName || attr.attribute_display_name,
  }))
);

const rules = ref([]);

watch(
  currentAccount,
  account => {
    rules.value = JSON.parse(
      JSON.stringify(account?.settings?.business_rules || [])
    );
  },
  { immediate: true, deep: true }
);

const typeLabel = type => t(`BUSINESS_RULES.TYPES.${type}`);

const activatePreset = preset => {
  const rule = {
    id: newRuleId(),
    preset_id: preset.id,
    name: t(preset.nameKey),
    ...JSON.parse(JSON.stringify(preset.defaults)),
  };
  if (!rule.config) rule.config = emptyConfigForType(rule.type);
  rules.value = [...rules.value, rule];
};

const createCustomRule = () => {
  const type = newRuleType.value;
  const name =
    newRuleName.value.trim() ||
    t('BUSINESS_RULES.CUSTOM_DEFAULT_NAME', { type: typeLabel(type) });
  rules.value = [
    ...rules.value,
    {
      id: newRuleId(),
      preset_id: null,
      name,
      type,
      enabled: true,
      config: emptyConfigForType(type),
    },
  ];
  newRuleName.value = '';
  showCreate.value = false;
};

const onTypeChange = (rule, type) => {
  rule.type = type;
  rule.preset_id = null;
  rule.config = emptyConfigForType(type);
};

const whenValuesText = rule =>
  Array.isArray(rule.config?.when_values)
    ? rule.config.when_values.join(', ')
    : '';

const setWhenValuesText = (rule, text) => {
  rule.config.when_values = text
    .split(',')
    .map(s => s.trim())
    .filter(Boolean);
};

const statusesText = rule =>
  Array.isArray(rule.config?.statuses) ? rule.config.statuses.join(', ') : '';

const setStatusesText = (rule, text) => {
  rule.config.statuses = text
    .split(',')
    .map(s => s.trim())
    .filter(Boolean);
};

const removeRule = id => {
  rules.value = rules.value.filter(r => r.id !== id);
};

const toggleRule = (rule, enabled) => {
  rule.enabled = enabled;
};

const save = async () => {
  saving.value = true;
  try {
    await updateAccount({ business_rules: rules.value }, { silent: true });
    useAlert(t('BUSINESS_RULES.SAVE_SUCCESS'));
  } catch (e) {
    useAlert(t('BUSINESS_RULES.SAVE_ERROR'));
  } finally {
    saving.value = false;
  }
};

const unusedPresets = computed(() =>
  BUSINESS_RULE_PRESETS.filter(
    p => !rules.value.some(r => r.preset_id === p.id)
  )
);
</script>

<template>
  <div
    class="flex flex-col gap-4 rounded-lg border border-n-weak bg-n-solid-2 p-4"
  >
    <div class="flex flex-wrap items-start justify-between gap-3">
      <div>
        <p class="font-medium text-n-slate-12">
          {{ $t('BUSINESS_RULES.TITLE') }}
        </p>
        <p class="text-sm text-n-slate-11">
          {{ $t('BUSINESS_RULES.DESCRIPTION') }}
        </p>
      </div>
      <Button
        sm
        blue
        solid
        :label="$t('BUSINESS_RULES.CREATE_CUSTOM')"
        @click="showCreate = !showCreate"
      />
    </div>

    <div
      v-if="showCreate"
      class="flex flex-col gap-3 rounded-md border border-n-brand/40 bg-n-background p-3"
    >
      <p class="m-0 text-sm font-medium text-n-slate-12">
        {{ $t('BUSINESS_RULES.CREATE_CUSTOM_TITLE') }}
      </p>
      <label class="text-xs text-n-slate-11">
        {{ $t('BUSINESS_RULES.FIELDS.NAME') }}
        <input
          v-model="newRuleName"
          type="text"
          class="mt-1 w-full"
          :placeholder="$t('BUSINESS_RULES.FIELDS.NAME_PLACEHOLDER')"
        />
      </label>
      <label class="text-xs text-n-slate-11">
        {{ $t('BUSINESS_RULES.FIELDS.TYPE') }}
        <select v-model="newRuleType" class="mt-1 w-full">
          <option v-for="type in GUARD_RULE_TYPES" :key="type" :value="type">
            {{ typeLabel(type) }}
          </option>
        </select>
      </label>
      <div class="flex gap-2">
        <Button
          sm
          blue
          solid
          :label="$t('BUSINESS_RULES.CREATE_ADD')"
          @click="createCustomRule"
        />
        <Button
          sm
          faded
          :label="$t('BUSINESS_RULES.CANCEL')"
          @click="showCreate = false"
        />
      </div>
    </div>

    <div v-if="unusedPresets.length" class="flex flex-col gap-2">
      <p class="text-xs font-medium uppercase text-n-slate-11">
        {{ $t('BUSINESS_RULES.PRESETS_TITLE') }}
      </p>
      <p class="m-0 text-xs text-n-slate-11">
        {{ $t('BUSINESS_RULES.PRESETS_HELP') }}
      </p>
      <div class="flex flex-wrap gap-2">
        <Button
          v-for="preset in unusedPresets"
          :key="preset.id"
          sm
          faded
          :label="$t(preset.nameKey)"
          @click="activatePreset(preset)"
        />
      </div>
    </div>

    <div v-if="!rules.length" class="text-sm text-n-slate-11">
      {{ $t('BUSINESS_RULES.EMPTY') }}
    </div>

    <div
      v-for="rule in rules"
      :key="rule.id"
      class="flex flex-col gap-3 rounded-md border border-n-weak bg-n-background p-3"
    >
      <div class="flex flex-wrap items-start justify-between gap-3">
        <div class="flex min-w-0 flex-1 flex-col gap-2">
          <label class="text-xs text-n-slate-11">
            {{ $t('BUSINESS_RULES.FIELDS.NAME') }}
            <input
              v-model="rule.name"
              type="text"
              class="mt-1 w-full font-medium text-n-slate-12"
            />
          </label>
          <label class="text-xs text-n-slate-11">
            {{ $t('BUSINESS_RULES.FIELDS.TYPE') }}
            <select
              class="mt-1 w-full"
              :value="rule.type"
              @change="onTypeChange(rule, $event.target.value)"
            >
              <option
                v-for="type in GUARD_RULE_TYPES"
                :key="type"
                :value="type"
              >
                {{ typeLabel(type) }}
              </option>
            </select>
          </label>
        </div>
        <div class="flex items-center gap-2">
          <Switch
            :model-value="rule.enabled !== false"
            @update:model-value="val => toggleRule(rule, val)"
          />
          <Button
            sm
            faded
            ruby
            :label="$t('BUSINESS_RULES.REMOVE')"
            @click="removeRule(rule.id)"
          />
        </div>
      </div>

      <template v-if="rule.type === 'require_attributes_on_status'">
        <label class="text-xs text-n-slate-11">
          {{ $t('BUSINESS_RULES.FIELDS.STATUS') }}
          <select v-model="rule.config.status" class="mt-1 w-full">
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
          {{ $t('BUSINESS_RULES.FIELDS.ATTRIBUTES') }}
          <select
            v-model="rule.config.attribute_keys"
            multiple
            class="mt-1 w-full min-h-24"
          >
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

      <template v-else-if="rule.type === 'if_attribute_then_require'">
        <label class="text-xs text-n-slate-11">
          {{ $t('BUSINESS_RULES.FIELDS.STATUS') }}
          <select v-model="rule.config.on_status" class="mt-1 w-full">
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
          <select v-model="rule.config.when_attribute" class="mt-1 w-full">
            <option value="">—</option>
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
            type="text"
            class="mt-1 w-full"
            :value="whenValuesText(rule)"
            :placeholder="$t('BUSINESS_RULES.FIELDS.WHEN_VALUES_PLACEHOLDER')"
            @input="setWhenValuesText(rule, $event.target.value)"
          />
        </label>
        <label class="text-xs text-n-slate-11">
          {{ $t('BUSINESS_RULES.FIELDS.REQUIRE_ATTRIBUTES') }}
          <select
            v-model="rule.config.require_attribute_keys"
            multiple
            class="mt-1 w-full min-h-24"
          >
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

      <template v-else-if="rule.type === 'require_reason_on_status'">
        <label class="text-xs text-n-slate-11">
          {{ $t('BUSINESS_RULES.FIELDS.STATUSES') }}
          <input
            type="text"
            class="mt-1 w-full"
            :value="statusesText(rule)"
            :placeholder="$t('BUSINESS_RULES.FIELDS.STATUSES_PLACEHOLDER')"
            @input="setStatusesText(rule, $event.target.value)"
          />
        </label>
        <label class="flex items-center gap-2 text-xs text-n-slate-11">
          <input v-model="rule.config.require_private_note" type="checkbox" />
          {{ $t('BUSINESS_RULES.FIELDS.REQUIRE_PRIVATE_NOTE') }}
        </label>
        <label class="text-xs text-n-slate-11">
          {{ $t('BUSINESS_RULES.FIELDS.REASON_ATTRIBUTE') }}
          <select
            v-model="rule.config.reason_attribute_key"
            class="mt-1 w-full"
          >
            <option value="">—</option>
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

      <template v-else-if="rule.type === 'forbid_status_if'">
        <label class="text-xs text-n-slate-11">
          {{ $t('BUSINESS_RULES.FIELDS.STATUS') }}
          <select v-model="rule.config.status" class="mt-1 w-full">
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
          <input v-model="rule.config.label" type="text" class="mt-1 w-full" />
        </label>
      </template>

      <template v-else-if="rule.type === 'require_assignee_on_status'">
        <label class="text-xs text-n-slate-11">
          {{ $t('BUSINESS_RULES.FIELDS.STATUS') }}
          <select v-model="rule.config.status" class="mt-1 w-full">
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
          <input v-model="rule.config.require_team_or_agent" type="checkbox" />
          {{ $t('BUSINESS_RULES.FIELDS.REQUIRE_TEAM_OR_AGENT') }}
        </label>
      </template>
    </div>

    <div>
      <Button
        blue
        solid
        :label="$t('BUSINESS_RULES.SAVE')"
        :is-loading="saving"
        @click="save"
      />
    </div>
  </div>
</template>
