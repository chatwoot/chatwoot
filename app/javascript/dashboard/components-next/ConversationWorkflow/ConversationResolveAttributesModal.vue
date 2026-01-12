<script setup>
import { ref, computed, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, url } from '@vuelidate/validators';
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
  list: t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.LIST'),
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
    }
  });
  return rules;
});

const v$ = useVuelidate(validationRules, formValues);

const getErrorMessage = attributeKey => {
  const field = v$.value[attributeKey];
  if (!field || !field.$error) return '';

  const attribute = visibleAttributes.value.find(
    attr => attr.value === attributeKey
  );
  if (!attribute) return '';

  if (field.url && field.url.$invalid) {
    return t('CUSTOM_ATTRIBUTES.VALIDATIONS.INVALID_URL');
  }
  if (field.required && field.required.$invalid) {
    return t('CUSTOM_ATTRIBUTES.VALIDATIONS.REQUIRED');
  }
  return '';
};

const isFormComplete = computed(() =>
  visibleAttributes.value.every(attribute => {
    const value = formValues[attribute.value];

    // For checkbox attributes, only check if the key exists (matches composable logic)
    if (attribute.type === ATTRIBUTE_TYPES.CHECKBOX) {
      return attribute.value in formValues;
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
      // For checkbox attributes, initialize to null to avoid pre-selection
      // For other attributes, initialize to empty string
      formValues[attribute.value] =
        attribute.type === ATTRIBUTE_TYPES.CHECKBOX ? null : '';
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
          <label
            class="text-sm font-medium"
            :class="
              v$[attribute.value].$error ? 'text-n-ruby-11' : 'text-n-slate-12'
            "
          >
            {{ attribute.label }}
          </label>
        </div>

        <template v-if="attribute.type === ATTRIBUTE_TYPES.TEXT">
          <div>
            <TextArea
              v-model="formValues[attribute.value]"
              class="w-full"
              :placeholder="getPlaceholder(ATTRIBUTE_TYPES.TEXT)"
              @blur="v$[attribute.value].$touch"
            />
            <span
              v-if="v$[attribute.value].$error"
              class="block w-full text-sm font-normal text-n-ruby-11 mt-1"
            >
              {{ getErrorMessage(attribute.value) }}
            </span>
          </div>
        </template>

        <template v-else-if="attribute.type === ATTRIBUTE_TYPES.NUMBER">
          <div>
            <Input
              v-model="formValues[attribute.value]"
              type="number"
              size="md"
              :placeholder="getPlaceholder(ATTRIBUTE_TYPES.NUMBER)"
              @blur="v$[attribute.value].$touch"
            />
            <span
              v-if="v$[attribute.value].$error"
              class="block w-full text-sm font-normal text-n-ruby-11 mt-1"
            >
              {{ getErrorMessage(attribute.value) }}
            </span>
          </div>
        </template>

        <template v-else-if="attribute.type === ATTRIBUTE_TYPES.LINK">
          <div>
            <Input
              v-model="formValues[attribute.value]"
              type="url"
              size="md"
              :placeholder="getPlaceholder(ATTRIBUTE_TYPES.LINK)"
              @blur="v$[attribute.value].$touch"
            />
            <span
              v-if="v$[attribute.value].$error"
              class="block w-full text-sm font-normal text-n-ruby-11 mt-1"
            >
              {{ getErrorMessage(attribute.value) }}
            </span>
          </div>
        </template>

        <template v-else-if="attribute.type === ATTRIBUTE_TYPES.DATE">
          <div>
            <Input
              v-model="formValues[attribute.value]"
              type="date"
              size="md"
              :placeholder="getPlaceholder(ATTRIBUTE_TYPES.DATE)"
              @blur="v$[attribute.value].$touch"
            />
            <span
              v-if="v$[attribute.value].$error"
              class="block w-full text-sm font-normal text-n-ruby-11 mt-1"
            >
              {{ getErrorMessage(attribute.value) }}
            </span>
          </div>
        </template>

        <template v-else-if="attribute.type === ATTRIBUTE_TYPES.LIST">
          <div>
            <ComboBox
              v-model="formValues[attribute.value]"
              :options="comboBoxOptions[attribute.value]"
              :placeholder="getPlaceholder(ATTRIBUTE_TYPES.LIST)"
              class="w-full"
            />
            <span
              v-if="v$[attribute.value].$error"
              class="block w-full text-sm font-normal text-n-ruby-11 mt-1"
            >
              {{ getErrorMessage(attribute.value) }}
            </span>
          </div>
        </template>

        <template v-else-if="attribute.type === ATTRIBUTE_TYPES.CHECKBOX">
          <ChoiceToggle v-model="formValues[attribute.value]" />
        </template>
      </div>
    </div>
  </Dialog>
</template>
