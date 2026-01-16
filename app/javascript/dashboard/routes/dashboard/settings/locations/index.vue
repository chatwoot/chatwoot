<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';

import AddLocation from './AddLocation.vue';
import EditLocation from './EditLocation.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const loading = ref({});
const showAddPopup = ref(false);
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const selectedLocation = ref({});

const records = computed(() => getters['locations/getLocations'].value);
const uiFlags = computed(() => getters['locations/getUIFlags'].value);

const deleteMessage = computed(() => ` ${selectedLocation.value.name}?`);

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = location => {
  showEditPopup.value = true;
  selectedLocation.value = location;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = location => {
  showDeleteConfirmationPopup.value = true;
  selectedLocation.value = location;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteLocation = async id => {
  try {
    await store.dispatch('locations/delete', id);
    useAlert(t('LOCATIONS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('LOCATIONS.DELETE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  } finally {
    loading.value[selectedLocation.value.id] = false;
  }
};

const confirmDeletion = () => {
  loading.value[selectedLocation.value.id] = true;
  closeDeletePopup();
  deleteLocation(selectedLocation.value.id);
};

const tableHeaders = computed(() => {
  return [
    t('LOCATIONS.LIST.TABLE_HEADER.NAME'),
    t('LOCATIONS.LIST.TABLE_HEADER.TYPE'),
    t('LOCATIONS.LIST.TABLE_HEADER.CITY'),
    t('LOCATIONS.LIST.TABLE_HEADER.PARENT'),
  ];
});

onBeforeMount(() => {
  store.dispatch('locations/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('LOCATIONS.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="$t('LOCATIONS.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('LOCATIONS.HEADER')"
        :description="$t('LOCATIONS.DESCRIPTION')"
        :link-text="$t('LOCATIONS.LEARN_MORE')"
        feature-name="locations"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('LOCATIONS.HEADER_BTN_TXT')"
            @click="openAddPopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <table class="min-w-full overflow-x-auto divide-y divide-n-weak">
        <thead>
          <th
            v-for="thHeader in tableHeaders"
            :key="thHeader"
            class="py-4 font-semibold text-left ltr:pr-4 rtl:pl-4 text-n-slate-11"
          >
            {{ thHeader }}
          </th>
        </thead>
        <tbody class="flex-1 divide-y divide-n-weak text-n-slate-12">
          <tr v-for="location in records" :key="location.id">
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <div class="flex flex-col">
                <span class="mb-1 font-medium break-words text-n-slate-12">
                  {{ location.name }}
                </span>

                <span class="mb-1 font-medium break-words text-n-slate-11">
                  {{ location.description }}
                </span>
              </div>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <span
                v-if="location.type_name"
                class="px-2 py-0.5 text-xs rounded-full bg-n-solid-3 text-n-slate-11"
              >
                {{ location.type_name }}
              </span>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <div v-if="location.address" class="flex flex-col">
                <span class="text-sm text-n-slate-12">
                  {{ location.address.city }}
                </span>
                <span class="text-xs text-n-slate-11">
                  {{ location.address.state }}
                </span>
              </div>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <span v-if="location.parent_location" class="text-sm text-n-slate-11">
                {{ location.parent_location.name }}
              </span>
              <span v-else class="text-xs text-n-slate-10">
                {{ $t('LOCATIONS.LIST.ROOT_LOCATION') }}
              </span>
            </td>
            <td class="py-4 min-w-xs">
              <div class="flex gap-1 justify-end">
                <Button
                  v-tooltip.top="$t('LOCATIONS.FORM.EDIT')"
                  icon="i-lucide-pen"
                  slate
                  xs
                  faded
                  :is-loading="loading[location.id]"
                  @click="openEditPopup(location)"
                />
                <Button
                  v-tooltip.top="$t('LOCATIONS.FORM.DELETE')"
                  icon="i-lucide-trash-2"
                  xs
                  ruby
                  faded
                  :is-loading="loading[location.id]"
                  @click="openDeletePopup(location)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </template>

    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddLocation @close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditLocation :selected-location="selectedLocation" @close="hideEditPopup" />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('LOCATIONS.DELETE.CONFIRM.TITLE')"
      :message="$t('LOCATIONS.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('LOCATIONS.DELETE.CONFIRM.YES')"
      :reject-text="$t('LOCATIONS.DELETE.CONFIRM.NO')"
    />
  </SettingsLayout>
</template>
