<script setup>
import { computed, ref, watch } from 'vue';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => [],
  },
  primaryPlaceholder: {
    type: String,
    default: '',
  },
  additionalPlaceholder: {
    type: String,
    default: '',
  },
  isDetailsView: {
    type: Boolean,
    default: false,
  },
  message: {
    type: String,
    default: '',
  },
  messageType: {
    type: String,
    default: 'info',
  },
});

const emit = defineEmits(['update:modelValue', 'input', 'blur']);

const normalizeEmails = emails => [
  ...new Set(emails.map(email => email?.trim()).filter(Boolean)),
];

const getEmailFields = emails => {
  const normalizedEmails = normalizeEmails(emails);
  return normalizedEmails.length ? normalizedEmails : [''];
};

const emailFields = ref(getEmailFields(props.modelValue));

const inputClass = computed(
  () =>
    `h-8 !pt-1 !pb-1 ${
      !props.isDetailsView ? '[&:not(.error,.focus)]:!outline-transparent' : ''
    }`
);

const syncFieldsFromModel = emails => {
  const modelFields = getEmailFields(emails);
  const normalizedModel = JSON.stringify(modelFields);
  const normalizedFields = JSON.stringify(emailFields.value);

  if (normalizedModel !== normalizedFields) {
    emailFields.value = modelFields;
  }
};

const emitUpdatedEmails = () => {
  emit('update:modelValue', normalizeEmails(emailFields.value));
};

const updateEmail = (index, value) => {
  emailFields.value[index] = value;
  emitUpdatedEmails();

  if (index === 0) {
    emit('input');
  }
};

const addEmailField = () => {
  emailFields.value.push('');
};

const removeEmailField = index => {
  emailFields.value.splice(index, 1);
  emitUpdatedEmails();
};

watch(
  () => props.modelValue,
  emails => syncFieldsFromModel(emails),
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-2">
    <div
      v-for="(email, index) in emailFields"
      :key="index"
      class="flex items-start gap-2"
    >
      <Input
        :model-value="email"
        type="email"
        :placeholder="index === 0 ? primaryPlaceholder : additionalPlaceholder"
        :message="index === 0 ? message : ''"
        :message-type="messageType"
        :custom-input-class="inputClass"
        class="flex-1"
        @update:model-value="value => updateEmail(index, value)"
        @blur="index === 0 && emit('blur')"
      />
      <Button
        v-if="index > 0"
        icon="i-lucide-trash-2"
        variant="ghost"
        color="slate"
        size="sm"
        class="mt-1"
        @click="removeEmailField(index)"
      />
    </div>
    <Button
      icon="i-lucide-plus"
      variant="link"
      color="slate"
      size="sm"
      class="self-start"
      :label="
        $t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM.EMAIL_ADDRESS.ADD')
      "
      @click="addEmailField"
    />
  </div>
</template>
