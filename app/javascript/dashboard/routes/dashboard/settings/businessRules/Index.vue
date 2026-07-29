<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';
import BusinessRuleForm from 'dashboard/components-next/ConversationWorkflow/BusinessRuleForm.vue';
import BusinessRulesDryRunDialog from 'dashboard/components-next/ConversationWorkflow/BusinessRulesDryRunDialog.vue';
import {
  BUSINESS_RULE_PRESETS,
  emptyConfigForType,
  newRuleId,
  summarizeRule,
} from 'dashboard/components-next/ConversationWorkflow/businessRulesConstants';
import {
  findImpossibleAndErrors,
  formatBusinessRuleLintErrors,
} from 'dashboard/helper/businessRulesLint';

const { t } = useI18n();
const store = useStore();
const { currentAccount, updateAccount } = useAccount();

const saving = ref(false);
const rules = ref([]);
const dialogRef = ref(null);
const formRule = ref(null);
const dialogMode = ref('create');
const showDryRun = ref(false);
const rulesPaused = ref(false);

onMounted(() => {
  store.dispatch('attributes/get');
  store.dispatch('labels/get');
  store.dispatch('inboxes/get');
});

watch(
  currentAccount,
  account => {
    rules.value = JSON.parse(
      JSON.stringify(account?.settings?.business_rules || [])
    );
    rulesPaused.value = Boolean(account?.settings?.business_rules_paused);
  },
  { immediate: true, deep: true }
);

const tableHeaders = computed(() => [
  t('BUSINESS_RULES.LIST.TABLE_HEADER.NAME'),
  t('BUSINESS_RULES.LIST.TABLE_HEADER.TYPE'),
  t('BUSINESS_RULES.LIST.TABLE_HEADER.SUMMARY'),
  t('BUSINESS_RULES.LIST.TABLE_HEADER.ENABLED'),
  t('BUSINESS_RULES.LIST.TABLE_HEADER.ACTION'),
]);

const unusedPresets = computed(() =>
  BUSINESS_RULE_PRESETS.filter(
    preset => !rules.value.some(rule => rule.preset_id === preset.id)
  )
);

const hasLegacyRequiredAttributes = computed(() => {
  const legacy =
    currentAccount.value?.settings?.conversation_required_attributes || [];
  return Array.isArray(legacy) && legacy.length > 0;
});

const hasEnabledRules = computed(() =>
  rules.value.some(rule => rule.enabled !== false)
);

const typeLabel = type => t(`BUSINESS_RULES.TYPES.${type}`);

const alertLintErrors = (errors, nextRules) => {
  const message =
    formatBusinessRuleLintErrors(errors, t, nextRules) ||
    t('BUSINESS_RULES.SAVE_ERROR');
  useAlert(message);
};

const persist = async nextRules => {
  const clientErrors = findImpossibleAndErrors(nextRules);
  if (clientErrors.length) {
    alertLintErrors(clientErrors, nextRules);
    return false;
  }

  saving.value = true;
  try {
    await updateAccount({ business_rules: nextRules }, { silent: true });
    rules.value = JSON.parse(JSON.stringify(nextRules));
    useAlert(t('BUSINESS_RULES.SAVE_SUCCESS'));
    return true;
  } catch (e) {
    const apiErrors = e?.response?.data?.business_rule_errors;
    if (apiErrors?.length) {
      alertLintErrors(apiErrors, nextRules);
    } else {
      useAlert(t('BUSINESS_RULES.SAVE_ERROR'));
    }
    return false;
  } finally {
    saving.value = false;
  }
};

const persistPaused = async paused => {
  saving.value = true;
  try {
    await updateAccount({ business_rules_paused: paused }, { silent: true });
    rulesPaused.value = paused;
    useAlert(
      paused
        ? t('BUSINESS_RULES.PAUSE.ON_SUCCESS')
        : t('BUSINESS_RULES.PAUSE.OFF_SUCCESS')
    );
  } catch {
    useAlert(t('BUSINESS_RULES.SAVE_ERROR'));
    rulesPaused.value = Boolean(
      currentAccount.value?.settings?.business_rules_paused
    );
  } finally {
    saving.value = false;
  }
};

