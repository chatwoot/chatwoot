<script setup>
import { ref, computed, reactive, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, url, helpers } from '@vuelidate/validators';
import { getRegexp } from 'shared/helpers/Validators';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import TextArea from 'next/textarea/TextArea.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ChoiceToggle from 'dashboard/components-next/input/ChoiceToggle.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useBusinessRulesStatusGuard } from 'dashboard/composables/useBusinessRulesStatusGuard';
import { ATTRIBUTE_TYPES } from './constants';

const emit = defineEmits(['submit', 'close']);

const { t } = useI18n();
const { checkStatusChange } = useBusinessRulesStatusGuard();

const dialogRef = ref(null);
const fieldsRootRef = ref(null);
const visibleAttributes = ref([]);
const formValues = reactive({});
const conversationContext = ref(null);
const baseConversation = ref(null);
const seedConversationValues = ref({});
const seedContactValues = ref({});
const syncingFields = ref(false);
const previousFieldCount = ref(0);

const pad2 = n => String(n).padStart(2, '0');

const todayDateValue = () => {
  const d = new Date();
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
};

const nowDateTimeValue = () => {
  const d = new Date();
  return `${todayDateValue()}T${pad2(d.getHours())}:${pad2(d.getMinutes())}`;
};

const placeholders = computed(() => ({
  text: t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.TEXT'),
  number: t(
    'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.NUMBER'
  ),
  currency: t(
    'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.CURRENCY'
  ),
  percent: t(
    'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.PERCENT'
  ),
  link: t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.LINK'),
  date: t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.DATE'),
  datetime: t(
    'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.DATETIME'
  ),
  list: t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.LIST'),
  multi_list: t(
    'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.LIST'
  ),
}));

const getPlaceholder = type => placeholders.value[type] || '';

const fieldKey = attribute =>
  `${attribute.attributeModel || 'conversation'}__${attribute.value}`;

const attributeSignature = attrs =>
  (attrs || [])
    .map(a => fieldKey(a))
    .sort()
    .join('|');

const confirmButtonLabel = computed(() => {
  const status = conversationContext.value?.status;
  if (status && status !== 'resolved') {
    return t(
      'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.ACTIONS.CONTINUE'
    );
  }
  return t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.ACTIONS.RESOLVE');
});

const attributeSections = computed(() => {
  const conversation = [];
  const contact = [];
  visibleAttributes.value.forEach(attribute => {
    if (attribute.attributeModel === 'contact') contact.push(attribute);
    else conversation.push(attribute);
  });
  const sections = [];
  if (conversation.length) {
    sections.push({
      id: 'conversation',
      title: t(
        'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.SECTION_CONVERSATION'
      ),
      attributes: conversation,
    });
  }
  if (contact.length) {
    sections.push({
      id: 'contact',
      title: t(
        'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.SECTION_CONTACT'
      ),
      attributes: contact,
    });
  }
  return sections;
});

const showSectionHeaders = computed(() => attributeSections.value.length > 1);

const validationRules = computed(() => {
  const rules = {};
  visibleAttributes.value.forEach(attribute => {
    const key = fieldKey(attribute);
    if (attribute.type === ATTRIBUTE_TYPES.LINK) {
      rules[key] = { required, url };
    } else if (attribute.type === ATTRIBUTE_TYPES.CHECKBOX) {
      rules[key] = {};
    } else {
      rules[key] = { required };
      if (attribute.regexPattern) {
        rules[key].regexValidation = helpers.withParams(
          { regexCue: attribute.regexCue },
          value => !value || getRegexp(attribute.regexPattern).test(value)
        );
      }
    }
  });
  return rules;
});

const v$ = useVuelidate(validationRules, formValues);

const getErrorMessage = attribute => {
  const field = v$.value[fieldKey(attribute)];
  if (!field || !field.$error) return '';

  if (field.url && field.url.$invalid) {
    return t('CUSTOM_ATTRIBUTES.VALIDATIONS.INVALID_URL');
  }
  if (field.regexValidation && field.regexValidation.$invalid) {
    return (
      field.regexValidation.$params?.regexCue ||
      t('CUSTOM_ATTRIBUTES.VALIDATIONS.INVALID_INPUT')
    );
  }
  if (field.required && field.required.$invalid) {
    return t('CUSTOM_ATTRIBUTES.VALIDATIONS.REQUIRED');
  }
  return '';
};

