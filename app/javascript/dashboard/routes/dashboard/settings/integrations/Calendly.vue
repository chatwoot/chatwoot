<script setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import calendlyAPI from 'dashboard/api/integrations/calendly';

import Integration from './Integration.vue';
import Spinner from 'shared/components/Spinner.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextButton from 'next/button/Button.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

const store = useStore();
const { t: $t } = useI18n();

const integrationLoaded = ref(false);
const isSubmitting = ref(false);
const isResubscribing = ref(false);
const hasWhatsAppInboxes = ref(false);
const webhookActive = ref(false);

const formState = reactive({
  booked: '',
  rescheduled: '',
  canceled: '',
});

const webhookLogs = ref([]);
const webhookLogsCount = ref(0);
const webhookLogsPage = ref(1);
const webhookLogsLoading = ref(false);
const webhookLogsStatusFilter = ref('');
const expandedLogId = ref(null);

const integration = useFunctionGetter(
  'integrations/getIntegration',
  'calendly'
);

const uiFlags = useMapGetter('integrations/getUIFlags');

const whatsAppInboxes = useMapGetter('inboxes/getWhatsAppInboxes');

const approvedTemplates = computed(() => {
  const templates = [];
  const seen = new Set();
  (whatsAppInboxes.value || []).forEach(inbox => {
    (inbox.message_templates || []).forEach(tpl => {
      if (tpl.status?.toLowerCase() === 'approved' && !seen.has(tpl.name)) {
        seen.add(tpl.name);
        templates.push(tpl);
      }
    });
  });
  return templates;
});

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return integration.value.action;
});

const showWebhookBanner = computed(
  () => integration.value.enabled && integrationLoaded.value
);

const showTemplateSection = computed(
  () =>
    integration.value.enabled &&
    hasWhatsAppInboxes.value &&
    integrationLoaded.value
);

const showWebhookLogs = computed(
  () => integration.value.enabled && integrationLoaded.value
);

const STATUS_BADGE_CLASSES = {
  received: 'bg-slate-100 text-slate-700 dark:bg-slate-700 dark:text-slate-300',
  processing:
    'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300',
  processed:
    'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
  failed: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300',
};

const statusBadgeClass = status => STATUS_BADGE_CLASSES[status] || '';

const logSummary = log => {
  if (log.status === 'failed') return log.error_message || 'Processing failed';
  const r = log.response_data || {};
  if (r.reason) return r.reason.replace(/_/g, ' ');
  const parts = [];
  if (r.contact_id) parts.push(`Contact #${r.contact_id}`);
  if (r.conversation_id) parts.push(`Conversation #${r.conversation_id}`);
  return parts.length ? parts.join(', ') : '-';
};

