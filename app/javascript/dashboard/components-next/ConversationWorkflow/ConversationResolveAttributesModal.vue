<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import TextArea from 'next/textarea/TextArea.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ChoiceToggle from 'dashboard/components-next/input/ChoiceToggle.vue';

const { t } = useI18n();

const dialogRef = ref(null);

const attributes = [
  {
    id: 1,
    attribute_display_name: 'Severity',
    attribute_display_type: 'text',
    attribute_key: 'severity',
  },
  {
    id: 3,
    attribute_display_name: 'Cloud customer',
    attribute_display_type: 'checkbox',
    attribute_key: 'cloud_customer',
  },
  {
    id: 4,
    attribute_display_name: 'Plan',
    attribute_display_type: 'list',
    attribute_key: 'plan',
    attribute_values: ['gold', 'silver', 'bronze'],
  },
  {
    id: 5,
    attribute_display_name: 'Signup date',
    attribute_display_type: 'date',
    attribute_key: 'signup_date',
  },
  {
    id: 6,
    attribute_display_name: 'Home page',
    attribute_display_type: 'link',
    attribute_key: 'home_page',
  },
  {
    id: 7,
    attribute_display_name: 'Reg number',
    attribute_display_type: 'number',
    attribute_key: 'reg_number',
  },
].map(attribute => ({
  ...attribute,
  value: attribute.attribute_key,
  label: attribute.attribute_display_name,
  type: attribute.attribute_display_type,
}));

const formValues = ref({});

const resetForm = () => {
  formValues.value = attributes.reduce((acc, attribute) => {
    acc[attribute.value] = '';
    return acc;
  }, {});
};

const open = () => {
  resetForm();
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

const handleConfirm = () => {
  close();
};

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
    @confirm="handleConfirm"
  >
    <div class="flex flex-col gap-4">
      <div
        v-for="attribute in attributes"
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
            :options="
              (attribute.attribute_values || []).map(option => ({
                value: option,
                label: option,
              }))
            "
            :placeholder="getPlaceholder('list')"
            class="w-full"
          />
        </template>

        <template v-else-if="attribute.type === 'checkbox'">
          <ChoiceToggle
            v-model="formValues[attribute.value]"
            :yes-label="
              t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.CHECKBOX.YES')
            "
            :no-label="
              t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.MODAL.CHECKBOX.NO')
            "
          />
        </template>
      </div>
    </div>
  </Dialog>
</template>