const isNumericType = type =>
  [
    ATTRIBUTE_TYPES.NUMBER,
    ATTRIBUTE_TYPES.CURRENCY,
    ATTRIBUTE_TYPES.PERCENT,
  ].includes(type);

const isBlankFormValue = (value, type) => {
  if (type === ATTRIBUTE_TYPES.CHECKBOX) {
    return value === null || value === undefined;
  }
  if (type === ATTRIBUTE_TYPES.MULTI_LIST) {
    return !Array.isArray(value) || value.length === 0;
  }
  if (value === undefined || value === null || String(value).trim() === '') {
    return true;
  }
  if (isNumericType(type)) {
    const numeric = Number(value);
    if (!Number.isNaN(numeric) && numeric === 0) return true;
  }
  return false;
};

const isFormComplete = computed(() =>
  visibleAttributes.value.every(attribute => {
    const key = fieldKey(attribute);
    return !isBlankFormValue(formValues[key], attribute.type);
  })
);

const filledCount = computed(
  () =>
    visibleAttributes.value.filter(
      attribute =>
        !isBlankFormValue(formValues[fieldKey(attribute)], attribute.type)
    ).length
);

const progressLabel = computed(() =>
  t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PROGRESS', {
    filled: filledCount.value,
    total: visibleAttributes.value.length,
  })
);

const scrollNewFieldsIntoView = async () => {
  await nextTick();
  const root = fieldsRootRef.value;
  if (!root) return;
  const fields = root.querySelectorAll('[data-resolve-field]');
  const last = fields[fields.length - 1];
  last?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
};

const scrollFirstBlankIntoView = async () => {
  await nextTick();
  const root = fieldsRootRef.value;
  if (!root) return;
  const blank = visibleAttributes.value.find(attribute =>
    isBlankFormValue(formValues[fieldKey(attribute)], attribute.type)
  );
  if (!blank) return;
  const el = root.querySelector(
    `[data-resolve-field-key="${fieldKey(blank)}"]`
  );
  el?.scrollIntoView({ behavior: 'smooth', block: 'center' });
};

/** Empty shell for missing fields (so validation can mark them red). */
const emptyValueFor = attribute => {
  if (attribute.type === ATTRIBUTE_TYPES.CHECKBOX) return null;
  if (attribute.type === ATTRIBUTE_TYPES.MULTI_LIST) return [];
  return '';
};

/** Sensible empty-state defaults so agents spend less time clicking. */
const defaultValueFor = attribute => {
  if (attribute.type === ATTRIBUTE_TYPES.CHECKBOX) return false;
  if (attribute.type === ATTRIBUTE_TYPES.MULTI_LIST) {
    const options = attribute.attributeValues || [];
    return options.length === 1 ? [options[0]] : [];
  }
  if (attribute.type === ATTRIBUTE_TYPES.LIST) {
    const options = attribute.attributeValues || [];
    return options.length === 1 ? options[0] : '';
  }
  if (attribute.type === ATTRIBUTE_TYPES.DATE) return todayDateValue();
  if (attribute.type === ATTRIBUTE_TYPES.DATETIME) return nowDateTimeValue();
  return '';
};

const valueFromSeed = attribute => {
  const source =
    attribute.attributeModel === 'contact'
      ? seedContactValues.value
      : seedConversationValues.value;
  const presetValue = source?.[attribute.value];
  if (
    presetValue === undefined ||
    presetValue === null ||
    (typeof presetValue === 'string' && presetValue.trim() === '') ||
    isBlankFormValue(presetValue, attribute.type)
  ) {
    return undefined;
  }
  return presetValue;
};

/** Prefer conversation value; otherwise empty (open) or smart default (chain). */
const resolveInitialValue = (attribute, { useSmartDefault = false } = {}) => {
  const seeded = valueFromSeed(attribute);
  if (seeded !== undefined) return seeded;
  if (useSmartDefault) return defaultValueFor(attribute);
  return emptyValueFor(attribute);
};

