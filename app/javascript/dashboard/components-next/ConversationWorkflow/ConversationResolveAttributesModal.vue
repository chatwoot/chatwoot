<script setup>
import { ref, computed, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, url, helpers } from '@vuelidate/validators';
import { getRegexp } from 'shared/helpers/Validators';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import TextArea from 'next/textarea/TextArea.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ChoiceToggle from 'dashboard/components-next/input/ChoiceToggle.vue';
import { ATTRIBUTE_TYPES } from './constants';

const emit = defineEmits(['submit']);

const { t } = useI18n();

const dialogRef = ref(null);
const visibleAttributes = ref([]);
const formValues = reactive({});
const conversationContext = ref(null);

const placeholders = computed(() => ({
  text: t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.TEXT'),
  number: t(
    'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.NUMBER'
  ),
  currency: t(
    'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.NUMBER'
  ),
  percent: t(
    'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.NUMBER'
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

const isFormComplete = computed(() =>
  visibleAttributes.value.every(attribute => {
    const key = fieldKey(attribute);
    const value = formValues[key];

    if (attribute.type === ATTRIBUTE_TYPES.CHECKBOX) {
      return value !== null;
    }
    if (attribute.type === ATTRIBUTE_TYPES.MULTI_LIST) {
      return Array.isArray(value) && value.length > 0;
    }
    if (value === undefined || value === null || String(value).trim() === '') {
      return false;
    }
    if (isNumericType(attribute.type)) {
      const numeric = Number(value);
      if (!Number.isNaN(numeric) && numeric === 0) return false;
    }
    return true;
  })
);

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

const close = () => {
  dialogRef.value?.close();
  conversationContext.value = null;
  v$.value.$reset();
};

const open = (
  attributes = [],
  initialConversationValues = {},
  context = null,
  initialContactValues = {}
) => {
  visibleAttributes.value = attributes;
  conversationContext.value = context;

  Object.keys(formValues).forEach(key => {
    delete formValues[key];
  });

  attributes.forEach(attribute => {
    const key = fieldKey(attribute);
    const source =
      attribute.attributeModel === 'contact'
        ? initialContactValues
        : initialConversationValues;
    const presetValue = source[attribute.value];
    if (presetValue !== undefined && presetValue !== null) {
      formValues[key] = presetValue;
    } else {
      let initial = '';
      if (attribute.type === ATTRIBUTE_TYPES.CHECKBOX) {
        initial = null;
      } else if (attribute.type === ATTRIBUTE_TYPES.MULTI_LIST) {
        initial = [];
      }
      formValues[key] = initial;
    }
  });

  v$.value.$reset();
  dialogRef.value?.open();
};

const handleConfirm = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) {
    return;
  }

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
    :title="t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.TITLE')"
    :description="
      t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.DESCRIPTION')
    "
    :confirm-button-label="
      t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.ACTIONS.RESOLVE')
    "
    :cancel-button-label="
      t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.ACTIONS.CANCEL')
    "
    :disable-confirm-button="!isFormComplete"
    @confirm="handleConfirm"
  >
    <div class="flex flex-col gap-4">
      <div
        v-for="attribute in visibleAttributes"
        :key="fieldKey(attribute)"
        class="flex flex-col gap-2"
      >
        <div class="flex items-center gap-2">
          <label class="mb-0 text-sm font-medium text-n-slate-12">
            {{ attribute.label }}
          </label>
          <span
            class="rounded bg-n-alpha-2 px-1.5 py-0.5 text-[10px] uppercase tracking-wide text-n-slate-11"
          >
            {{
              attribute.attributeModel === 'contact'
                ? $t('BUSINESS_RULES.FIELDS.SECTION_CONTACT')
                : $t('BUSINESS_RULES.FIELDS.SECTION_CONVERSATION')
            }}
          </span>
        </div>

        <template v-if="attribute.type === ATTRIBUTE_TYPES.TEXT">
          <TextArea
            v-model="formValues[fieldKey(attribute)]"
            class="w-full"
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
            :message-type="v$[fieldKey(attribute)].$error ? 'error' : 'info'"
            :has-error="v$[fieldKey(attribute)].$error"
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
    </div>
  </Dialog>
</template>
