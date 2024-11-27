<!-- Attribute type "Text, URL, Number" -->
<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { isValidURL } from 'dashboard/helper/URLHelper.js';
import { getRegexp } from 'shared/helpers/Validators';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  attribute: {
    type: Object,
    required: true,
  },
  isEditingView: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update', 'delete']);

const { t } = useI18n();
const isEditingValue = ref(false);
const editedValue = ref(props.attribute.value || '');

const isAttributeTypeLink = computed(
  () => props.attribute.attributeDisplayType === 'link'
);

const isAttributeTypeText = computed(
  () => props.attribute.attributeDisplayType === 'text'
);

const isAttributeTypeNumber = computed(
  () => props.attribute.attributeDisplayType === 'number'
);

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
          return getRegexp(props.attribute.regexPattern).test(value);
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
      return 'number';
    default:
      return 'text';
  }
});

const toggleEditValue = value => {
  isEditingValue.value =
    typeof value === 'boolean' ? value : !isEditingValue.value;
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
</script>

<template>
  <div
    class="flex items-center w-full min-w-0 gap-2"
    :class="{
      'justify-start': isEditingView,
      'justify-end': !isEditingView,
    }"
  >
    <span
      v-if="!isEditingValue"
      class="min-w-0 text-sm"
      :class="{
        'cursor-pointer text-n-slate-11 hover:text-n-slate-12 py-2 select-none font-medium':
          !isEditingView,
        'text-n-slate-12 truncate flex-1':
          isEditingView && !isAttributeTypeLink,
        'truncate flex-1 hover:text-n-brand text-n-blue-text':
          isEditingView && isAttributeTypeLink,
      }"
      @click="toggleEditValue(!isEditingView)"
    >
      <a
        v-if="isAttributeTypeLink && attribute.value && isEditingView"
        :href="attribute.value"
        target="_blank"
        rel="noopener noreferrer"
        class="hover:underline"
        @click.stop
      >
        {{ attribute.value }}
      </a>
      <template v-else>
        {{
          attribute.value ||
          t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.TRIGGER.INPUT')
        }}
      </template>
    </span>

    <div
      v-if="isEditingView && !isEditingValue"
      class="flex items-center gap-1"
    >
      <Button
        variant="faded"
        color="slate"
        icon="i-lucide-pencil"
        size="xs"
        class="flex-shrink-0 opacity-0 group-hover/attribute:opacity-100 hover:no-underline"
        @click="toggleEditValue(true)"
      />
      <Button
        variant="faded"
        color="ruby"
        icon="i-lucide-trash"
        size="xs"
        class="flex-shrink-0 opacity-0 group-hover/attribute:opacity-100 hover:no-underline"
        @click="emit('delete')"
      />
    </div>

    <div
      v-if="isEditingValue"
      v-on-clickaway="() => toggleEditValue(false)"
      class="flex items-center w-full"
    >
      <Input
        v-model="editedValue"
        :placeholder="t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.TRIGGER.INPUT')"
        :type="getInputType"
        class="w-full [&>p]:absolute [&>p]:mt-0.5 [&>p]:top-8 ltr:[&>p]:left-0 rtl:[&>p]:right-0"
        autofocus
        :message="attributeErrorMessage"
        :message-type="hasError ? 'error' : 'info'"
        custom-input-class="h-8 ltr:rounded-r-none rtl:rounded-l-none"
        @keyup.enter="handleInputUpdate"
      />
      <Button
        icon="i-lucide-check"
        :color="hasError ? 'ruby' : 'blue'"
        size="sm"
        class="flex-shrink-0 ltr:rounded-l-none rtl:rounded-r-none"
        @click="handleInputUpdate"
      />
    </div>
  </div>
</template>
