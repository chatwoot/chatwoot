<script setup>
import { computed, onActivated, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useBranding } from 'shared/composables/useBranding';
import SdkAppsAPI from 'dashboard/api/sdkApps';
import InboxesAPI from 'dashboard/api/inboxes';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import SettingsLayout from '../../SettingsLayout.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const { t } = useI18n();
const { replaceInstallationName } = useBranding();
const route = useRoute();
const router = useRouter();
const apps = ref([]);
const inboxes = ref([]);
const searchQuery = ref('');
const loading = ref(true);
const busy = ref(false);
const error = ref('');
const selectedApp = ref(null);
const deleteDialog = ref(null);
const filteredApps = computed(() =>
  apps.value.filter(app =>
    app.name.toLowerCase().includes(searchQuery.value.trim().toLowerCase())
  )
);
const headers = computed(() => [
  t('INBOX_MGMT.SDK_APPS.APP'),
  t('INBOX_MGMT.SDK_APPS.ACTIONS'),
]);

async function load() {
  loading.value = true;
  error.value = '';
  try {
    const [appResponse, inboxResponse] = await Promise.all([
      SdkAppsAPI.get(),
      InboxesAPI.get(),
    ]);
    apps.value = appResponse.data;
    inboxes.value = inboxResponse.data.payload;
  } catch (exception) {
    error.value =
      exception.response?.data?.error || t('INBOX_MGMT.SDK_APPS.ERROR');
  } finally {
    loading.value = false;
  }
}
function openApp(app) {
  router.push({
    name: app
      ? 'settings_integrations_sdk_details'
      : 'settings_integrations_sdk_new',
    params: {
      accountId: route.params.accountId,
      ...(app ? { sdkAppId: app.id } : {}),
    },
  });
}
function confirmRemoval(app) {
  selectedApp.value = app;
  deleteDialog.value.open();
}
async function remove() {
  busy.value = true;
  error.value = '';
  try {
    await SdkAppsAPI.delete(selectedApp.value.id);
    deleteDialog.value.close();
    await load();
  } catch (exception) {
    error.value =
      exception.response?.data?.error || t('INBOX_MGMT.SDK_APPS.ERROR');
    deleteDialog.value.close();
  } finally {
    busy.value = false;
  }
}
onActivated(load);
</script>

<template>
  <SettingsLayout
    :is-loading="loading"
    :loading-message="t('INBOX_MGMT.SDK_APPS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="t('INBOX_MGMT.SDK_APPS.TITLE')"
        :description="
          replaceInstallationName(t('INBOX_MGMT.SDK_APPS.DESCRIPTION'))
        "
        :back-button-label="t('INTEGRATION_SETTINGS.HEADER')"
        :search-placeholder="t('INBOX_MGMT.SDK_APPS.SEARCH')"
      >
        <template #actions>
          <Button :label="t('INBOX_MGMT.SDK_APPS.ADD')" @click="openApp()" />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <p v-if="error" role="alert" class="mb-4 text-n-ruby-9">{{ error }}</p>
      <BaseTable
        :headers="headers"
        :items="filteredApps"
        :no-data-message="
          searchQuery
            ? t('INBOX_MGMT.SDK_APPS.NO_RESULTS')
            : t('INBOX_MGMT.SDK_APPS.EMPTY')
        "
      >
        <template #row>
          <BaseTableRow v-for="app in filteredApps" :key="app.id" :item="app">
            <BaseTableCell>
              <div class="flex gap-2 font-medium break-words text-n-slate-12">
                {{ app.name }}
              </div>
              <div class="block mt-1 text-sm text-n-slate-11">
                {{
                  t('INBOX_MGMT.SDK_APPS.CONNECTED_TO', {
                    inbox: inboxes.find(inbox => inbox.id === app.inbox_id)
                      ?.name,
                  })
                }}
              </div>
            </BaseTableCell>
            <BaseTableCell align="end" class="w-24">
              <div class="flex justify-end gap-3 flex-shrink-0">
                <Button
                  v-tooltip.top="t('INBOX_MGMT.SDK_APPS.SETTINGS')"
                  :aria-label="t('INBOX_MGMT.SDK_APPS.SETTINGS')"
                  icon="i-woot-settings"
                  slate
                  sm
                  @click="openApp(app)"
                />
                <Button
                  v-tooltip.top="t('INBOX_MGMT.SDK_APPS.REMOVE')"
                  :aria-label="t('INBOX_MGMT.SDK_APPS.REMOVE')"
                  icon="i-woot-bin"
                  slate
                  sm
                  class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                  @click="confirmRemoval(app)"
                />
              </div>
            </BaseTableCell>
          </BaseTableRow>
        </template>
      </BaseTable>
      <Dialog
        ref="deleteDialog"
        type="alert"
        :title="
          t('INBOX_MGMT.SDK_APPS.DELETE_TITLE', { name: selectedApp?.name })
        "
        :description="t('INBOX_MGMT.SDK_APPS.REMOVE_HELP')"
        :confirm-button-label="t('INBOX_MGMT.SDK_APPS.REMOVE')"
        :is-loading="busy"
        :disable-confirm-button="busy"
        @confirm="remove"
      />
    </template>
  </SettingsLayout>
</template>
