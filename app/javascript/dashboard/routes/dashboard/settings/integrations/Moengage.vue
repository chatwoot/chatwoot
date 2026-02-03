<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';

import Integration from './Integration.vue';
import Spinner from 'shared/components/Spinner.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import FormSelect from 'v3/components/Form/Select.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const integrationLoaded = ref(false);
const isSubmitting = ref(false);
const dialogRef = ref(null);
const disconnectDialogRef = ref(null);

const formData = ref({
  workspace_id: '',
  data_center: '01',
  default_inbox_id: null,
  auto_create_contact: true,
  enable_ai_response: false,
});

const integration = useFunctionGetter(
  'integrations/getIntegration',
  'moengage'
);
const uiFlags = useMapGetter('integrations/getUIFlags');
const inboxes = useMapGetter('inboxes/getInboxes');

const isConnected = computed(() => integration.value?.enabled);

const currentHook = computed(() => {
  const hooks = integration.value?.hooks || [];
  return hooks[0] || null;
});

const webhookUrl = computed(() => currentHook.value?.webhook_url || '');

const integrationAction = computed(() => {
  if (isConnected.value) {
    return 'disconnect';
  }
  return 'connect';
});

const dataCenterOptions = [
  { value: '01', label: 'DC-01 (US)' },
  { value: '02', label: 'DC-02 (EU)' },
  { value: '03', label: 'DC-03 (India)' },
  { value: '04', label: 'DC-04 (US Alternate)' },
  { value: '05', label: 'DC-05 (Singapore)' },
  { value: '06', label: 'DC-06 (Indonesia)' },
];

const inboxOptions = computed(() =>
  inboxes.value.map(inbox => ({
    value: String(inbox.id),
    label: inbox.name,
  }))
);

const selectedInboxId = computed({
  get: () =>
    formData.value.default_inbox_id
      ? String(formData.value.default_inbox_id)
      : '',
  set: val => {
    formData.value.default_inbox_id = val ? Number(val) : null;
  },
});

const dataCenterLabel = computed(() => {
  const option = dataCenterOptions.find(
    opt => opt.value === formData.value.data_center
  );
  return option?.label || formData.value.data_center;
});

const currentInboxName = computed(() => {
  if (!formData.value.default_inbox_id) return '-';
  const inbox = inboxes.value.find(
    i => i.id === formData.value.default_inbox_id
  );
  return inbox?.name || '-';
});

const openConnectDialog = () => {
  dialogRef.value?.open();
};

const openDisconnectDialog = () => {
  disconnectDialogRef.value?.open();
};

