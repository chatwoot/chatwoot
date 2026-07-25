<!-- Attribute type "Text, URL, Number, currency, percent" -->
<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { isValidURL } from 'dashboard/helper/URLHelper.js';
import { getRegexp } from 'shared/helpers/Validators';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  attribute: {
    type: Object,
    required: true,
  },
  readOnly: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update', 'focusChange']);

const { t } = useI18n();
const isEditingValue = ref(false);
const editedValue = ref(props.attribute.value || '');
const currencyPrefix = '$';
const percentSuffix = '%';

watch(
  () => props.attribute.value,
  val => {
    if (!isEditingValue.value) editedValue.value = val || '';
  }
);

const isAttributeTypeLink = computed(
  () => props.attribute.attributeDisplayType === 'link'
);

const isAttributeTypeText = computed(
  () => props.attribute.attributeDisplayType === 'text'
);

const isAttributeTypeCurrency = computed(
  () => props.attribute.attributeDisplayType === 'currency'
);

const isAttributeTypePercent = computed(
  () => props.attribute.attributeDisplayType === 'percent'
);

const isAttributeTypeNumber = computed(
  () =>
    props.attribute.attributeDisplayType === 'number' ||
    isAttributeTypeCurrency.value ||
    isAttributeTypePercent.value
);

const displayValue = computed(() => {
  const val = props.attribute.value;
  if (val === null || val === undefined || val === '') return '';
  if (isAttributeTypeCurrency.value) return `$${val}`;
  if (isAttributeTypePercent.value) return `${val}%`;
  return val;
});

const rules = computed(() => ({
  editedValue: {
    required,
    ...(isAttributeTypeLink.value && {
      url: value => !value || isValidURL(value),
    }),
    ...(isAttributeTypeText.value &&
      props.attribute.regexPattern && {
        regexValidation: value => {
          if (!value) return true;
          try {
            return getRegexp(props.attribute.regexPattern).test(value);
          } catch {
            return false;
          }
        },
      }),
  },
}));

const v$ = useVuelidate(rules, { editedValue });

const hasError = computed(() => v$.value.$error);

const attributeErrorMessage = computed(() => {
  if (!hasError.value) return '';

  if (isAttributeTypeLink.value && v$.value.editedValue.url?.$invalid) {
    return t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.VALIDATIONS.INVALID_URL');
  }

  if (
    isAttributeTypeText.value &&
    props.attribute.regexPattern &&
    v$.value.editedValue.regexValidation?.$invalid
  ) {
    return (
      props.attribute.regexCue ||
      t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.VALIDATIONS.INVALID_INPUT')
    );
  }

  if (isAttributeTypeNumber.value && v$.value.editedValue.required?.$invalid) {
    return t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.VALIDATIONS.INVALID_NUMBER');
  }

  return t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.VALIDATIONS.REQUIRED');
});

const getInputType = computed(() => {
  switch (props.attribute.attributeDisplayType) {
    case 'link':
      return 'url';
    case 'number':
    case 'currency':
    case 'percent':
      return 'number';
    default:
      return 'text';
  }
});

const toggleEditValue = value => {
  if (props.readOnly) return;
  isEditingValue.value =
    typeof value === 'boolean' ? value : !isEditingValue.value;
  emit('focusChange', isEditingValue.value);
  if (isEditingValue.value) {
    v$.value.$reset();
    editedValue.value = props.attribute.value || '';
  }
};

const handleInputUpdate = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid) return;

  emit('update', editedValue.value);
  toggleEditValue(false);
};

const onClickAway = () => {
  v$.value.$reset();
  toggleEditValue(false);
};
</script>

<template>
  <div class="flex items-center w-full min-w-0">
    <div
      v-if="!isEditingValue"
      class="flex items-center w-full min-h-8 min-w-0"
      :class="{ 'cursor-pointer': !readOnly }"
      @click="toggleEditValue(true)"
    >
      <a
        v-if="isAttributeTypeLink && attribute.value"
        :href="attribute.value"
        target="_blank"
        rel="noopener noreferrer"
        class="text-sm text-n-brand break-all hover:underline"
        @click.stop
      >
        {{ attribute.value }}
      </a>
      <span
        v-else
        class="text-sm text-n-slate-12 truncate"
        :class="{ 'opacity-0': !attribute.value }"
      >
        {{ displayValue || '\u00A0' }}
      </span>
    </div>

    <div
      v-else
      v-on-clickaway="onClickAway"
      class="flex flex-col w-full min-w-0"
    >
      <div class="flex items-center w-full gap-1">
        <span
          v-if="isAttributeTypeCurrency"
          class="text-sm text-n-slate-11 shrink-0"
        >
          {{ currencyPrefix }}
        </span>
        <input
          v-model="editedValue"
          :type="getInputType"
          class="!mb-0 !h-8 !border-0 !shadow-none !outline-none !bg-transparent !px-0 !text-sm w-full"
          autofocus
          @keyup.enter="handleInputUpdate"
        />
        <span
          v-if="isAttributeTypePercent"
          class="text-sm text-n-slate-11 shrink-0"
        >
          {{ percentSuffix }}
        </span>
        <Button
          icon="i-lucide-check"
          :color="hasError ? 'ruby' : 'blue'"
          size="sm"
          class="flex-shrink-0"
          @click="handleInputUpdate"
        />
      </div>
      <span v-if="hasError" class="text-xs text-n-ruby-11 mt-0.5">
        {{ attributeErrorMessage }}
      </span>
    </div>
  </div>
</template>
