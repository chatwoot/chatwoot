<script setup>
import { ref, computed, onMounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import ApplicationModal from './components/ApplicationModal.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const MODAL_TYPES = {
  CREATE: 'create',
  EDIT: 'edit',
};

const store = useStore();
const { t } = useI18n();

const applications = useMapGetter('applications/getApplications');
const uiFlags = useMapGetter('applications/getUIFlags');

const selectedApplication = ref({});
const loading = ref({});
const modalType = ref(MODAL_TYPES.CREATE);
const applicationModalRef = ref(null);
const applicationDeleteDialogRef = ref(null);

const tableHeaders = computed(() => {
  return [
    t('APPLICATIONS.LIST.TABLE_HEADER.DETAILS'),
    t('APPLICATIONS.LIST.TABLE_HEADER.URL'),
  ];
});

const selectedApplicationName = computed(
  () => selectedApplication.value?.name || ''
);

const openAddModal = () => {
  modalType.value = MODAL_TYPES.CREATE;
  selectedApplication.value = {};
  applicationModalRef.value.dialogRef.open();
};

const openEditModal = application => {
  modalType.value = MODAL_TYPES.EDIT;
  selectedApplication.value = application;
  applicationModalRef.value.dialogRef.open();
};

const openDeletePopup = application => {
  selectedApplication.value = application;
  applicationDeleteDialogRef.value.open();
};

const deleteApplication = async id => {
  try {
    await store.dispatch('applications/delete', id);
    useAlert(t('APPLICATIONS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('APPLICATIONS.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
    selectedApplication.value = {};
  }
};

const confirmDeletion = () => {
  loading.value[selectedApplication.value.id] = true;
  deleteApplication(selectedApplication.value.id);
  applicationDeleteDialogRef.value.close();
};

onMounted(() => {
  store.dispatch('applications/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="t('APPLICATIONS.LIST.LOADING')"
    :no-records-found="!applications.length"
    :no-records-message="t('APPLICATIONS.LIST.404')"
    class="p-6"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('APPLICATIONS.HEADER')"
        :description="t('APPLICATIONS.DESCRIPTION')"
        :link-text="t('APPLICATIONS.LEARN_MORE')"
        feature-name="applications"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('APPLICATIONS.ADD.TITLE')"
            @click="openAddModal"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div class="p-6">
        <table class="min-w-full overflow-x-auto divide-y divide-n-strong">
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
            <tr v-for="application in applications" :key="application.id">
              <td class="py-4 ltr:pr-4 rtl:pl-4">
                <div class="flex flex-row items-center gap-4">
                  <Avatar
                    :name="application.name"
                    :src="application.thumbnail"
                    :size="40"
                    rounded-full
                  />
                  <div>
                    <span class="block font-medium break-words">
                      {{ application.name }}
                      <span
                        v-if="application.status === 'active'"
                        class="text-xs text-n-slate-12 bg-n-green-5 inline-block rounded-md py-0.5 px-1 ltr:ml-1 rtl:mr-1"
                      >
                        {{ $t('APPLICATIONS.STATUS.ACTIVE') }}
                      </span>
                    </span>
                    <span class="text-sm text-n-slate-11">
                      {{ application.description }}
                    </span>
                  </div>
                </div>
              </td>
              <td class="py-4 ltr:pr-4 rtl:pl-4 text-sm">
                {{ application.url }}
              </td>
              <td class="py-4 min-w-xs">
                <div class="flex gap-1 justify-end">
                  <Button
                    v-tooltip.top="t('APPLICATIONS.EDIT.BUTTON_TEXT')"
                    icon="i-lucide-pen"
                    slate
                    xs
                    faded
                    :is-loading="loading[application.id]"
                    @click="openEditModal(application)"
                  />
                  <Button
                    v-tooltip.top="t('APPLICATIONS.DELETE.BUTTON_TEXT')"
                    icon="i-lucide-trash-2"
                    xs
                    ruby
                    faded
                    :is-loading="loading[application.id]"
                    @click="openDeletePopup(application)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>

    <ApplicationModal
      ref="applicationModalRef"
      :type="modalType"
      :selected-application="selectedApplication"
    />

    <Dialog
      ref="applicationDeleteDialogRef"
      type="alert"
      :title="t('APPLICATIONS.DELETE.CONFIRM.TITLE')"
      :description="
        t('APPLICATIONS.DELETE.CONFIRM.MESSAGE', {
          name: selectedApplicationName,
        })
      "
      :is-loading="uiFlags.isDeleting"
      :confirm-button-label="t('APPLICATIONS.DELETE.CONFIRM.YES')"
      :cancel-button-label="t('APPLICATIONS.DELETE.CONFIRM.NO')"
      @confirm="confirmDeletion"
    />
  </SettingsLayout>
</template>