const handleConnect = async () => {
  if (!formData.value.workspace_id || !formData.value.default_inbox_id) {
    useAlert(t('INTEGRATION_SETTINGS.MOENGAGE.FORM.VALIDATION_ERROR'));
    return;
  }

  isSubmitting.value = true;
  try {
    await store.dispatch('integrations/createMoengage', formData.value);
    useAlert(t('INTEGRATION_SETTINGS.MOENGAGE.SAVE_SUCCESS'));
    dialogRef.value?.close();
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.MOENGAGE.SAVE_ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

const handleDisconnect = async () => {
  try {
    await store.dispatch('integrations/deleteMoengage');
    useAlert(t('INTEGRATION_SETTINGS.MOENGAGE.DISCONNECT_SUCCESS'));
    disconnectDialogRef.value?.close();
    router.push({ name: 'settings_applications' });
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.MOENGAGE.DISCONNECT_ERROR'));
  }
};

const copyWebhookUrl = async () => {
  await copyTextToClipboard(webhookUrl.value);
  useAlert(t('INTEGRATION_SETTINGS.MOENGAGE.WEBHOOK_URL_COPIED'));
};

const regenerateToken = async () => {
  if (
    !window.confirm(t('INTEGRATION_SETTINGS.MOENGAGE.REGENERATE_TOKEN_CONFIRM'))
  ) {
    return;
  }

  try {
    await store.dispatch('integrations/regenerateMoengageToken');
    useAlert(t('INTEGRATION_SETTINGS.MOENGAGE.TOKEN_REGENERATED'));
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.MOENGAGE.SAVE_ERROR'));
  }
};

const isUpdatingSettings = ref(false);

const toggleAiResponse = async newValue => {
  isUpdatingSettings.value = true;
  try {
    await store.dispatch('integrations/updateMoengage', {
      enable_ai_response: newValue,
    });
    formData.value.enable_ai_response = newValue;
    useAlert(t('INTEGRATION_SETTINGS.MOENGAGE.SETTINGS.UPDATE_SUCCESS'));
  } catch (error) {
    // Revert the toggle on error
    formData.value.enable_ai_response = !newValue;
    useAlert(t('INTEGRATION_SETTINGS.MOENGAGE.SETTINGS.UPDATE_ERROR'));
  } finally {
    isUpdatingSettings.value = false;
  }
};

// Watch for hook changes to update form data
watch(currentHook, newHook => {
  if (newHook?.settings) {
    formData.value.enable_ai_response =
      newHook.settings.enable_ai_response ?? false;
  }
});

const initializeMoengageIntegration = async () => {
  await store.dispatch('integrations/get');
  await store.dispatch('inboxes/get');

  // Fetch MoEngage-specific data to get webhook_url
  if (isConnected.value) {
    await store.dispatch('integrations/fetchMoengage');
  }

  if (currentHook.value?.settings) {
    const settings = currentHook.value.settings;
    formData.value = {
      workspace_id: settings.workspace_id || '',
      data_center: settings.data_center || '01',
      default_inbox_id: settings.default_inbox_id || null,
      auto_create_contact: settings.auto_create_contact ?? true,
      enable_ai_response: settings.enable_ai_response ?? false,
    };
  }

  integrationLoaded.value = true;
};

onMounted(() => {
  initializeMoengageIntegration();
});
</script>

<template>
  <div class="flex-grow flex-shrink p-4 overflow-auto max-w-6xl mx-auto">
    <div
      v-if="integrationLoaded && !uiFlags.isCreatingMoengage"
      class="flex flex-col gap-6"
    >
      <Integration
        :integration-id="integration.id"
        :integration-logo="integration.logo"
        :integration-name="integration.name"
        :integration-description="integration.description"
        :integration-enabled="isConnected"
        :integration-action="integrationAction"
        :delete-confirmation-text="{
          title: $t('INTEGRATION_SETTINGS.MOENGAGE.DELETE.TITLE'),
          message: $t('INTEGRATION_SETTINGS.MOENGAGE.DELETE.MESSAGE'),
        }"
      >
        <template #action>
          <Button
            v-if="!isConnected"
            teal
            :label="$t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT')"
            @click="openConnectDialog"
          />
          <Button
            v-else
            faded
            ruby
            :label="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')"
            @click="openDisconnectDialog"
          />
        </template>
      </Integration>

      <div
        v-if="isConnected && webhookUrl"
        class="p-6 outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow"
      >
        <h4 class="text-base font-medium mb-3 text-n-slate-12">
          {{ $t('INTEGRATION_SETTINGS.MOENGAGE.WEBHOOK_URL') }}
        </h4>
        <div class="flex items-center gap-3 mb-2">
          <input
            type="text"
            :value="webhookUrl"
            readonly
            class="flex-1 px-3 py-2 text-sm bg-n-solid-3 border border-n-weak rounded font-mono text-n-slate-12"
          />
          <Button
            faded
            slate
            size="small"
            :label="$t('INTEGRATION_SETTINGS.MOENGAGE.COPY_WEBHOOK_URL')"
            @click="copyWebhookUrl"
          />
          <Button
            faded
            amber
            size="small"
            :label="$t('INTEGRATION_SETTINGS.MOENGAGE.REGENERATE_TOKEN')"
            @click="regenerateToken"
          />
        </div>
        <p class="text-xs text-n-slate-11">
          {{ $t('INTEGRATION_SETTINGS.MOENGAGE.WEBHOOK_URL_HELP') }}
        </p>
      </div>

      <div
        v-if="isConnected"
        class="p-6 outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow"
      >
        <h4 class="text-base font-medium mb-4 text-n-slate-12">
          {{ $t('INTEGRATION_SETTINGS.MOENGAGE.SETTINGS.TITLE') }}
        </h4>
        <div class="flex flex-col gap-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <p class="text-xs text-n-slate-11 mb-1">
                {{ $t('INTEGRATION_SETTINGS.MOENGAGE.FORM.WORKSPACE_ID') }}
              </p>
              <p class="text-sm text-n-slate-12 font-mono">
                {{ formData.workspace_id || '-' }}
              </p>
            </div>
            <div>
              <p class="text-xs text-n-slate-11 mb-1">
                {{ $t('INTEGRATION_SETTINGS.MOENGAGE.FORM.DATA_CENTER') }}
              </p>
              <p class="text-sm text-n-slate-12">
                {{ dataCenterLabel }}
              </p>
            </div>
            <div>
              <p class="text-xs text-n-slate-11 mb-1">
                {{ $t('INTEGRATION_SETTINGS.MOENGAGE.FORM.DEFAULT_INBOX') }}
              </p>
              <p class="text-sm text-n-slate-12">
                {{ currentInboxName }}
              </p>
            </div>
            <div>
              <p class="text-xs text-n-slate-11 mb-1">
                {{
                  $t('INTEGRATION_SETTINGS.MOENGAGE.FORM.AUTO_CREATE_CONTACT')
                }}
              </p>
              <p class="text-sm text-n-slate-12">
                {{ formData.auto_create_contact ? 'Enabled' : 'Disabled' }}
              </p>
            </div>
          </div>
          <div
            class="flex items-center justify-between pt-4 border-t border-n-weak"
          >
            <div class="flex-1">
              <h5 class="text-sm font-medium text-n-slate-12">
                {{
                  $t('INTEGRATION_SETTINGS.MOENGAGE.SETTINGS.AI_SETTINGS_TITLE')
                }}
              </h5>
              <p class="text-xs text-n-slate-11">
                {{
                  $t(
                    'INTEGRATION_SETTINGS.MOENGAGE.SETTINGS.AI_SETTINGS_DESCRIPTION'
                  )
                }}
              </p>
            </div>
            <Switch
              :model-value="formData.enable_ai_response"
              :disabled="isUpdatingSettings"
              @update:model-value="toggleAiResponse"
            />
          </div>
        </div>
      </div>

      <Dialog
        ref="dialogRef"
        :title="$t('INTEGRATION_SETTINGS.MOENGAGE.CONNECT_TITLE')"
        :is-loading="isSubmitting"
        @confirm="handleConnect"
      >
        <div class="flex flex-col gap-4">
          <Input
            v-model="formData.workspace_id"
            :label="$t('INTEGRATION_SETTINGS.MOENGAGE.FORM.WORKSPACE_ID')"
            :placeholder="
              $t('INTEGRATION_SETTINGS.MOENGAGE.FORM.WORKSPACE_ID_PLACEHOLDER')
            "
            :message="
              $t('INTEGRATION_SETTINGS.MOENGAGE.FORM.WORKSPACE_ID_HELP')
            "
            message-type="info"
          />

          <FormSelect
            v-model="formData.data_center"
            name="data_center"
            :label="$t('INTEGRATION_SETTINGS.MOENGAGE.FORM.DATA_CENTER')"
            :options="dataCenterOptions"
          />

          <FormSelect
            v-model="selectedInboxId"
            name="default_inbox_id"
            :label="$t('INTEGRATION_SETTINGS.MOENGAGE.FORM.DEFAULT_INBOX')"
            :placeholder="
              $t('INTEGRATION_SETTINGS.MOENGAGE.FORM.DEFAULT_INBOX_PLACEHOLDER')
            "
            :options="inboxOptions"
          />

          <div class="flex items-center gap-2">
            <input
              id="auto_create_contact"
              v-model="formData.auto_create_contact"
              type="checkbox"
              class="w-4 h-4"
            />
            <label for="auto_create_contact" class="text-sm text-n-slate-12">
              {{ $t('INTEGRATION_SETTINGS.MOENGAGE.FORM.AUTO_CREATE_CONTACT') }}
            </label>
          </div>

          <div class="flex flex-col gap-1">
            <div class="flex items-center gap-2">
              <input
                id="enable_ai_response"
                v-model="formData.enable_ai_response"
                type="checkbox"
                class="w-4 h-4"
              />
              <label for="enable_ai_response" class="text-sm text-n-slate-12">
                {{
                  $t('INTEGRATION_SETTINGS.MOENGAGE.FORM.ENABLE_AI_RESPONSE')
                }}
              </label>
            </div>
            <p class="text-xs text-n-slate-11 ml-6">
              {{
                $t('INTEGRATION_SETTINGS.MOENGAGE.FORM.ENABLE_AI_RESPONSE_HELP')
              }}
            </p>
          </div>
        </div>
      </Dialog>

      <Dialog
        ref="disconnectDialogRef"
        type="alert"
        :title="$t('INTEGRATION_SETTINGS.MOENGAGE.DELETE.TITLE')"
        :description="$t('INTEGRATION_SETTINGS.MOENGAGE.DELETE.MESSAGE')"
        :confirm-button-label="
          $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.YES')
        "
        :cancel-button-label="
          $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.NO')
        "
        @confirm="handleDisconnect"
      />
    </div>

    <div v-else class="flex items-center justify-center flex-1">
      <Spinner size="" color-scheme="primary" />
    </div>
  </div>
</template>