const touchBlankFields = async () => {
  await nextTick();
  visibleAttributes.value.forEach(attribute => {
    const key = fieldKey(attribute);
    if (isBlankFormValue(formValues[key], attribute.type)) {
      v$.value[key]?.$touch?.();
    }
  });
  await scrollFirstBlankIntoView();
};

const comboBoxOptions = computed(() => {
  const options = {};
  visibleAttributes.value.forEach(attribute => {
    if (attribute.type === ATTRIBUTE_TYPES.LIST) {
      options[fieldKey(attribute)] = (attribute.attributeValues || []).map(
        option => ({
          value: option,
          label: option,
        })
      );
    }
  });
  return options;
});

const setToday = attribute => {
  formValues[fieldKey(attribute)] = todayDateValue();
};

const setNow = attribute => {
  formValues[fieldKey(attribute)] = nowDateTimeValue();
};

const collectDraftAttributes = () => {
  const conversationAttributes = {};
  const contactAttributes = {};
  visibleAttributes.value.forEach(attribute => {
    const value = formValues[fieldKey(attribute)];
    if (attribute.attributeModel === 'contact') {
      contactAttributes[attribute.value] = value;
    } else {
      conversationAttributes[attribute.value] = value;
    }
  });
  return { conversationAttributes, contactAttributes };
};

const buildDraftConversation = () => {
  const conversation = baseConversation.value;
  if (!conversation) return null;
  const { conversationAttributes, contactAttributes } =
    collectDraftAttributes();
  const sender = conversation.meta?.sender || {};
  return {
    ...conversation,
    custom_attributes: {
      ...(conversation.custom_attributes || {}),
      ...conversationAttributes,
    },
    meta: {
      ...(conversation.meta || {}),
      sender: {
        ...sender,
        custom_attributes: {
          ...(sender.custom_attributes || {}),
          ...contactAttributes,
        },
      },
    },
  };
};

const syncVisibleAttributes = nextRequired => {
  const next = Array.isArray(nextRequired) ? nextRequired : [];
  if (
    attributeSignature(next) === attributeSignature(visibleAttributes.value)
  ) {
    return false;
  }

  syncingFields.value = true;
  const keepKeys = new Set(next.map(fieldKey));
  const previousValues = { ...formValues };

  Object.keys(formValues).forEach(key => {
    if (!keepKeys.has(key)) delete formValues[key];
  });

  const previousOrder = visibleAttributes.value.map(fieldKey);
  const ordered = [];
  const seen = new Set();

  // Keep prior order for fields that remain required (e.g. tipo stays first).
  previousOrder.forEach(key => {
    const attr = next.find(a => fieldKey(a) === key);
    if (attr) {
      ordered.push(attr);
      seen.add(key);
    }
  });
  next.forEach(attr => {
    const key = fieldKey(attr);
    if (!seen.has(key)) {
      ordered.push(attr);
      seen.add(key);
    }
  });

  ordered.forEach(attribute => {
    const key = fieldKey(attribute);
    if (
      previousValues[key] !== undefined &&
      !isBlankFormValue(previousValues[key], attribute.type)
    ) {
      formValues[key] = previousValues[key];
    } else if (formValues[key] === undefined) {
      // New field from chain: seed from conversation, else smart default.
      formValues[key] = resolveInitialValue(attribute, {
        useSmartDefault: true,
      });
    }
  });

  visibleAttributes.value = ordered;
  syncingFields.value = false;

  const grew = ordered.length > previousFieldCount.value;
  previousFieldCount.value = ordered.length;
  if (grew) scrollNewFieldsIntoView();

  return true;
};

const reevaluateDependentRules = async ({ touchBlanks = false } = {}) => {
  if (syncingFields.value) return;
  if (!baseConversation.value || !conversationContext.value) return;

  const draft = buildDraftConversation();
  if (!draft) return;

  const targetStatus =
    conversationContext.value.status ||
    conversationContext.value.targetStatus ||
    'resolved';
  const guard = checkStatusChange(draft, targetStatus);
  // Use full required set (not only blanks) so filled triggers stay in the form.
  const changed = syncVisibleAttributes(
    guard.requiredAttributes?.length
      ? guard.requiredAttributes
      : guard.missingAttributes || []
  );
  if (changed) {
    await nextTick();
    await reevaluateDependentRules({ touchBlanks });
    return;
  }
  if (touchBlanks) await touchBlankFields();
};