const formatLogTime = iso => {
  if (!iso) return '-';
  const d = new Date(iso);
  return d.toLocaleString(undefined, {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const toggleExpanded = id => {
  expandedLogId.value = expandedLogId.value === id ? null : id;
};

const fetchWebhookLogs = async () => {
  webhookLogsLoading.value = true;
  try {
    const { data } = await calendlyAPI.getWebhookLogs({
      page: webhookLogsPage.value,
      status: webhookLogsStatusFilter.value || undefined,
    });
    webhookLogs.value = data.payload;
    webhookLogsCount.value = data.meta.count;
  } catch {
    useAlert($t('INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.FETCH_ERROR'));
  } finally {
    webhookLogsLoading.value = false;
  }
};

const onLogsPageChange = page => {
  webhookLogsPage.value = page;
  fetchWebhookLogs();
};

const onLogsStatusFilterChange = () => {
  webhookLogsPage.value = 1;
  fetchWebhookLogs();
};

const loadCurrentSettings = async () => {
  try {
    const hook = integration.value.hooks?.[0];
    if (!hook?.settings?.calendly_templates) return;

    const templates = hook.settings.calendly_templates;
    formState.booked = templates.booked || '';
    formState.rescheduled = templates.rescheduled || '';
    formState.canceled = templates.canceled || '';
  } catch {
    // Settings not configured yet
  }
};

const initializeCalendlyIntegration = async () => {
  await store.dispatch('integrations/get', 'calendly');
  await store.dispatch('inboxes/get');
  hasWhatsAppInboxes.value = (whatsAppInboxes.value || []).length > 0;
  const hook = integration.value.hooks?.[0];
  webhookActive.value = !!hook?.settings?.webhook_subscription_uri;
  await loadCurrentSettings();
  integrationLoaded.value = true;

  if (integration.value.enabled) {
    fetchWebhookLogs();
  }
};

const handleResubscribe = async () => {
  isResubscribing.value = true;
  try {
    await calendlyAPI.resubscribeWebhook();
    webhookActive.value = true;
    useAlert($t('INTEGRATION_SETTINGS.CALENDLY.WEBHOOK.RESUBSCRIBE_SUCCESS'));
  } catch (e) {
    const msg =
      e.response?.data?.error ||
      $t('INTEGRATION_SETTINGS.CALENDLY.WEBHOOK.RESUBSCRIBE_ERROR');
    useAlert(msg);
  } finally {
    isResubscribing.value = false;
  }
};

const handleSubmit = async () => {
  isSubmitting.value = true;
  try {
    await calendlyAPI.updateSettings({
      calendly_templates: {
        booked: formState.booked || null,
        rescheduled: formState.rescheduled || null,
        canceled: formState.canceled || null,
      },
    });
    useAlert($t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.SAVE_SUCCESS'));
  } catch {
    useAlert($t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.SAVE_ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

onMounted(() => {
  initializeCalendlyIntegration();
});
</script>

<template>
  <div class="flex-grow flex-shrink p-4 overflow-auto max-w-6xl mx-auto">
    <div v-if="integrationLoaded && !uiFlags.isDeleting">
      <Integration
        :integration-id="integration.id"
        :integration-logo="integration.logo"
        :integration-name="integration.name"
        :integration-description="integration.description"
        :integration-enabled="integration.enabled"
        :integration-action="integrationAction"
        :delete-confirmation-text="{
          title: $t('INTEGRATION_SETTINGS.CALENDLY.DELETE.TITLE'),
          message: $t('INTEGRATION_SETTINGS.CALENDLY.DELETE.MESSAGE'),
        }"
      />

      <div
        v-if="showWebhookBanner"
        class="mt-4 flex items-center justify-between rounded-lg border p-4"
        :class="
          webhookActive
            ? 'border-green-200 bg-green-50 text-green-800'
            : 'border-amber-200 bg-amber-50 text-amber-800'
        "
      >
        <span class="text-sm">
          {{
            webhookActive
              ? $t('INTEGRATION_SETTINGS.CALENDLY.WEBHOOK.ACTIVE')
              : $t('INTEGRATION_SETTINGS.CALENDLY.WEBHOOK.INACTIVE')
          }}
        </span>
        <NextButton
          v-if="!webhookActive"
          xs
          amber
          :is-loading="isResubscribing"
          :label="$t('INTEGRATION_SETTINGS.CALENDLY.WEBHOOK.RESUBSCRIBE')"
          @click="handleResubscribe"
        />
      </div>

      <div v-if="showTemplateSection" class="mt-6">
        <SectionLayout
          :title="$t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.TITLE')"
          :description="
            $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.DESCRIPTION')
          "
        >
          <div
            class="mb-4 rounded-lg border border-slate-200 bg-slate-50 p-4 text-sm text-slate-700"
          >
            <p>
              {{ $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.HELP_TEXT') }}
            </p>
            <ul class="mt-2 list-disc pl-5 space-y-1">
              <li>
                {{ $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.VAR_NAME') }}
              </li>
              <li>
                {{ $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.VAR_EVENT') }}
              </li>
              <li>
                {{ $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.VAR_TIME') }}
              </li>
            </ul>
          </div>

          <form class="grid gap-5" @submit.prevent="handleSubmit">
            <WithLabel
              name="bookedTemplate"
              :label="
                $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.BOOKED_LABEL')
              "
            >
              <select
                v-model="formState.booked"
                class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
              >
                <option value="">
                  {{
                    $t(
                      'INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.SELECT_PLACEHOLDER'
                    )
                  }}
                </option>
                <option
                  v-for="tpl in approvedTemplates"
                  :key="tpl.name"
                  :value="tpl.name"
                >
                  {{ tpl.name }}
                </option>
              </select>
            </WithLabel>

            <WithLabel
              name="rescheduledTemplate"
              :label="
                $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.RESCHEDULED_LABEL')
              "
            >
              <select
                v-model="formState.rescheduled"
                class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
              >
                <option value="">
                  {{
                    $t(
                      'INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.SELECT_PLACEHOLDER'
                    )
                  }}
                </option>
                <option
                  v-for="tpl in approvedTemplates"
                  :key="tpl.name"
                  :value="tpl.name"
                >
                  {{ tpl.name }}
                </option>
              </select>
            </WithLabel>

            <WithLabel
              name="canceledTemplate"
              :label="
                $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.CANCELED_LABEL')
              "
            >
              <select
                v-model="formState.canceled"
                class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
              >
                <option value="">
                  {{
                    $t(
                      'INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.SELECT_PLACEHOLDER'
                    )
                  }}
                </option>
                <option
                  v-for="tpl in approvedTemplates"
                  :key="tpl.name"
                  :value="tpl.name"
                >
                  {{ tpl.name }}
                </option>
              </select>
            </WithLabel>

            <div class="flex gap-2">
              <NextButton
                blue
                type="submit"
                :is-loading="isSubmitting"
                :label="
                  $t('INTEGRATION_SETTINGS.CALENDLY.TEMPLATES.SAVE_BUTTON')
                "
              />
            </div>
          </form>
        </SectionLayout>
      </div>
      <div v-if="showWebhookLogs" class="mt-6">
        <SectionLayout
          :title="$t('INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.TITLE')"
          :description="
            $t('INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.DESCRIPTION')
          "
        >
          <div class="mb-4">
            <select
              v-model="webhookLogsStatusFilter"
              class="w-48 rounded-md border border-slate-300 px-3 py-2 text-sm dark:border-slate-600 dark:bg-slate-800"
              @change="onLogsStatusFilterChange"
            >
              <option value="">
                {{
                  $t('INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.STATUS.ALL')
                }}
              </option>
              <option value="received">
                {{
                  $t(
                    'INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.STATUS.RECEIVED'
                  )
                }}
              </option>
              <option value="processing">
                {{
                  $t(
                    'INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.STATUS.PROCESSING'
                  )
                }}
              </option>
              <option value="processed">
                {{
                  $t(
                    'INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.STATUS.PROCESSED'
                  )
                }}
              </option>
              <option value="failed">
                {{
                  $t('INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.STATUS.FAILED')
                }}
              </option>
            </select>
          </div>

          <div
            v-if="webhookLogsLoading"
            class="flex items-center justify-center py-8"
          >
            <Spinner size="" color-scheme="primary" />
          </div>

          <div
            v-else-if="webhookLogs.length === 0"
            class="rounded-lg border border-slate-200 bg-slate-50 p-6 text-center text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-400"
          >
            {{ $t('INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.EMPTY') }}
          </div>

          <div v-else>
            <table class="w-full text-sm border-collapse">
              <thead>
                <tr
                  class="border-b border-slate-200 text-left text-xs font-medium uppercase text-slate-500 dark:border-slate-700 dark:text-slate-400"
                >
                  <th class="px-3 py-2">
                    {{
                      $t(
                        'INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.COLUMNS.TIME'
                      )
                    }}
                  </th>
                  <th class="px-3 py-2">
                    {{
                      $t(
                        'INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.COLUMNS.EVENT'
                      )
                    }}
                  </th>
                  <th class="px-3 py-2">
                    {{
                      $t(
                        'INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.COLUMNS.STATUS'
                      )
                    }}
                  </th>
                  <th class="px-3 py-2">
                    {{
                      $t(
                        'INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.COLUMNS.SUMMARY'
                      )
                    }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <template v-for="log in webhookLogs" :key="log.id">
                  <tr
                    class="cursor-pointer border-b border-slate-100 hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
                    @click="toggleExpanded(log.id)"
                  >
                    <td
                      class="whitespace-nowrap px-3 py-2 text-slate-600 dark:text-slate-300"
                    >
                      {{ formatLogTime(log.created_at) }}
                    </td>
                    <td
                      class="px-3 py-2 font-mono text-xs text-slate-700 dark:text-slate-300"
                    >
                      {{ log.event_type }}
                    </td>
                    <td class="px-3 py-2">
                      <span
                        class="inline-block rounded-full px-2 py-0.5 text-xs font-medium"
                        :class="statusBadgeClass(log.status)"
                      >
                        {{ log.status }}
                      </span>
                    </td>
                    <td class="px-3 py-2 text-slate-600 dark:text-slate-400">
                      {{ logSummary(log) }}
                    </td>
                  </tr>
                  <tr v-if="expandedLogId === log.id">
                    <td
                      colspan="4"
                      class="bg-slate-50 px-4 py-3 dark:bg-slate-800"
                    >
                      <div v-if="log.error_message" class="mb-3">
                        <p
                          class="text-xs font-medium text-red-600 dark:text-red-400"
                        >
                          {{
                            $t(
                              'INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.DETAILS.ERROR'
                            )
                          }}
                        </p>
                        <!-- prettier-ignore -->
                        <pre
                          class="mt-1 overflow-x-auto rounded bg-red-50 p-2 text-xs text-red-800 dark:bg-red-900/30 dark:text-red-300"
                        >{{ log.error_message }}</pre>
                      </div>
                      <div class="mb-3">
                        <p
                          class="text-xs font-medium text-slate-500 dark:text-slate-400"
                        >
                          {{
                            $t(
                              'INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.DETAILS.PAYLOAD'
                            )
                          }}
                        </p>
                        <!-- prettier-ignore -->
                        <pre
                          class="mt-1 max-h-48 overflow-auto rounded bg-slate-100 p-2 text-xs text-slate-700 dark:bg-slate-900 dark:text-slate-300"
                        >{{ JSON.stringify(log.payload, null, 2) }}</pre>
                      </div>
                      <div
                        v-if="
                          log.response_data &&
                          Object.keys(log.response_data).length
                        "
                      >
                        <p
                          class="text-xs font-medium text-slate-500 dark:text-slate-400"
                        >
                          {{
                            $t(
                              'INTEGRATION_SETTINGS.CALENDLY.WEBHOOK_LOGS.DETAILS.RESPONSE'
                            )
                          }}
                        </p>
                        <!-- prettier-ignore -->
                        <pre
                          class="mt-1 max-h-48 overflow-auto rounded bg-slate-100 p-2 text-xs text-slate-700 dark:bg-slate-900 dark:text-slate-300"
                        >{{ JSON.stringify(log.response_data, null, 2) }}</pre>
                      </div>
                    </td>
                  </tr>
                </template>
              </tbody>
            </table>

            <div v-if="webhookLogsCount > 15" class="mt-4">
              <PaginationFooter
                :current-page="webhookLogsPage"
                :total-items="webhookLogsCount"
                :items-per-page="15"
                @update:current-page="onLogsPageChange"
              />
            </div>
          </div>
        </SectionLayout>
      </div>
    </div>
    <div v-else class="flex items-center justify-center flex-1">
      <Spinner size="" color-scheme="primary" />
    </div>
  </div>
</template>
