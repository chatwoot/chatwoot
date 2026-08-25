<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useCompaniesStore } from 'dashboard/stores/companies';

import ListAttribute from 'dashboard/components-next/CustomAttributes/ListAttribute.vue';
import CheckboxAttribute from 'dashboard/components-next/CustomAttributes/CheckboxAttribute.vue';
import DateAttribute from 'dashboard/components-next/CustomAttributes/DateAttribute.vue';
import OtherAttribute from 'dashboard/components-next/CustomAttributes/OtherAttribute.vue';

const props = defineProps({
  companyId: {
    type: Number,
    required: true,
  },
  attribute: {
    type: Object,
    required: true,
  },
  isEditingView: {
    type: Boolean,
    default: false,
  },
});

const companiesStore = useCompaniesStore();
const { t } = useI18n();

const handleDelete = async () => {
  try {
    await companiesStore.deleteCustomAttributes({
      id: props.companyId,
      customAttributes: [props.attribute.attributeKey],
    });
    useAlert(t('COMPANIES.DETAIL.ATTRIBUTES.MESSAGES.DELETE_SUCCESS'));
  } catch (error) {
    useAlert(
      error?.response?.message ||
        t('COMPANIES.DETAIL.ATTRIBUTES.MESSAGES.DELETE_ERROR')
    );
  }
};

const handleUpdate = async value => {
  try {
    await companiesStore.update({
      id: props.companyId,
      customAttributes: {
        [props.attribute.attributeKey]: value,
      },
    });
    useAlert(t('COMPANIES.DETAIL.ATTRIBUTES.MESSAGES.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(
      error?.response?.message ||
        t('COMPANIES.DETAIL.ATTRIBUTES.MESSAGES.UPDATE_ERROR')
    );
  }
};

const componentMap = {
  list: ListAttribute,
  checkbox: CheckboxAttribute,
  date: DateAttribute,
  default: OtherAttribute,
};

const CurrentAttributeComponent = computed(
  () =>
    componentMap[props.attribute.attributeDisplayType] || componentMap.default
);
</script>

<template>
  <div
    class="grid grid-cols-[140px,1fr] group/attribute items-center w-full gap-2"
    :class="isEditingView ? 'min-h-10' : 'min-h-11'"
  >
    <div class="flex items-center justify-between truncate">
      <span class="text-sm font-medium truncate text-n-slate-12">
        {{ attribute.attributeDisplayName }}
      </span>
    </div>

    <component
      :is="CurrentAttributeComponent"
      :attribute="attribute"
      :is-editing-view="isEditingView"
      @update="handleUpdate"
      @delete="handleDelete"
    />
  </div>
</template>
