<script setup>
import { ref, computed, onMounted } from 'vue';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import Integration from './Integration.vue';

import Input from 'dashboard/components-next/input/Input.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const store = useStore();
const { t } = useI18n();

const dialogRef = ref(null);
const integrationLoaded = ref(false);
const isSubmitting = ref(false);
const isEditing = ref(false);

const apiUrl = ref('');
const apiKey = ref('');
const apiUrlError = ref('');
const apiKeyError = ref('');

const integration = useFunctionGetter('integrations/getIntegration', 'viari');
const uiFlags = useMapGetter('integrations/getUIFlags');

const isConnected = computed(() => Boolean(integration.value?.hooks?.length));

const integrationAction = computed(() =>
  isConnected.value ? 'disconnect' : 'connect'
);

const openDialog = (editing = false) => {
  isEditing.value = editing;
  apiUrlError.value = '';
  apiKeyError.value = '';
  if (editing && integration.value?.hooks?.[0]) {
    const hook = integration.value.hooks[0];
    apiUrl.value = hook.settings?.api_url ?? '';
    apiKey.value = hook.settings?.api_key ?? '';
  } else {
    apiUrl.value = '';
    apiKey.value = '';
  }
  if (dialogRef.value) {
    dialogRef.value.open();
  }
};

const closeDialog = () => {
  apiUrl.value = '';
  apiKey.value = '';
  apiUrlError.value = '';
  apiKeyError.value = '';
  isSubmitting.value = false;
};

const validateForm = () => {
  let valid = true;
  if (!apiUrl.value.startsWith('http')) {
    apiUrlError.value = t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_URL_HELP');
    valid = false;
  }
  if (apiKey.value.length < 10) {
    apiKeyError.value = t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_KEY_HELP');
    valid = false;
  }
  return valid;
};

const handleSubmit = async () => {
  if (!validateForm()) return;
  isSubmitting.value = true;
  try {
    if (isEditing.value && integration.value?.hooks?.[0]) {
      const hook = integration.value.hooks[0];
      await store.dispatch('integrations/deleteHook', {
        appId: 'viari',
        hookId: hook.id,
      });
    }
    await store.dispatch('integrations/createHook', {
      app_id: 'viari',
      settings: { api_url: apiUrl.value, api_key: apiKey.value },
    });
    if (dialogRef.value) {
      dialogRef.value.close();
    }
  } catch {
    apiUrlError.value = t('INTEGRATION_SETTINGS.VIARI.ERROR');
  } finally {
    isSubmitting.value = false;
  }
};

onMounted(async () => {
  await store.dispatch('integrations/get', 'viari');
  integrationLoaded.value = true;
});
</script>

<template>
  <SettingsLayout
    :is-loading="
      !integrationLoaded || uiFlags.isCreatingHook || uiFlags.isDeletingHook
    "
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('INTEGRATION_SETTINGS.VIARI.HEADER')"
        description=""
        :back-button-label="t('INTEGRATION_SETTINGS.HEADER')"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-6">
        <Integration
          integration-id="viari"
          :integration-name="integration.name"
          :integration-description="integration.description"
          :integration-enabled="isConnected"
          :integration-action="integrationAction"
          :delete-confirmation-text="{
            title: t('INTEGRATION_SETTINGS.VIARI.DELETE.TITLE'),
            message: t('INTEGRATION_SETTINGS.VIARI.DELETE.MESSAGE'),
          }"
        >
          <template #action>
            <div class="flex gap-2">
              <Button
                v-if="isConnected"
                ghost
                :label="t('INTEGRATION_SETTINGS.VIARI.UPDATE.SUBMIT')"
                @click="openDialog(true)"
              />
              <Button
                v-else
                teal
                :label="t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT')"
                @click="openDialog(false)"
              />
            </div>
          </template>
        </Integration>

        <Dialog
          ref="dialogRef"
          :title="
            isEditing
              ? t('INTEGRATION_SETTINGS.VIARI.UPDATE.TITLE')
              : t('INTEGRATION_SETTINGS.VIARI.CONNECT.TITLE')
          "
          :is-loading="isSubmitting"
          @confirm="handleSubmit"
          @close="closeDialog"
        >
          <div class="flex flex-col gap-4">
            <Input
              v-model="apiUrl"
              type="url"
              :label="t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_URL_LABEL')"
              :placeholder="
                t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_URL_PLACEHOLDER')
              "
              :message="
                apiUrlError ||
                t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_URL_HELP')
              "
              :message-type="apiUrlError ? 'error' : 'info'"
            />
            <Input
              v-model="apiKey"
              type="password"
              :label="t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_KEY_LABEL')"
              :placeholder="
                t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_KEY_PLACEHOLDER')
              "
              :message="
                apiKeyError ||
                t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_KEY_HELP')
              "
              :message-type="apiKeyError ? 'error' : 'info'"
            />
          </div>
        </Dialog>
      </div>
    </template>
  </SettingsLayout>
</template>