const openCreate = () => {
  dialogMode.value = 'create';
  formRule.value = {
    id: newRuleId(),
    name: '',
    type: 'require_attributes_on_status',
    enabled: false,
    preset_id: null,
    conditions: [],
    config: emptyConfigForType('require_attributes_on_status'),
  };
  dialogRef.value?.open();
};

const openEdit = rule => {
  dialogMode.value = 'edit';
  formRule.value = JSON.parse(JSON.stringify(rule));
  dialogRef.value?.open();
};

const closeDialog = () => {
  dialogRef.value?.close();
  formRule.value = null;
};

const saveFromDialog = async () => {
  if (!formRule.value?.name?.trim()) {
    useAlert(t('BUSINESS_RULES.NAME_REQUIRED'));
    return;
  }
  const payload = {
    ...formRule.value,
    name: formRule.value.name.trim(),
    conditions: Array.isArray(formRule.value.conditions)
      ? formRule.value.conditions
      : [],
    config: { ...(formRule.value.config || {}) },
  };
  let next;
  if (dialogMode.value === 'edit') {
    next = rules.value.map(rule => (rule.id === payload.id ? payload : rule));
  } else {
    next = [...rules.value, payload];
  }
  const ok = await persist(next);
  if (ok) closeDialog();
};

const activatePreset = async preset => {
  const rule = {
    id: newRuleId(),
    preset_id: preset.id,
    name: t(preset.nameKey),
    ...JSON.parse(JSON.stringify(preset.defaults)),
    enabled: false,
  };
  if (!rule.config) rule.config = emptyConfigForType(rule.type);
  if (!Array.isArray(rule.conditions)) rule.conditions = [];
  await persist([...rules.value, rule]);
};

const toggleEnabled = async (rule, enabled) => {
  const next = rules.value.map(item =>
    item.id === rule.id ? { ...item, enabled } : item
  );
  const ok = await persist(next);
  if (!ok) {
    // Force switch back via account watch / local reset
    rules.value = JSON.parse(
      JSON.stringify(currentAccount.value?.settings?.business_rules || [])
    );
  }
};

const removeRule = async rule => {
  await persist(rules.value.filter(item => item.id !== rule.id));
};

const dialogTitle = computed(() =>
  dialogMode.value === 'edit'
    ? t('BUSINESS_RULES.EDIT_TITLE')
    : t('BUSINESS_RULES.CREATE_CUSTOM_TITLE')
);
</script>

