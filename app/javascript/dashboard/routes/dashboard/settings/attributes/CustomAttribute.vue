<script setup>
import { useAlert } from 'dashboard/composables';
import EditAttribute from './EditAttribute.vue';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  attributeModel: {
    type: String,
    default: 'conversation_attribute',
  },
});

const { t } = useI18n();

const showEditPopup = ref(false);
const showDeletePopup = ref(false);
const selectedAttribute = ref({});

const getters = useStoreGetters();
const store = useStore();

const attributes = computed(() =>
  getters['attributes/getAttributesByModel'].value(props.attributeModel)
);
const uiFlags = computed(() => getters['attributes/getUIFlags'].value);

const attributeDisplayName = computed(
  () => selectedAttribute.value.attribute_display_name
);
const deleteConfirmText = computed(
  () =>
    `${t('ATTRIBUTES_MGMT.DELETE.CONFIRM.YES')} ${attributeDisplayName.value}`
);
const deleteRejectText = computed(() => t('ATTRIBUTES_MGMT.DELETE.CONFIRM.NO'));
const confirmDeleteTitle = computed(() =>
  t('ATTRIBUTES_MGMT.DELETE.CONFIRM.TITLE', {
    attributeName: attributeDisplayName.value,
  })
);
const confirmPlaceHolderText = computed(
  () =>
    `${t('ATTRIBUTES_MGMT.DELETE.CONFIRM.PLACE_HOLDER', {
      attributeName: attributeDisplayName.value,
    })}`
);

const deleteAttributes = async ({ id }) => {
  try {
    await store.dispatch('attributes/delete', id);
    useAlert(t('ATTRIBUTES_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.response?.message || t('ATTRIBUTES_MGMT.DELETE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};
const openEditPopup = response => {
  showEditPopup.value = true;
  selectedAttribute.value = response;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const closeDelete = () => {
  showDeletePopup.value = false;
  selectedAttribute.value = {};
};
const confirmDeletion = () => {
  deleteAttributes(selectedAttribute.value);
  closeDelete();
};
const openDelete = value => {
  showDeletePopup.value = true;
  selectedAttribute.value = value;
};

const tableHeaders = computed(() => {
  return [
    t('ATTRIBUTES_MGMT.LIST.TABLE_HEADER.NAME'),
    t('ATTRIBUTES_MGMT.LIST.TABLE_HEADER.DESCRIPTION'),
    t('ATTRIBUTES_MGMT.LIST.TABLE_HEADER.TYPE'),
    t('ATTRIBUTES_MGMT.LIST.TABLE_HEADER.KEY'),
  ];
});
</script>

<template>
  <div class="flex flex-col">
    <table class="min-w-full overflow-x-auto">
      <thead>
        <th
          v-for="tableHeader in tableHeaders"
          :key="tableHeader"
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ tableHeader }}
        </th>
      </thead>
      <tbody
        class="divide-y divide-slate-25 dark:divide-slate-800 flex-1 text-slate-700 dark:text-slate-100"
      >
        <tr v-for="attribute in attributes" :key="attribute.attribute_key">
          <td
            class="py-4 ltr:pr-4 rtl:pl-4 overflow-hidden whitespace-nowrap text-ellipsis"
          >
            {{ attribute.attribute_display_name }}
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4">
            {{ attribute.attribute_description }}
          </td>
          <td
            class="py-4 ltr:pr-4 rtl:pl-4 overflow-hidden whitespace-nowrap text-ellipsis"
          >
            {{ attribute.attribute_display_type }}
          </td>
          <td
            class="py-4 ltr:pr-4 rtl:pl-4 attribute-key overflow-hidden whitespace-nowrap text-ellipsis"
          >
            {{ attribute.attribute_key }}
          </td>
          <td class="py-4 min-w-xs">
            <div class="flex gap-1 justify-end">
              <Button
                v-tooltip.top="$t('ATTRIBUTES_MGMT.LIST.BUTTONS.EDIT')"
                icon="i-lucide-pen"
                slate
                xs
                faded
                @click="openEditPopup(attribute)"
              />
              <Button
                v-tooltip.top="$t('ATTRIBUTES_MGMT.LIST.BUTTONS.DELETE')"
                icon="i-lucide-trash-2"
                xs
                ruby
                faded
                @click="openDelete(attribute)"
              />
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditAttribute
        :selected-attribute="selectedAttribute"
        :is-updating="uiFlags.isUpdating"
        @on-close="hideEditPopup"
      />
    </woot-modal>
    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="confirmDeleteTitle"
      :message="$t('ATTRIBUTES_MGMT.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedAttribute.attribute_display_name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      @on-confirm="confirmDeletion"
      @on-close="closeDelete"
    />
  </div>
</template>

<style lang="scss" scoped>
.attribute-key {
  font-family: monospace;
}
</style>