watch(
  formValues,
  () => {
    reevaluateDependentRules();
  },
  { deep: true }
);

const close = () => {
  dialogRef.value?.close();
  conversationContext.value = null;
  baseConversation.value = null;
  seedConversationValues.value = {};
  seedContactValues.value = {};
  v$.value.$reset();
};

const open = (
  attributes = [],
  initialConversationValues = {},
  context = null,
  initialContactValues = {}
) => {
  conversationContext.value = context;
  baseConversation.value = context?.conversation || null;
  seedConversationValues.value = {
    ...(baseConversation.value?.custom_attributes || {}),
    ...initialConversationValues,
  };
  seedContactValues.value = {
    ...(baseConversation.value?.meta?.sender?.custom_attributes || {}),
    ...initialContactValues,
  };
  syncingFields.value = true;

  Object.keys(formValues).forEach(key => {
    delete formValues[key];
  });

  previousFieldCount.value = 0;
  visibleAttributes.value = attributes;

  attributes.forEach(attribute => {
    const key = fieldKey(attribute);
    // Keep blanks empty so missing fields show validation error on open.
    formValues[key] = resolveInitialValue(attribute, {
      useSmartDefault: false,
    });
  });

  syncingFields.value = false;
  v$.value.$reset();
  dialogRef.value?.open();
  nextTick(async () => {
    await reevaluateDependentRules({ touchBlanks: true });
  });
};

const handleClose = () => {
  conversationContext.value = null;
  v$.value.$reset();
  emit('close');
};

const handleConfirm = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) {
    return;
  }

  await reevaluateDependentRules();
  if (!isFormComplete.value) {
    return;
  }

  const { conversationAttributes, contactAttributes } =
    collectDraftAttributes();

  emit('submit', {
    attributes: conversationAttributes,
    contactAttributes,
    context: conversationContext.value,
  });
  close();
};