<template>
  <SettingsLayout :no-records-found="false">
    <template #header>
      <BaseSettingsHeader
        :title="$t('BUSINESS_RULES.HEADER')"
        :description="$t('BUSINESS_RULES.DESCRIPTION')"
        feature-name="business-rules"
      >
        <template #actions>
          <Button
            :label="$t('BUSINESS_RULES.DRY_RUN.OPEN')"
            size="sm"
            faded
            slate
            @click="showDryRun = true"
          />
          <Button
            :label="$t('BUSINESS_RULES.CREATE_CUSTOM')"
            size="sm"
            @click="openCreate"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <div
        class="mb-4 flex flex-wrap items-center justify-between gap-3 rounded-lg border border-n-weak bg-n-solid-2 p-3"
      >
        <div>
          <p class="m-0 text-sm font-medium text-n-slate-12">
            {{ $t('BUSINESS_RULES.PAUSE.LABEL') }}
          </p>
          <p class="mb-0 mt-1 text-xs text-n-slate-11">
            {{ $t('BUSINESS_RULES.PAUSE.HELP') }}
          </p>
        </div>
        <Switch
          :model-value="rulesPaused"
          :disabled="saving"
          @update:model-value="persistPaused"
        />
      </div>

      <div
        v-if="hasEnabledRules && !rulesPaused"
        class="mb-4 rounded-lg border border-n-amber-5 bg-n-amber-2/40 p-3 text-sm text-n-slate-12"
      >
        {{ $t('BUSINESS_RULES.ENABLED_WARNING') }}
      </div>

      <div
        v-if="hasLegacyRequiredAttributes"
        class="mb-4 rounded-lg border border-n-amber-5 bg-n-amber-2/40 p-3 text-sm text-n-slate-12"
      >
        {{ $t('BUSINESS_RULES.LEGACY_BANNER') }}
      </div>

      <div
        v-if="unusedPresets.length"
        class="mb-6 flex flex-col gap-3 rounded-lg border border-n-weak bg-n-solid-2 p-4"
      >
        <div>
          <p class="m-0 font-medium text-n-slate-12">
            {{ $t('BUSINESS_RULES.PRESETS_TITLE') }}
          </p>
          <p class="mb-0 mt-1 text-sm text-n-slate-11">
            {{ $t('BUSINESS_RULES.PRESETS_HELP') }}
          </p>
        </div>
        <div class="flex flex-col gap-2">
          <div
            v-for="preset in unusedPresets"
            :key="preset.id"
            class="flex flex-wrap items-center justify-between gap-2 rounded-md border border-n-weak bg-n-solid-1 p-3"
          >
            <div>
              <p class="m-0 text-sm font-medium text-n-slate-12">
                {{ $t(preset.nameKey) }}
              </p>
              <p class="mb-0 mt-1 text-xs text-n-slate-11">
                {{ $t(preset.descriptionKey) }}
              </p>
            </div>
            <Button
              sm
              faded
              :label="$t('BUSINESS_RULES.ACTIVATE_PRESET')"
              :is-loading="saving"
              @click="activatePreset(preset)"
            />
          </div>
        </div>
      </div>

      <BaseTable
        :headers="tableHeaders"
        :items="rules"
        :no-data-message="$t('BUSINESS_RULES.EMPTY')"
      >
        <template #row="{ items }">
          <BaseTableRow v-for="rule in items" :key="rule.id" :item="rule">
            <template #default>
              <BaseTableCell>
                <span class="text-body-main text-n-slate-12">
                  {{ rule.name }}
                </span>
              </BaseTableCell>
              <BaseTableCell>
                <span class="text-body-main text-n-slate-11">
                  {{ typeLabel(rule.type) }}
                </span>
              </BaseTableCell>
              <BaseTableCell>
                <span class="text-xs text-n-slate-11">
                  {{ summarizeRule(rule, t) }}
                </span>
              </BaseTableCell>
              <BaseTableCell>
                <Switch
                  :model-value="rule.enabled !== false"
                  :disabled="saving"
                  @update:model-value="toggleEnabled(rule, $event)"
                />
              </BaseTableCell>
              <BaseTableCell>
                <div class="flex items-center gap-2">
                  <Button
                    sm
                    slate
                    faded
                    :label="$t('BUSINESS_RULES.EDIT')"
                    @click="openEdit(rule)"
                  />
                  <Button
                    sm
                    ruby
                    faded
                    :label="$t('BUSINESS_RULES.REMOVE')"
                    :is-loading="saving"
                    @click="removeRule(rule)"
                  />
                </div>
              </BaseTableCell>
            </template>
          </BaseTableRow>
        </template>
      </BaseTable>
    </template>

    <Dialog
      ref="dialogRef"
      type="edit"
      width="xl"
      overflow-y-auto
      :title="dialogTitle"
      :confirm-button-label="$t('BUSINESS_RULES.SAVE')"
      :cancel-button-label="$t('BUSINESS_RULES.CANCEL')"
      :is-loading="saving"
      @confirm="saveFromDialog"
      @close="formRule = null"
    >
      <BusinessRuleForm v-if="formRule" v-model="formRule" />
    </Dialog>

    <BusinessRulesDryRunDialog v-model="showDryRun" />
  </SettingsLayout>
</template>
