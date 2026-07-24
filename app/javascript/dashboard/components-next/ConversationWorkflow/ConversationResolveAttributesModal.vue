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

const validationRules = computed(() => {
  const rules = {};
  visibleAttributes.value.forEach(attribute => {
    if (attribute.type === ATTRIBUTE_TYPES.LINK) {
      rules[attribute.value] = { required, url };
    } else if (attribute.type === ATTRIBUTE_TYPES.CHECKBOX) {
      // Checkbox doesn't need validation - any selection is valid
      rules[attribute.value] = {};
    } else {
      rules[attribute.value] = { required };
      if (attribute.regexPattern) {
        rules[attribute.value].regexValidation = helpers.withParams(
          { regexCue: attribute.regexCue },
          value => !value || getRegexp(attribute.regexPattern).test(value)
        );
      }
    }
  });
  return rules;
});

const v$ = useVuelidate(validationRules, formValues);

const getErrorMessage = attributeKey => {
  const field = v$.value[attributeKey];
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

const isFormComplete = computed(() =>
  visibleAttributes.value.every(attribute => {
    const value = formValues[attribute.value];

    // For checkbox attributes, ensure the agent has explicitly selected a value
    if (attribute.type === ATTRIBUTE_TYPES.CHECKBOX) {
      return formValues[attribute.value] !== null;
    }
    if (attribute.type === ATTRIBUTE_TYPES.MULTI_LIST) {
      return Array.isArray(value) && value.length > 0;
    }

    // For other attribute types, check for valid non-empty values
    return value !== undefined && value !== null && String(value).trim() !== '';
  })
);

const comboBoxOptions = computed(() => {
  const options = {};
  visibleAttributes.value.forEach(attribute => {
    if (attribute.type === ATTRIBUTE_TYPES.LIST) {
      options[attribute.value] = (attribute.attributeValues || []).map(
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

const open = (attributes = [], initialValues = {}, context = null) => {
  visibleAttributes.value = attributes;
  conversationContext.value = context;

  // Clear existing formValues
  Object.keys(formValues).forEach(key => {
    delete formValues[key];
  });

  // Initialize form values
  attributes.forEach(attribute => {
    const presetValue = initialValues[attribute.value];
    if (presetValue !== undefined && presetValue !== null) {
      formValues[attribute.value] = presetValue;
    } else {
      // Checkbox → null (no pre-selection); multi_list → []; else ''
      let initial = '';
      if (attribute.type === ATTRIBUTE_TYPES.CHECKBOX) {
        initial = null;
      } else if (attribute.type === ATTRIBUTE_TYPES.MULTI_LIST) {
        initial = [];
      }
      formValues[attribute.value] = initial;
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

  emit('submit', {
    attributes: { ...formValues },
    context: conversationContext.value,
  });
  close();
};

defineExpose({ open, close });
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
        :key="attribute.value"
        class="flex flex-col gap-2"
      >
        <div class="flex justify-between items-center">
          <label class="mb-0.5 text-sm font-medium text-n-slate-12">
            {{ attribute.label }}
          </label>
        </div>

        <template v-if="attribute.type === ATTRIBUTE_TYPES.TEXT">
          <TextArea
            v-model="formValues[attribute.value]"
            class="w-full"
            :placeholder="getPlaceholder(ATTRIBUTE_TYPES.TEXT)"
            :message="getErrorMessage(attribute.value)"
            :message-type="v$[attribute.value].$error ? 'error' : 'info'"
            @blur="v$[attribute.value].$touch"
          />
        </template>

        <template v-else-if="attribute.type === ATTRIBUTE_TYPES.NUMBER">
          <Input
            v-model="formValues[attribute.value]"
            type="number"
            size="md"
            :placeholder="getPlaceholder(ATTRIBUTE_TYPES.NUMBER)"
            :message="getErrorMessage(attribute.value)"
            :message-type="v$[attribute.value].$error ? 'error' : 'info'"
            @blur="v$[attribute.value].$touch"
          />
        </template>

        <template v-else-if="attribute.type === ATTRIBUTE_TYPES.LINK">
          <Input
            v-model="formValues[attribute.value]"
            type="url"
            size="md"
            :placeholder="getPlaceholder(ATTRIBUTE_TYPES.LINK)"
            :message="getErrorMessage(attribute.value)"
            :message-type="v$[attribute.value].$error ? 'error' : 'info'"
            @blur="v$[attribute.value].$touch"
          />
        </template>

        <template v-else-if="attribute.type === ATTRIBUTE_TYPES.DATE">
          <Input
            v-model="formValues[attribute.value]"
            type="date"
            size="md"
            :placeholder="getPlaceholder(ATTRIBUTE_TYPES.DATE)"
            :message="getErrorMessage(attribute.value)"
            :message-type="v$[attribute.value].$error ? 'error' : 'info'"
            @blur="v$[attribute.value].$touch"
          />
        </template>

        <template v-else-if="attribute.type === ATTRIBUTE_TYPES.DATETIME">
          <Input
            v-model="formValues[attribute.value]"
            type="datetime-local"
            size="md"
            :placeholder="getPlaceholder(ATTRIBUTE_TYPES.DATETIME)"
            :message="getErrorMessage(attribute.value)"
            :message-type="v$[attribute.value].$error ? 'error' : 'info'"
            @blur="v$[attribute.value].$touch"
          />
        </template>

        <template v-else-if="attribute.type === ATTRIBUTE_TYPES.LIST">
          <ComboBox
            v-model="formValues[attribute.value]"
            :options="comboBoxOptions[attribute.value]"
            :placeholder="getPlaceholder(ATTRIBUTE_TYPES.LIST)"
            :message="getErrorMessage(attribute.value)"
            :message-type="v$[attribute.value].$error ? 'error' : 'info'"
            :has-error="v$[attribute.value].$error"
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
                  Array.isArray(formValues[attribute.value]) &&
                  formValues[attribute.value].includes(option)
                "
                @change="
                  event => {
                    const current = Array.isArray(formValues[attribute.value])
                      ? [...formValues[attribute.value]]
                      : [];
                    if (event.target.checked) {
                      if (!current.includes(option)) current.push(option);
                    } else {
                      const idx = current.indexOf(option);
                      if (idx >= 0) current.splice(idx, 1);
                    }
                    formValues[attribute.value] = current;
                  }
                "
              />
              {{ option }}
            </label>
          </div>
        </template>

        <template v-else-if="attribute.type === ATTRIBUTE_TYPES.CHECKBOX">
          <ChoiceToggle v-model="formValues[attribute.value]" />
        </template>
      </div>
    </div>
  </Dialog>
</template>
