<script setup>
import { ref, computed, h, useTemplateRef, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useOperators } from 'dashboard/components-next/filter/operators';
import ConditionRow from 'dashboard/components-next/filter/ConditionRow.vue';
import AutomationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import {
  generateAutomationPayload,
  getAttributes,
  getFileName,
  showActionInput,
} from 'dashboard/helper/automationHelper';
import { validateAutomation } from 'dashboard/helper/validations';
import { AUTOMATION_RULE_EVENTS, AUTOMATION_ACTION_TYPES } from './constants';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['create', 'edit'].includes(value),
  },
  automationTypes: {
    type: Object,
    required: true,
  },
  getConditionDropdownValues: {
    type: Function,
    required: true,
  },
  getActionDropdownValues: {
    type: Function,
    required: true,
  },
  appendNewCondition: {
    type: Function,
    required: true,
  },
  appendNewAction: {
    type: Function,
    required: true,
  },
  removeFilter: {
    type: Function,
    required: true,
  },
  removeAction: {
    type: Function,
    required: true,
  },
  resetAction: {
    type: Function,
    required: true,
  },
  onEventChange: {
    type: Function,
    required: true,
  },
});

const emit = defineEmits(['save']);
const automation = defineModel('automation', { type: Object, default: null });

const INPUT_TYPE_MAP = {
  multi_select: 'multiSelect',
  search_select: 'searchSelect',
  plain_text: 'plainText',
  comma_separated_plain_text: 'plainText',
  date: 'date',
};

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();
const { operators } = useOperators();

const dialogRef = ref(null);
const conditionsRef = useTemplateRef('conditionsRef');
const errors = ref({});

const isEditMode = computed(() => props.mode === 'edit');

const titleKey = computed(() =>
  isEditMode.value ? 'AUTOMATION.EDIT.TITLE' : 'AUTOMATION.ADD.TITLE'
);
const cancelKey = computed(() =>
  isEditMode.value
    ? 'AUTOMATION.EDIT.CANCEL_BUTTON_TEXT'
    : 'AUTOMATION.ADD.CANCEL_BUTTON_TEXT'
);
const submitKey = computed(() =>
  isEditMode.value ? 'AUTOMATION.EDIT.SUBMIT' : 'AUTOMATION.ADD.SUBMIT'
);

const getTranslatedAttributes = (type, event) => {
  return getAttributes(type, event).map(attribute => {
    const skipTranslation =
      attribute.customAttributeType ||
      ['contact_custom_attribute', 'conversation_custom_attribute'].includes(
        attribute.key
      );
    return {
      ...attribute,
      name: skipTranslation
        ? attribute.name
        : t(`AUTOMATION.ATTRIBUTES.${attribute.name}`),
    };
  });
};

const eventName = computed(() => automation.value?.event_name);

const filterTypes = computed(() => {
  const event = eventName.value;
  if (!event || !props.automationTypes[event]) return [];

  const attributes = getTranslatedAttributes(props.automationTypes, event);

  return attributes.map(attr => {
    if (attr.disabled) {
      return { value: attr.key, label: attr.name, disabled: true };
    }

    const mappedInputType = INPUT_TYPE_MAP[attr.inputType] || 'plainText';
    const options = props.getConditionDropdownValues(attr.key) || [];

    const filterOperators = (attr.filterOperators || []).map(op => {
      const enriched = operators.value[op.value];
      if (enriched) return enriched;
      return {
        value: op.value,
        label: t(`FILTER.OPERATOR_LABELS.${op.value}`),
        hasInput: true,
        inputOverride: null,
        icon: h('span', { class: 'i-ph-equals-bold !text-n-blue-11' }),
      };
    });

    return {
      attributeKey: attr.key,
      value: attr.key,
      attributeName: attr.name,
      label: attr.name,
      inputType: mappedInputType,
      options,
      filterOperators,
      dataType: 'text',
      attributeModel: attr.customAttributeType || 'standard',
    };
  });
});

const automationRuleEvents = computed(() =>
  AUTOMATION_RULE_EVENTS.map(event => ({
    ...event,
    value: t(`AUTOMATION.EVENTS.${event.value}`),
  }))
);

const hasAutomationMutated = computed(() => {
  return Boolean(
    automation.value?.conditions[0]?.values ||
      automation.value?.actions[0]?.action_params?.length
  );
});

const automationActionTypes = computed(() => {
  const actionTypes = isCloudFeatureEnabled('sla')
    ? AUTOMATION_ACTION_TYPES
    : AUTOMATION_ACTION_TYPES.filter(({ key }) => key !== 'add_sla');

  return actionTypes.map(action => ({
    ...action,
    label: t(`AUTOMATION.ACTIONS.${action.label}`),
  }));
});

const hasConditionErrors = computed(() =>
  Object.keys(errors.value).some(key => key.startsWith('condition_'))
);

const hasActionErrors = computed(() =>
  Object.keys(errors.value).some(key => key.startsWith('action_'))
);

watch(
  () => automation.value,
  () => {
    if (Object.keys(errors.value).length) {
      errors.value = {};
    }
  },
  { deep: true }
);

const isConditionsValid = () => {
  if (!conditionsRef.value) return true;
  return conditionsRef.value.every(condition => condition.validate());
};

const resetValidation = () => {
  errors.value = {};
  conditionsRef.value?.forEach(c => c.resetValidation());
};

const syncCustomAttributeTypes = () => {
  automation.value.conditions.forEach(condition => {
    const filterType = filterTypes.value.find(
      ft => ft.attributeKey === condition.attribute_key
    );
    condition.custom_attribute_type =
      filterType?.attributeModel === 'standard'
        ? ''
        : filterType?.attributeModel || '';
  });
};

const open = () => {
  resetValidation();
  dialogRef.value?.open();
};

