<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import ListAttribute from 'dashboard/components-next/CustomAttributes/ListAttribute.vue';
import CheckboxAttribute from 'dashboard/components-next/CustomAttributes/CheckboxAttribute.vue';
import DateAttribute from 'dashboard/components-next/CustomAttributes/DateAttribute.vue';
import OtherAttribute from 'dashboard/components-next/CustomAttributes/OtherAttribute.vue';

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

const store = useStore();
const { t } = useI18n();
const route = useRoute();

const handleDelete = async () => {
  try {
    await store.dispatch('contacts/deleteCustomAttributes', {
      id: route.params.contactId,
      customAttributes: [props.attribute.attributeKey],
    });
    useAlert(
      t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.API.DELETE_SUCCESS_MESSAGE')
    );
  } catch (error) {
    useAlert(
      error?.response?.message ||
        t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.API.DELETE_ERROR')
    );
  }
};

const handleUpdate = async value => {
  try {
    await store.dispatch('contacts/update', {
      id: route.params.contactId,
      customAttributes: {
        [props.attribute.attributeKey]: value,
      },
    });
    useAlert(t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error?.response?.message ||
        t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.API.UPDATE_ERROR')
    );
  }
};

const componentMap = {
  list: ListAttribute,
  checkbox: CheckboxAttribute,
  date: DateAttribute,
  default: OtherAttribute,
};

const CurrentAttributeComponent = computed(() => {
  return (
    componentMap[props.attribute.attributeDisplayType] || componentMap.default
  );
});
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
