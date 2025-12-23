<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import TextArea from 'next/textarea/TextArea.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ChoiceToggle from 'dashboard/components-next/input/ChoiceToggle.vue';

const emit = defineEmits(['submit']);

const { t } = useI18n();

const dialogRef = ref(null);
const visibleAttributes = ref([]);
const formValues = ref({});
const conversationContext = ref(null);

const getPlaceholder = type => {
  const placeholders = {
    text: t(
      'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.TEXT'
    ),
    number: t(
      'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.NUMBER'
    ),
    link: t(
      'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.LINK'
    ),
    date: t(
      'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.DATE'
    ),
    list: t(
      'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.PLACEHOLDERS.LIST'
    ),
  };

  return placeholders[type] || '';
};

const isFormComplete = computed(() =>
  visibleAttributes.value.every(attribute => {
    const value = formValues.value?.[attribute.value];

    // For checkbox attributes, only check if the key exists (matches composable logic)
    if (attribute.type === 'checkbox') {
      return attribute.value in formValues.value;
    }

    // For other attribute types, check for valid non-empty values
    return value !== undefined && value !== null && String(value).trim() !== '';
  })
);

const comboBoxOptions = computed(() => {
  const options = {};
  visibleAttributes.value.forEach(attribute => {
    if (attribute.type === 'list') {
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
};

const open = (attributes = [], initialValues = {}, context = null) => {
  visibleAttributes.value = attributes;
  conversationContext.value = context;
  formValues.value = attributes.reduce((acc, attribute) => {
    const presetValue = initialValues[attribute.value];
    if (presetValue !== undefined && presetValue !== null) {
      acc[attribute.value] = presetValue;
    } else {
      // For checkbox attributes, initialize to null to avoid pre-selection
      // For other attributes, initialize to empty string
      acc[attribute.value] = attribute.type === 'checkbox' ? null : '';
    }
    return acc;
  }, {});
  dialogRef.value?.open();
};

const handleConfirm = () => {
  emit('submit', {
    attributes: { ...formValues.value },
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
          <label class="text-sm font-medium text-n-slate-12">
            {{ attribute.label }}
          </label>
        </div>

        <template v-if="attribute.type === 'text'">
          <TextArea
            v-model="formValues[attribute.value]"
            class="w-full"
            :placeholder="getPlaceholder('text')"
          />
        </template>

        <template v-else-if="attribute.type === 'number'">
          <Input
            v-model="formValues[attribute.value]"
            type="number"
            size="md"
            :placeholder="getPlaceholder('number')"
          />
        </template>

        <template v-else-if="attribute.type === 'link'">
          <Input
            v-model="formValues[attribute.value]"
            type="url"
            size="md"
            :placeholder="getPlaceholder('link')"
          />
        </template>

        <template v-else-if="attribute.type === 'date'">
          <Input
            v-model="formValues[attribute.value]"
            type="date"
            size="md"
            :placeholder="getPlaceholder('date')"
          />
        </template>

        <template v-else-if="attribute.type === 'list'">
          <ComboBox
            v-model="formValues[attribute.value]"
            :options="comboBoxOptions[attribute.value]"
            :placeholder="getPlaceholder('list')"
            class="w-full"
          />
        </template>

        <template v-else-if="attribute.type === 'checkbox'">
          <ChoiceToggle v-model="formValues[attribute.value]" />
        </template>
      </div>
    </div>
  </Dialog>
</template>