const close = () => {
  resetValidation();
  dialogRef.value?.close();
};

const emitSaveAutomation = () => {
  syncCustomAttributeTypes();
  const conditionsValid = isConditionsValid();
  errors.value = validateAutomation(automation.value);
  if (Object.keys(errors.value).length === 0 && conditionsValid) {
    const payload = generateAutomationPayload(automation.value);
    emit('save', payload, props.mode);
  }
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="3xl"
    position="top"
    :title="$t(titleKey)"
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
  >
    <div v-if="automation" class="flex flex-col w-full">
      <woot-input
        v-model="automation.name"
        :label="$t('AUTOMATION.ADD.FORM.NAME.LABEL')"
        type="text"
        :class="{ error: errors.name }"
        :error="errors.name ? $t('AUTOMATION.ADD.FORM.NAME.ERROR') : ''"
        :placeholder="$t('AUTOMATION.ADD.FORM.NAME.PLACEHOLDER')"
      />
      <woot-input
        v-model="automation.description"
        :label="$t('AUTOMATION.ADD.FORM.DESC.LABEL')"
        type="text"
        :class="{ error: errors.description }"
        :error="errors.description ? $t('AUTOMATION.ADD.FORM.DESC.ERROR') : ''"
        :placeholder="$t('AUTOMATION.ADD.FORM.DESC.PLACEHOLDER')"
      />
      <div class="mb-6">
        <label :class="{ error: errors.event_name }">
          {{ $t('AUTOMATION.ADD.FORM.EVENT.LABEL') }}
          <select
            v-model="automation.event_name"
            class="m-0"
            @change="onEventChange()"
          >
            <option
              v-for="event in automationRuleEvents"
              :key="event.key"
              :value="event.key"
            >
              {{ event.value }}
            </option>
          </select>
          <span v-if="errors.event_name" class="message">
            {{ $t('AUTOMATION.ADD.FORM.EVENT.ERROR') }}
          </span>
        </label>
        <p
          v-if="!isEditMode && hasAutomationMutated"
          class="text-xs text-right text-n-teal-10 pt-1"
        >
          {{ $t('AUTOMATION.FORM.RESET_MESSAGE') }}
        </p>
      </div>
      <!-- Conditions Start -->
      <section class="mb-5">
        <label>
          {{ $t('AUTOMATION.ADD.FORM.CONDITIONS.LABEL') }}
        </label>
        <ul
          class="grid gap-4 list-none p-3 mb-4 outline outline-1 rounded-xl -outline-offset-1"
          :class="
            hasConditionErrors
              ? 'outline-n-ruby-5 bg-n-ruby-2/50'
              : 'outline-n-weak dark:outline-n-strong'
          "
        >
          <template v-for="(condition, i) in automation.conditions" :key="i">
            <ConditionRow
              v-if="i === 0"
              ref="conditionsRef"
              v-model:attribute-key="automation.conditions[i].attribute_key"
              v-model:filter-operator="automation.conditions[i].filter_operator"
              v-model:values="automation.conditions[i].values"
              :filter-types="filterTypes"
              :show-query-operator="false"
              @remove="removeFilter(i)"
            />
            <ConditionRow
              v-else
              ref="conditionsRef"
              v-model:attribute-key="automation.conditions[i].attribute_key"
              v-model:filter-operator="automation.conditions[i].filter_operator"
              v-model:query-operator="
                automation.conditions[i - 1].query_operator
              "
              v-model:values="automation.conditions[i].values"
              :filter-types="filterTypes"
              show-query-operator
              @remove="removeFilter(i)"
            />
          </template>
          <div>
            <NextButton
              icon="i-lucide-plus"
              blue
              faded
              sm
              :label="$t('AUTOMATION.ADD.CONDITION_BUTTON_LABEL')"
              @click="appendNewCondition"
            />
          </div>
        </ul>
      </section>
      <!-- Conditions End -->
      <!-- Actions Start -->
      <section>
        <label>
          {{ $t('AUTOMATION.ADD.FORM.ACTIONS.LABEL') }}
        </label>
        <ul
          class="grid list-none p-3 mb-4 outline outline-1 rounded-xl -outline-offset-1 border-solid"
          :class="
            hasActionErrors
              ? 'outline-n-ruby-5 bg-n-ruby-2/50'
              : 'outline-n-weak dark:outline-n-strong'
          "
        >
          <AutomationActionInput
            v-for="(action, i) in automation.actions"
            :key="i"
            v-model="automation.actions[i]"
            :action-types="automationActionTypes"
            dropdown-max-height="max-h-[7.5rem]"
            :dropdown-values="getActionDropdownValues(action.action_name)"
            :show-action-input="
              showActionInput(automationActionTypes, action.action_name)
            "
            :conditions="automation.conditions"
            :error-message="
              errors[`action_${i}`]
                ? $t(`AUTOMATION.ERRORS.${errors[`action_${i}`]}`)
                : ''
            "
            :initial-file-name="
              isEditMode ? getFileName(action, automation.files) : ''
            "
            @reset-action="resetAction(i)"
            @remove-action="removeAction(i)"
          />
          <div class="pt-2">
            <NextButton
              icon="i-lucide-plus"
              blue
              faded
              sm
              :label="$t('AUTOMATION.ADD.ACTION_BUTTON_LABEL')"
              @click="appendNewAction"
            />
          </div>
        </ul>
      </section>
      <!-- Actions End -->
      <div class="w-full mt-8">
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-4">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t(cancelKey)"
            @click.prevent="close"
          />
          <NextButton
            solid
            blue
            type="submit"
            :label="$t(submitKey)"
            @click="emitSaveAutomation"
          />
        </div>
      </div>
    </div>
  </Dialog>
</template>