defineExpose({ open, close, fieldKey });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="lg"
    position="top"
    body-scroll
    :title="t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.TITLE')"
    :description="
      t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.DESCRIPTION')
    "
    :confirm-button-label="confirmButtonLabel"
    :cancel-button-label="
      t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.ACTIONS.CANCEL')
    "
    :disable-confirm-button="!isFormComplete"
    @confirm="handleConfirm"
    @close="handleClose"
  >
    <div ref="fieldsRootRef" class="flex flex-col gap-4 pb-2">
      <p
        v-if="visibleAttributes.length > 1"
        class="mb-0 text-xs text-n-slate-11"
      >
        {{ progressLabel }}
      </p>

      <section
        v-for="section in attributeSections"
        :key="section.id"
        class="flex flex-col gap-4"
      >
        <h3
          v-if="showSectionHeaders"
          class="text-xs font-semibold uppercase tracking-wide text-n-slate-11"
        >
          {{ section.title }}
        </h3>

        <div
          v-for="attribute in section.attributes"
          :key="fieldKey(attribute)"
          data-resolve-field
          :data-resolve-field-key="fieldKey(attribute)"
          class="flex flex-col gap-1.5"
        >
          <div class="flex items-center justify-between gap-2">
            <label class="mb-0 text-sm font-medium text-n-slate-12">
              {{ attribute.label }}
              <span class="text-n-ruby-9" aria-hidden="true">{{
                t(
                  'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.REQUIRED_MARK'
                )
              }}</span>
            </label>
            <Button
              v-if="attribute.type === ATTRIBUTE_TYPES.DATE"
              type="button"
              size="xs"
              ghost
              slate
              :label="
                t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.USE_TODAY')
              "
              @click="setToday(attribute)"
            />
            <Button
              v-else-if="attribute.type === ATTRIBUTE_TYPES.DATETIME"
              type="button"
              size="xs"
              ghost
              slate
              :label="
                t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.USE_NOW')
              "
              @click="setNow(attribute)"
            />
          </div>

          <template v-if="attribute.type === ATTRIBUTE_TYPES.TEXT">
            <TextArea
              v-model="formValues[fieldKey(attribute)]"
              class="w-full min-h-[4.5rem]"
              :placeholder="getPlaceholder(ATTRIBUTE_TYPES.TEXT)"
              :message="getErrorMessage(attribute)"
              :message-type="v$[fieldKey(attribute)].$error ? 'error' : 'info'"
              @blur="v$[fieldKey(attribute)].$touch"
            />
          </template>

          <template
            v-else-if="
              attribute.type === ATTRIBUTE_TYPES.NUMBER ||
              attribute.type === ATTRIBUTE_TYPES.CURRENCY ||
              attribute.type === ATTRIBUTE_TYPES.PERCENT
            "
          >
            <Input
              v-model="formValues[fieldKey(attribute)]"
              type="number"
              size="md"
              :placeholder="getPlaceholder(attribute.type)"
              :message="getErrorMessage(attribute)"
              :message-type="v$[fieldKey(attribute)].$error ? 'error' : 'info'"
              @blur="v$[fieldKey(attribute)].$touch"
            />
          </template>

          <template v-else-if="attribute.type === ATTRIBUTE_TYPES.LINK">
            <Input
              v-model="formValues[fieldKey(attribute)]"
              type="url"
              size="md"
              :placeholder="getPlaceholder(ATTRIBUTE_TYPES.LINK)"
              :message="getErrorMessage(attribute)"
              :message-type="v$[fieldKey(attribute)].$error ? 'error' : 'info'"
              @blur="v$[fieldKey(attribute)].$touch"
            />
          </template>

          <template v-else-if="attribute.type === ATTRIBUTE_TYPES.DATE">
            <Input
              v-model="formValues[fieldKey(attribute)]"
              type="date"
              size="md"
              :placeholder="getPlaceholder(ATTRIBUTE_TYPES.DATE)"
              :message="getErrorMessage(attribute)"
              :message-type="v$[fieldKey(attribute)].$error ? 'error' : 'info'"
              @blur="v$[fieldKey(attribute)].$touch"
            />
          </template>

          <template v-else-if="attribute.type === ATTRIBUTE_TYPES.DATETIME">
            <Input
              v-model="formValues[fieldKey(attribute)]"
              type="datetime-local"
              size="md"
              :placeholder="getPlaceholder(ATTRIBUTE_TYPES.DATETIME)"
              :message="getErrorMessage(attribute)"
              :message-type="v$[fieldKey(attribute)].$error ? 'error' : 'info'"
              @blur="v$[fieldKey(attribute)].$touch"
            />
          </template>

          <template v-else-if="attribute.type === ATTRIBUTE_TYPES.LIST">
            <ComboBox
              v-model="formValues[fieldKey(attribute)]"
              :options="comboBoxOptions[fieldKey(attribute)]"
              :placeholder="getPlaceholder(ATTRIBUTE_TYPES.LIST)"
              :message="getErrorMessage(attribute)"
              :has-error="v$[fieldKey(attribute)].$error"
              teleport
              class="w-full"
            />
          </template>

          <template v-else-if="attribute.type === ATTRIBUTE_TYPES.MULTI_LIST">
            <div class="flex flex-col gap-1.5">
              <label
                v-for="option in attribute.attributeValues || []"
                :key="option"
                class="flex items-center gap-2 text-sm text-n-slate-12"
              >
                <input
                  type="checkbox"
                  :checked="
                    Array.isArray(formValues[fieldKey(attribute)]) &&
                    formValues[fieldKey(attribute)].includes(option)
                  "
                  @change="
                    event => {
                      const key = fieldKey(attribute);
                      const current = Array.isArray(formValues[key])
                        ? [...formValues[key]]
                        : [];
                      if (event.target.checked) {
                        if (!current.includes(option)) current.push(option);
                      } else {
                        const idx = current.indexOf(option);
                        if (idx >= 0) current.splice(idx, 1);
                      }
                      formValues[key] = current;
                    }
                  "
                />
                {{ option }}
              </label>
            </div>
          </template>

          <template v-else-if="attribute.type === ATTRIBUTE_TYPES.CHECKBOX">
            <ChoiceToggle v-model="formValues[fieldKey(attribute)]" />
          </template>
        </div>
      </section>
    </div>
  </Dialog>
</template>
