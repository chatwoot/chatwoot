<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useFunctionGetter, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Spinner from 'shared/components/Spinner.vue';
import integrationAPI from 'dashboard/api/integrations';

const props = defineProps({
  error: {
    type: String,
    default: '',
  },
});

const store = useStore();
const integrationLoaded = ref(false);
const dialogRef = ref(null);
const accessToken = ref('');
const isSubmitting = ref(false);
const showAccessTokenDialog = ref(false);

const integration = useFunctionGetter('integrations/getIntegration', 'hubspot');
const uiFlags = useMapGetter('integrations/getUIFlags');

const integrationAction = computed(() => {
  if (integration.value?.enabled) {
    return 'disconnect';
  }
  return integration.value?.action;
});

const initializeHubspotIntegration = async () => {
  await store.dispatch('integrations/get', 'hubspot');
  integrationLoaded.value = true;
};

const openAccessTokenDialog = () => {
  showAccessTokenDialog.value = true;
  if (dialogRef.value) {
    dialogRef.value.open();
  }
};

const closeAccessTokenDialog = () => {
  showAccessTokenDialog.value = false;
  if (dialogRef.value) {
    dialogRef.value.close();
  }
  accessToken.value = '';
  isSubmitting.value = false;
};

const handleConnect = async () => {
  if (!accessToken.value.trim()) {
    useAlert('Please enter your HubSpot private app access token');
    return;
  }
  try {
    isSubmitting.value = true;
    await integrationAPI.connectHubspot({ accessToken: accessToken.value });
    await store.dispatch('integrations/get', 'hubspot');
    useAlert('HubSpot connected successfully');
    closeAccessTokenDialog();
  } catch (error) {
    useAlert(error.message || 'Failed to connect HubSpot');
  } finally {
    isSubmitting.value = false;
  }
};

const handleDisconnect = async () => {
  try {
    isSubmitting.value = true;
    await integrationAPI.disconnectHubspot();
    await store.dispatch('integrations/get', 'hubspot');
    useAlert('HubSpot disconnected successfully');
  } catch (error) {
    useAlert(error.message || 'Failed to disconnect HubSpot');
  } finally {
    isSubmitting.value = false;
  }
};

onMounted(() => {
  initializeHubspotIntegration();
});
</script>

<template>
  <div class="flex-grow flex-shrink p-4 overflow-auto max-w-6xl mx-auto">
    <div v-if="integrationLoaded && !uiFlags.isCreatingHubspot">
      <base-settings-header
        :header-title="'INTEGRATION_SETTINGS.HEADER'"
        :show-back-button="true"
        :back-url="{ name: 'settings_applications' }"
      />
      <div class="row">
        <div class="columns large-8">
          <div class="panel">
            <div class="panel__header">
              <h3 class="panel__title">HubSpot Integration</h3>
            </div>
            <div class="panel__content">
              <p class="text-muted">
                Connect your HubSpot account to sync conversations and contacts.
              </p>
              <div class="mb-4">
                <h4 class="text-lg font-medium mb-2">How to connect:</h4>
                <ol class="list-decimal list-inside space-y-2 text-sm text-muted">
                  <li>Go to your HubSpot account settings</li>
                  <li>Navigate to Integrations > Private Apps</li>
                  <li>Click "Create a private app"</li>
                  <li>Give your app a name (e.g., "DashAssist Integration")</li>
                  <li>Select the following scopes:
                    <ul class="list-disc list-inside ml-4 mt-1">
                      <li>crm.objects.contacts.write</li>
                      <li>crm.objects.contacts.read</li>
                      <li>crm.schemas.contacts.read</li>
                    </ul>
                  </li>
                  <li>Click "Create app"</li>
                  <li>Copy the access token</li>
                </ol>
              </div>
              <next-button
                v-if="!integration?.hooks?.length"
                :loading="isSubmitting"
                @click="openAccessTokenDialog"
              >
                Connect HubSpot
              </next-button>
              <div v-else>
                <p class="text-success">HubSpot is connected</p>
                <next-button
                  :loading="isSubmitting"
                  variant="danger"
                  @click="handleDisconnect"
                >
                  Disconnect HubSpot
                </next-button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <Dialog
        ref="dialogRef"
        title="Connect HubSpot"
        @close="closeAccessTokenDialog"
      >
        <template #default>
          <div class="p-4">
            <p class="text-muted mb-4">
              Please enter your HubSpot private app access token to connect your account.
            </p>
            <Input
              v-model="accessToken"
              type="password"
              placeholder="Enter your HubSpot private app access token"
              class="w-full"
            />
          </div>
        </template>
        <template #footer>
          <div class="flex justify-end gap-2">
            <NextButton
              variant="secondary"
              :loading="false"
              @click="closeAccessTokenDialog"
            >
              Cancel
            </NextButton>
            <NextButton
              :loading="isSubmitting"
              @click="handleConnect"
            >
              Connect
            </NextButton>
          </div>
        </template>
      </Dialog>
    </div>
    <div v-else class="flex items-center justify-center flex-1">
      <Spinner size="" color-scheme="primary" />
    </div>
  </div>
</template> 