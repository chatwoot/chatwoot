<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { format } from 'date-fns';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import IntegrationsAPI from 'dashboard/api/integrations';

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
const showDocs = ref(false);

const toggleDocs = () => {
  showDocs.value = !showDocs.value;
};

const examplePayload = `{
  "event_name": "cart_abandoned",
  "customer": {
    "email": "john@example.com",
    "phone": "+1234567890",
    "customer_id": "cust_123",
    "first_name": "John",
    "last_name": "Doe"
  },
  "event_attributes": {
    "product_name": "Wireless Headphones",
    "cart_value": "$199.99",
    "items_count": 2
  },
  "campaign": {
    "id": "camp_123",
    "name": "Cart Recovery"
  }
}`;

const copyExamplePayload = async () => {
  await copyTextToClipboard(examplePayload);
  useAlert(t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.EXAMPLE_COPIED'));
};

const payloadFields = computed(() => [
  {
    key: 'event_name',
    name: 'event_name',
    description: t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.FIELDS.EVENT_NAME'),
  },
  {
    key: 'customer',
    name: 'customer',
    description: t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.FIELDS.CUSTOMER'),
    children: [
      {
        key: 'email',
        name: 'email',
        description: t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.FIELDS.EMAIL'),
      },
      {
        key: 'phone',
        name: 'phone',
        description: t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.FIELDS.PHONE'),
      },
      {
        key: 'customer_id',
        name: 'customer_id',
        description: t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.FIELDS.CUSTOMER_ID'),
      },
      {
        key: 'first_name',
        name: 'first_name',
        description: t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.FIELDS.FIRST_NAME'),
      },
      {
        key: 'last_name',
        name: 'last_name',
        description: t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.FIELDS.LAST_NAME'),
      },
    ],
  },
  {
    key: 'event_attributes',
    name: 'event_attributes',
    description: t(
      'INTEGRATION_SETTINGS.MOENGAGE.DOCS.FIELDS.EVENT_ATTRIBUTES'
    ),
  },
  {
    key: 'campaign',
    name: 'campaign',
    description: t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.FIELDS.CAMPAIGN'),
  },
]);

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

// Webhook Event Logs
const showLogs = ref(false);
const eventLogs = ref([]);
const logsLoading = ref(false);
const logsMeta = ref({
  total_count: 0,
  page: 1,
  per_page: 10,
  total_pages: 0,
});
const selectedLogPayload = ref(null);
const payloadDialogRef = ref(null);

const fetchEventLogs = async (page = 1) => {
  logsLoading.value = true;
  try {
    const response = await IntegrationsAPI.getMoengageWebhookEventLogs({
      page,
      perPage: 10,
    });
    eventLogs.value = response.data.payload;
    logsMeta.value = response.data.meta;
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.FETCH_ERROR'));
  } finally {
    logsLoading.value = false;
  }
};

const toggleLogs = () => {
  showLogs.value = !showLogs.value;
  if (showLogs.value && eventLogs.value.length === 0) {
    fetchEventLogs();
  }
};

const refreshLogs = () => {
  fetchEventLogs(logsMeta.value.page);
};

const goToPage = page => {
  if (page >= 1 && page <= logsMeta.value.total_pages) {
    fetchEventLogs(page);
  }
};

const formatDate = dateString => {
  if (!dateString) return '-';
  return format(new Date(dateString), 'MMM d, yyyy h:mm a');
};

const getStatusClass = status => {
  const classes = {
    success: 'bg-g-50 text-g-800 dark:bg-g-800 dark:text-g-100',
    failed: 'bg-r-50 text-r-800 dark:bg-r-800 dark:text-r-100',
    pending: 'bg-y-50 text-y-800 dark:bg-y-800 dark:text-y-100',
    skipped: 'bg-n-50 text-n-800 dark:bg-n-800 dark:text-n-100',
  };
  return classes[status] || classes.pending;
};

const viewPayload = log => {
  selectedLogPayload.value = log;
  payloadDialogRef.value?.open();
};

const formatJson = obj => {
  try {
    return JSON.stringify(obj, null, 2);
  } catch {
    return String(obj);
  }
};

const initializeMoengageIntegration = async () => {
  await store.dispatch('integrations/get');
  await store.dispatch('inboxes/get');

  // Always try to fetch MoEngage-specific data to get webhook_url
  // This will return the full hook data including webhook_url if connected
  const hookData = await store.dispatch('integrations/fetchMoengage');

  // Update form data from fetched hook or from existing hook in store
  const settings = hookData?.settings || currentHook.value?.settings;
  if (settings) {
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
                {{
                  formData.auto_create_contact
                    ? $t('INTEGRATION_SETTINGS.MOENGAGE.SETTINGS.ENABLED')
                    : $t('INTEGRATION_SETTINGS.MOENGAGE.SETTINGS.DISABLED')
                }}
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

      <div
        v-if="isConnected"
        class="p-6 outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow"
      >
        <div
          class="flex items-center justify-between cursor-pointer"
          @click="toggleDocs"
        >
          <div>
            <h4 class="text-base font-medium text-n-slate-12">
              {{ $t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.TITLE') }}
            </h4>
            <p class="text-sm text-n-slate-11">
              {{ $t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.DESCRIPTION') }}
            </p>
          </div>
          <span
            class="text-n-slate-11 transition-transform"
            :class="{ 'rotate-180': showDocs }"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <polyline points="6 9 12 15 18 9" />
            </svg>
          </span>
        </div>

        <div v-if="showDocs" class="mt-4 flex flex-col gap-4">
          <div>
            <h5 class="text-sm font-medium text-n-slate-12 mb-2">
              {{ $t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.PAYLOAD_STRUCTURE') }}
            </h5>
            <div class="text-xs space-y-2">
              <div
                v-for="field in payloadFields"
                :key="field.key"
                class="flex flex-col"
              >
                <div class="flex items-start gap-2">
                  <code
                    class="text-n-slate-12 bg-n-solid-3 px-1 rounded shrink-0"
                  >
                    {{ field.name }}
                  </code>
                  <span class="text-n-slate-11">{{ field.description }}</span>
                </div>
                <div v-if="field.children" class="ml-6 mt-1 space-y-1">
                  <div
                    v-for="child in field.children"
                    :key="child.key"
                    class="flex items-start gap-2"
                  >
                    <code
                      class="text-n-slate-12 bg-n-solid-3 px-1 rounded shrink-0"
                    >
                      {{ child.name }}
                    </code>
                    <span class="text-n-slate-11">{{ child.description }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div>
            <div class="flex items-center justify-between mb-2">
              <h5 class="text-sm font-medium text-n-slate-12">
                {{ $t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.EXAMPLE_TITLE') }}
              </h5>
              <Button
                faded
                slate
                size="small"
                :label="$t('INTEGRATION_SETTINGS.MOENGAGE.DOCS.COPY_EXAMPLE')"
                @click="copyExamplePayload"
              />
            </div>
            <pre
              class="text-xs bg-n-solid-3 border border-n-weak rounded p-3 overflow-x-auto text-n-slate-12"
            >
              {{ examplePayload }}
            </pre>
          </div>
        </div>
      </div>

      <!-- Webhook Event Logs Section -->
      <div
        v-if="isConnected"
        class="p-6 outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow"
      >
        <div
          class="flex items-center justify-between cursor-pointer"
          @click="toggleLogs"
        >
          <div>
            <h4 class="text-base font-medium text-n-slate-12">
              {{ $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.TITLE') }}
            </h4>
            <p class="text-sm text-n-slate-11">
              {{ $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.DESCRIPTION') }}
            </p>
          </div>
          <div class="flex items-center gap-2">
            <Button
              v-if="showLogs"
              faded
              slate
              size="small"
              :label="$t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.REFRESH')"
              @click.stop="refreshLogs"
            />
            <span
              class="text-n-slate-11 transition-transform"
              :class="{ 'rotate-180': showLogs }"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <polyline points="6 9 12 15 18 9" />
              </svg>
            </span>
          </div>
        </div>

        <div v-if="showLogs" class="mt-4">
          <div v-if="logsLoading" class="flex justify-center py-8">
            <Spinner size="" color-scheme="primary" />
          </div>

          <div v-else-if="eventLogs.length === 0" class="py-8 text-center">
            <p class="text-sm text-n-slate-11">
              {{ $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.EMPTY') }}
            </p>
          </div>

          <div v-else>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-n-weak">
                <thead>
                  <tr>
                    <th
                      class="py-3 ltr:pr-4 rtl:pl-4 text-left text-xs font-semibold text-n-slate-11 uppercase tracking-wider"
                    >
                      {{ $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.TABLE.EVENT') }}
                    </th>
                    <th
                      class="py-3 px-4 text-left text-xs font-semibold text-n-slate-11 uppercase tracking-wider"
                    >
                      {{
                        $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.TABLE.STATUS')
                      }}
                    </th>
                    <th
                      class="py-3 px-4 text-left text-xs font-semibold text-n-slate-11 uppercase tracking-wider"
                    >
                      {{
                        $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.TABLE.CONTACT')
                      }}
                    </th>
                    <th
                      class="py-3 px-4 text-left text-xs font-semibold text-n-slate-11 uppercase tracking-wider"
                    >
                      {{ $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.TABLE.TIME') }}
                    </th>
                    <th
                      class="py-3 ltr:pl-4 rtl:pr-4 text-left text-xs font-semibold text-n-slate-11 uppercase tracking-wider"
                    >
                      {{
                        $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.TABLE.ACTIONS')
                      }}
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-n-weak">
                  <tr v-for="log in eventLogs" :key="log.id">
                    <td
                      class="py-3 ltr:pr-4 rtl:pl-4 text-sm text-n-slate-12 font-mono"
                    >
                      {{ log.event_name || '-' }}
                    </td>
                    <td class="py-3 px-4">
                      <span
                        class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium"
                        :class="getStatusClass(log.status)"
                      >
                        {{
                          $t(
                            `INTEGRATION_SETTINGS.MOENGAGE.LOGS.STATUS.${log.status.toUpperCase()}`
                          )
                        }}
                      </span>
                    </td>
                    <td class="py-3 px-4 text-sm text-n-slate-12">
                      <span v-if="log.contact_id">#{{ log.contact_id }}</span>
                      <span v-else class="text-n-slate-11">-</span>
                    </td>
                    <td class="py-3 px-4 text-sm text-n-slate-11">
                      {{ formatDate(log.created_at) }}
                    </td>
                    <td class="py-3 ltr:pl-4 rtl:pr-4">
                      <Button
                        faded
                        slate
                        size="small"
                        :label="
                          $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.VIEW_PAYLOAD')
                        "
                        @click="viewPayload(log)"
                      />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Pagination -->
            <div
              v-if="logsMeta.total_pages > 1"
              class="flex items-center justify-between mt-4 pt-4 border-t border-n-weak"
            >
              <p class="text-sm text-n-slate-11">
                {{
                  $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.PAGINATION.SHOWING', {
                    from: (logsMeta.page - 1) * logsMeta.per_page + 1,
                    to: Math.min(
                      logsMeta.page * logsMeta.per_page,
                      logsMeta.total_count
                    ),
                    total: logsMeta.total_count,
                  })
                }}
              </p>
              <div class="flex items-center gap-2">
                <Button
                  faded
                  slate
                  size="small"
                  :disabled="logsMeta.page <= 1"
                  :label="
                    $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.PAGINATION.PREVIOUS')
                  "
                  @click="goToPage(logsMeta.page - 1)"
                />
                <span class="text-sm text-n-slate-11">
                  {{ logsMeta.page }} / {{ logsMeta.total_pages }}
                </span>
                <Button
                  faded
                  slate
                  size="small"
                  :disabled="logsMeta.page >= logsMeta.total_pages"
                  :label="
                    $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.PAGINATION.NEXT')
                  "
                  @click="goToPage(logsMeta.page + 1)"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Payload Detail Dialog -->
      <Dialog
        ref="payloadDialogRef"
        :title="$t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.PAYLOAD_DIALOG.TITLE')"
        :show-confirm-button="false"
        :cancel-button-label="
          $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.PAYLOAD_DIALOG.CLOSE')
        "
      >
        <div v-if="selectedLogPayload" class="flex flex-col gap-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <p class="text-xs text-n-slate-11 mb-1">
                {{ $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.TABLE.EVENT') }}
              </p>
              <p class="text-sm text-n-slate-12 font-mono">
                {{ selectedLogPayload.event_name || '-' }}
              </p>
            </div>
            <div>
              <p class="text-xs text-n-slate-11 mb-1">
                {{ $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.TABLE.STATUS') }}
              </p>
              <span
                class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium"
                :class="getStatusClass(selectedLogPayload.status)"
              >
                {{
                  $t(
                    `INTEGRATION_SETTINGS.MOENGAGE.LOGS.STATUS.${selectedLogPayload.status.toUpperCase()}`
                  )
                }}
              </span>
            </div>
            <div>
              <p class="text-xs text-n-slate-11 mb-1">
                {{ $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.TABLE.CONTACT') }}
              </p>
              <p class="text-sm text-n-slate-12">
                {{ selectedLogPayload.contact_id || '-' }}
              </p>
            </div>
            <div>
              <p class="text-xs text-n-slate-11 mb-1">
                {{
                  $t(
                    'INTEGRATION_SETTINGS.MOENGAGE.LOGS.PAYLOAD_DIALOG.CONVERSATION'
                  )
                }}
              </p>
              <p class="text-sm text-n-slate-12">
                {{ selectedLogPayload.conversation_id || '-' }}
              </p>
            </div>
            <div>
              <p class="text-xs text-n-slate-11 mb-1">
                {{
                  $t(
                    'INTEGRATION_SETTINGS.MOENGAGE.LOGS.PAYLOAD_DIALOG.PROCESSING_TIME'
                  )
                }}
              </p>
              <p class="text-sm text-n-slate-12">
                {{
                  selectedLogPayload.processing_time_ms
                    ? `${selectedLogPayload.processing_time_ms}ms`
                    : '-'
                }}
              </p>
            </div>
            <div>
              <p class="text-xs text-n-slate-11 mb-1">
                {{ $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.TABLE.TIME') }}
              </p>
              <p class="text-sm text-n-slate-12">
                {{ formatDate(selectedLogPayload.created_at) }}
              </p>
            </div>
          </div>

          <div v-if="selectedLogPayload.error_message">
            <p class="text-xs text-n-slate-11 mb-1">
              {{
                $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.PAYLOAD_DIALOG.ERROR')
              }}
            </p>
            <p class="text-sm text-r-600 bg-r-50 dark:bg-r-900 p-2 rounded">
              {{ selectedLogPayload.error_message }}
            </p>
          </div>

          <div>
            <p class="text-xs text-n-slate-11 mb-1">
              {{
                $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.PAYLOAD_DIALOG.PAYLOAD')
              }}
            </p>
            <pre
              class="text-xs bg-n-solid-3 border border-n-weak rounded p-3 overflow-x-auto text-n-slate-12 max-h-64"
              >{{ formatJson(selectedLogPayload.payload) }}</pre
            >
          </div>

          <div
            v-if="Object.keys(selectedLogPayload.response_data || {}).length"
          >
            <p class="text-xs text-n-slate-11 mb-1">
              {{
                $t('INTEGRATION_SETTINGS.MOENGAGE.LOGS.PAYLOAD_DIALOG.RESPONSE')
              }}
            </p>
            <pre
              class="text-xs bg-n-solid-3 border border-n-weak rounded p-3 overflow-x-auto text-n-slate-12"
              >{{ formatJson(selectedLogPayload.response_data) }}</pre
            >
          </div>
        </div>
      </Dialog>

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
