<script setup>
import { computed, nextTick, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useTrack } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { CAPTAIN_TOOL_CATALOG_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import IntegrationsAPI from 'dashboard/api/integrations';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ProviderIcon from 'dashboard/components-next/captain/pageComponents/toolCatalog/ProviderIcon.vue';
import {
  buildConnectionSelections,
  buildSelections,
  flattenTemplates,
  installedConfigurations,
  installedTemplateKeys,
  missingRequiredConfiguration,
  requiredScopes,
  selectionChanged,
  selectedTemplates,
} from './catalogSelection';
import {
  clearCatalogFlow,
  getCatalogFlow,
  saveCatalogFlow,
} from './catalogFlow';

const STARTER_SETS = {
  stripe: [
    'get_current_customer',
    'get_subscription_status',
    'get_last_five_payments',
  ],
  shopify: [
    'get_current_customer',
    'list_recent_customer_orders',
    'get_order_tracking_status',
  ],
  linear: [
    'create_issue_from_conversation',
    'get_linked_issue_status',
    'add_comment_to_linked_issue',
  ],
  slack: ['send_message_to_channel', 'reply_to_thread', 'find_user_by_email'],
};

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();
const { isAdmin } = useAdmin();

const selectedKeys = ref([]);
const configurations = ref({});
const stripeCredential = ref('');
const shopDomain = ref('');
const channelOptions = ref([]);
const teamOptions = ref([]);
const projectOptions = ref([]);
const statusMessage = ref('');
const errorMessage = ref('');
const installationComplete = ref(false);
const isChangingStripeKey = ref(false);
const revokeDialogRef = ref(null);
const statusRef = ref(null);

const providerKey = computed(() => route.params.providerKey);
const accountId = computed(() => route.params.accountId);
const provider = useMapGetter('captainToolCatalog/getProvider');
const capacity = useMapGetter('captainToolCatalog/getCapacity');
const uiFlags = useMapGetter('captainToolCatalog/getUIFlags');

const providerDetails = computed(() => provider.value(providerKey.value));
const isFetching = computed(() => uiFlags.value.fetchingProvider);
const isMutating = computed(() => uiFlags.value.mutatingInstallation);
const isFetchingSetup = computed(() => uiFlags.value.fetchingSetup);
const allTemplates = computed(() => flattenTemplates(providerDetails.value));
const desiredTemplates = computed(() =>
  selectedTemplates(providerDetails.value, selectedKeys.value)
);
const connectionTemplates = computed(() =>
  desiredTemplates.value.filter(
    template => !template.installed || template.update_available
  )
);
const scopes = computed(() => requiredScopes(connectionTemplates.value));
const grantedScopes = computed(
  () => new Set(providerDetails.value?.connection.granted_scopes || [])
);
const requiresConnection = computed(
  () =>
    providerKey.value !== 'stripe' &&
    connectionTemplates.value.length > 0 &&
    (!providerDetails.value?.connection.connected ||
      scopes.value.some(scope => !grantedScopes.value.has(scope)))
);
const stripeRequiresCredential = computed(
  () =>
    providerKey.value === 'stripe' &&
    connectionTemplates.value.length > 0 &&
    (!providerDetails.value?.connection.connected ||
      scopes.value.some(scope => !grantedScopes.value.has(scope)))
);
const credentialsEncrypted = computed(
  () => providerDetails.value?.connection.credential_storage !== 'plaintext'
);
const changeConnectionLabel = computed(() =>
  providerKey.value === 'stripe'
    ? t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CHANGE_KEY')
    : t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CHANGE_CONNECTION')
);
const revokeConnectionLabel = computed(() =>
  providerKey.value === 'stripe'
    ? t('CAPTAIN.CUSTOM_TOOLS.CATALOG.REVOKE_KEY')
    : t('CAPTAIN.CUSTOM_TOOLS.CATALOG.REVOKE_CONNECTION')
);
const revokeConfirmationNotice = computed(() =>
  providerKey.value === 'stripe'
    ? t('CAPTAIN.CUSTOM_TOOLS.CATALOG.REVOKE_KEY_CONFIRM_NOTICE')
    : t('CAPTAIN.CUSTOM_TOOLS.CATALOG.REVOKE_CONFIRM_NOTICE')
);
const selectedCount = computed(() => desiredTemplates.value.length);
const projectedCapacity = computed(
  () =>
    capacity.value.used -
    (providerDetails.value?.installed_count || 0) +
    selectedCount.value
);
const hasCapacity = computed(
  () => projectedCapacity.value <= capacity.value.limit
);
const configurationMissing = computed(() =>
  missingRequiredConfiguration(desiredTemplates.value, configurations.value)
);
const hasSelectionChanges = computed(() =>
  selectionChanged(
    providerDetails.value,
    selectedKeys.value,
    configurations.value
  )
);
const updates = computed(() =>
  allTemplates.value.filter(template => template.update_available)
);
const canContinue = computed(() => {
  if (!hasSelectionChanges.value || !hasCapacity.value || isMutating.value) {
    return false;
  }
  if (requiresConnection.value) {
    return providerKey.value !== 'shopify' || shopDomain.value.trim();
  }
  if (stripeRequiresCredential.value) {
    return stripeCredential.value.trim();
  }
  return !configurationMissing.value;
});
const backUrl = computed(() => ({
  name: 'captain_tools_index',
  params: route.params,
  query: { view: 'browse' },
}));
const playgroundUrl = computed(() => ({
  name: 'captain_assistants_playground_index',
  params: {
    accountId: route.params.accountId,
    assistantId: route.params.assistantId,
  },
}));

const riskLabel = riskClass =>
  riskClass === 'read'
    ? t('CAPTAIN.CUSTOM_TOOLS.CATALOG.READ')
    : t('CAPTAIN.CUSTOM_TOOLS.CATALOG.WRITE');

const availabilityLabel = template => {
  if (template.availability !== 'available') {
    return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.REQUIRES_APPROVAL');
  }
  if (template.update_available) {
    return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.UPDATE_AVAILABLE');
  }
  if (template.installed) {
    return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.INSTALLED');
  }
  return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.AVAILABLE');
};

const formatError = error => {
  switch (error?.message) {
    case 'installation_expired':
      return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.ERRORS.INSTALLATION_EXPIRED');
    case 'invalid_shopify_domain':
      return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.ERRORS.INVALID_SHOPIFY_DOMAIN');
    case 'setup_connection_required':
      return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.ERRORS.SETUP_CONNECTION_REQUIRED');
    case 'stripe_restricted_key_required':
      return t(
        'CAPTAIN.CUSTOM_TOOLS.CATALOG.ERRORS.STRIPE_RESTRICTED_KEY_REQUIRED'
      );
    case 'tool_capacity_exceeded':
      return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.ERRORS.TOOL_CAPACITY_EXCEEDED');
    default:
      return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.ERRORS.GENERIC');
  }
};

const announce = async (message, { error = false } = {}) => {
  statusMessage.value = error ? '' : message;
  errorMessage.value = error ? message : '';
  await nextTick();
  statusRef.value?.focus();
};

const setConfiguration = (templateKey, key, value) => {
  configurations.value = {
    ...configurations.value,
    [templateKey]: {
      ...(configurations.value[templateKey] || {}),
      [key]: value,
    },
  };
};

const configurationValue = (templateKey, key) =>
  configurations.value[templateKey]?.[key] || '';

const templateNeedsConfiguration = templateKey =>
  (
    allTemplates.value.find(template => template.key === templateKey)
      ?.configuration_schema.required || []
  ).length > 0;

const requiresSlackChannel = computed(
  () =>
    providerKey.value === 'slack' &&
    selectedKeys.value.some(templateNeedsConfiguration)
);
const requiresLinearProject = computed(
  () =>
    providerKey.value === 'linear' &&
    selectedKeys.value.some(templateNeedsConfiguration)
);

const loadSlackChannels = async () => {
  if (
    !requiresSlackChannel.value ||
    !providerDetails.value.connection.connected
  ) {
    return;
  }
  const payload = await store.dispatch('captainToolCatalog/setup', {
    providerKey: 'slack',
    operationKey: 'list_channels',
  });
  channelOptions.value = payload.options.map(option => ({
    value: option.id,
    label: `${option.is_private ? 'Private: ' : ''}#${option.name}`,
  }));
};

const loadLinearProjects = async teamId => {
  if (!teamId) {
    projectOptions.value = [];
    return;
  }

  const payload = await store.dispatch('captainToolCatalog/setup', {
    providerKey: 'linear',
    operationKey: 'list_team_entities',
    arguments: { teamId },
  });
  projectOptions.value = payload.projects.map(option => ({
    value: option.id,
    label: option.name,
  }));
};

const loadLinearTeams = async () => {
  if (
    !requiresLinearProject.value ||
    !providerDetails.value.connection.connected
  ) {
    return;
  }
  const payload = await store.dispatch('captainToolCatalog/setup', {
    providerKey: 'linear',
    operationKey: 'list_teams',
  });
  teamOptions.value = payload.options.map(option => ({
    value: option.id,
    label: option.name,
  }));
  await loadLinearProjects(
    configurationValue('create_issue_from_conversation', 'team_id')
  );
};

const loadSetupOptions = async () => {
  try {
    await Promise.all([loadSlackChannels(), loadLinearTeams()]);
  } catch (error) {
    await announce(formatError(error), { error: true });
  }
};

const selectLinearTeam = async value => {
  const template = desiredTemplates.value.find(item =>
    item.configuration_schema.required?.includes('team_id')
  );
  if (!template) return;

  setConfiguration(template.key, 'team_id', value);
  setConfiguration(template.key, 'project_id', '');
  try {
    await loadLinearProjects(value);
  } catch (error) {
    await announce(formatError(error), { error: true });
  }
};

const setSlackChannel = value => {
  const template = desiredTemplates.value.find(item =>
    item.configuration_schema.required?.includes('channel_id')
  );
  if (template) setConfiguration(template.key, 'channel_id', value);
};

const toggleTemplate = async (template, selected) => {
  if (template.availability !== 'available' && !template.installed) return;

  selectedKeys.value = selected
    ? [...new Set([...selectedKeys.value, template.key])]
    : selectedKeys.value.filter(key => key !== template.key);
  installationComplete.value = false;
  if (selected) await loadSetupOptions();
};

const selectStarterSet = async () => {
  const availableKeys = new Set(
    allTemplates.value
      .filter(template => template.availability === 'available')
      .map(template => template.key)
  );
  const starterKeys = (STARTER_SETS[providerKey.value] || []).filter(key =>
    availableKeys.has(key)
  );
  selectedKeys.value = [...new Set([...selectedKeys.value, ...starterKeys])];
  installationComplete.value = false;
  useTrack(CAPTAIN_TOOL_CATALOG_EVENTS.STARTER_SET_SELECTED, {
    provider: providerKey.value,
    templateCount: selectedKeys.value.length,
  });
  await loadSetupOptions();
};

const saveFlow = installation => {
  saveCatalogFlow({
    accountId: accountId.value,
    assistantId: route.params.assistantId,
    providerKey: providerKey.value,
    installationId: installation.id,
    selectedKeys: selectedKeys.value,
    configurations: configurations.value,
  });
};

const startOAuth = async installation => {
  saveFlow(installation);
  useTrack(CAPTAIN_TOOL_CATALOG_EVENTS.CONNECTION_STARTED, {
    provider: providerKey.value,
    workflow: installation.workflow_kind,
    templateCount: selectedCount.value,
  });
  const data = { installation_id: installation.id };
  if (providerKey.value === 'shopify') {
    data.shop_domain = shopDomain.value;
  }
  const response = await IntegrationsAPI.startCatalogOAuth(
    providerKey.value,
    data
  );
  window.location.assign(response.data.redirect_url);
};

const resetSelection = () => {
  selectedKeys.value = installedTemplateKeys(providerDetails.value);
  configurations.value = installedConfigurations(providerDetails.value);
};

const saveSelection = async () => {
  errorMessage.value = '';
  installationComplete.value = false;
  const workflow = providerDetails.value.installed_count ? 'update' : 'install';
  try {
    if (requiresConnection.value) {
      const installation = await store.dispatch(
        'captainToolCatalog/prepareConnection',
        {
          provider_key: providerKey.value,
          templates: buildConnectionSelections(
            providerDetails.value,
            selectedKeys.value
          ),
        }
      );
      await startOAuth(installation);
      return;
    }

    const templates = buildSelections(
      providerDetails.value,
      selectedKeys.value,
      configurations.value
    );
    const data = {
      templates,
      credential: stripeCredential.value || undefined,
    };
    const installation =
      workflow === 'update'
        ? await store.dispatch('captainToolCatalog/update', {
            providerKey: providerKey.value,
            data,
          })
        : await store.dispatch('captainToolCatalog/install', {
            provider_key: providerKey.value,
            ...data,
          });
    if (installation.status === 'awaiting_connection') {
      await startOAuth(installation);
      return;
    }

    stripeCredential.value = '';
    clearCatalogFlow(accountId.value, providerKey.value);
    await store.dispatch('captainToolCatalog/show', providerKey.value);
    resetSelection();
    installationComplete.value = installation.resulting_tool_ids.length > 0;
    useTrack(CAPTAIN_TOOL_CATALOG_EVENTS.WORKFLOW_COMPLETED, {
      provider: providerKey.value,
      workflow,
      templateCount: installation.resulting_tool_ids.length,
    });
    const successMessage =
      workflow === 'update'
        ? t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SAVE_SUCCESS')
        : t('CAPTAIN.CUSTOM_TOOLS.CATALOG.INSTALL_SUCCESS');
    await announce(successMessage);
  } catch (error) {
    stripeCredential.value = '';
    useTrack(CAPTAIN_TOOL_CATALOG_EVENTS.WORKFLOW_FAILED, {
      provider: providerKey.value,
      workflow,
    });
    await announce(formatError(error), { error: true });
  }
};

const reconnect = async ({ forceReauthorization = false } = {}) => {
  errorMessage.value = '';
  try {
    const data = { force_reauthorization: forceReauthorization };
    if (providerKey.value === 'stripe')
      data.credential = stripeCredential.value;
    const installation = await store.dispatch('captainToolCatalog/reconnect', {
      providerKey: providerKey.value,
      data,
    });
    if (installation.status === 'awaiting_connection') {
      await startOAuth(installation);
      return;
    }
    stripeCredential.value = '';
    isChangingStripeKey.value = false;
    await store.dispatch('captainToolCatalog/show', providerKey.value);
    useTrack(CAPTAIN_TOOL_CATALOG_EVENTS.WORKFLOW_COMPLETED, {
      provider: providerKey.value,
      workflow: 'reconnect',
    });
    await announce(t('CAPTAIN.CUSTOM_TOOLS.CATALOG.RECONNECT_SUCCESS'));
  } catch (error) {
    stripeCredential.value = '';
    useTrack(CAPTAIN_TOOL_CATALOG_EVENTS.WORKFLOW_FAILED, {
      provider: providerKey.value,
      workflow: 'reconnect',
    });
    await announce(formatError(error), { error: true });
  }
};

const changeConnection = async () => {
  if (providerKey.value === 'stripe') {
    isChangingStripeKey.value = true;
    return;
  }

  await reconnect({ forceReauthorization: true });
};

const openRevokeDialog = () => revokeDialogRef.value?.open();

const revokeConnection = async () => {
  errorMessage.value = '';
  try {
    await store.dispatch('captainToolCatalog/disconnect', providerKey.value);
    revokeDialogRef.value?.close();
    stripeCredential.value = '';
    isChangingStripeKey.value = false;
    await store.dispatch('captainToolCatalog/show', providerKey.value);
    await announce(t('CAPTAIN.CUSTOM_TOOLS.CATALOG.REVOKE_SUCCESS'));
  } catch (error) {
    revokeDialogRef.value?.close();
    await announce(formatError(error), { error: true });
  }
};

const updateInstalledTools = async () => {
  await saveSelection();
};

const restoreFlow = () => {
  const flow = getCatalogFlow(accountId.value, providerKey.value);
  if (!flow) return;

  selectedKeys.value = Array.isArray(flow.selectedKeys)
    ? flow.selectedKeys
    : [];
  configurations.value = flow.configurations || {};
};

const handleOAuthReturn = async () => {
  const installationId = route.query.installation_id;
  if (!installationId) return;

  const installation = await store.dispatch(
    'captainToolCatalog/showInstallation',
    installationId
  );
  if (installation.provider_key !== providerKey.value) {
    throw new Error('provider_mismatch');
  }
  await store.dispatch('captainToolCatalog/show', providerKey.value);
  await router.replace({
    name: 'captain_tools_catalog_provider',
    params: route.params,
  });

  if (installation.workflow_kind === 'connect') {
    await loadSetupOptions();
    await announce(t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CONNECT_SUCCESS'));
    return;
  }

  clearCatalogFlow(accountId.value, providerKey.value);
  resetSelection();
  installationComplete.value =
    installation.status === 'completed' &&
    installation.resulting_tool_ids.length > 0;
  useTrack(
    installation.status === 'completed'
      ? CAPTAIN_TOOL_CATALOG_EVENTS.WORKFLOW_COMPLETED
      : CAPTAIN_TOOL_CATALOG_EVENTS.WORKFLOW_FAILED,
    {
      provider: providerKey.value,
      workflow: installation.workflow_kind,
      templateCount: installation.resulting_tool_ids.length,
    }
  );
  await announce(
    installation.status === 'completed'
      ? t('CAPTAIN.CUSTOM_TOOLS.CATALOG.WORKFLOW_SUCCESS')
      : t('CAPTAIN.CUSTOM_TOOLS.CATALOG.WORKFLOW_INCOMPLETE'),
    { error: installation.status !== 'completed' }
  );
};

onMounted(async () => {
  if (!isAdmin.value) {
    await router.replace({ name: 'captain_tools_index', params: route.params });
    return;
  }
  try {
    await store.dispatch('captainToolCatalog/show', providerKey.value);
    useTrack(CAPTAIN_TOOL_CATALOG_EVENTS.PROVIDER_VIEWED, {
      provider: providerKey.value,
      source: route.query.installation_id ? 'oauth_return' : 'direct',
    });
    if (
      providerKey.value === 'shopify' &&
      providerDetails.value.connection.display_name
    ) {
      shopDomain.value = providerDetails.value.connection.display_name;
    }
    resetSelection();
    restoreFlow();
    await handleOAuthReturn();
    await loadSetupOptions();
  } catch (error) {
    await announce(formatError(error), { error: true });
  }
});
</script>

<template>
  <PageLayout
    :header-title="providerDetails?.name || $t('CAPTAIN.CUSTOM_TOOLS.HEADER')"
    :back-url="backUrl"
    :is-fetching="false"
    :is-empty="false"
    :show-pagination-footer="false"
  >
    <template #body>
      <div v-if="isFetching" class="flex justify-center py-12">
        <Spinner />
      </div>
      <div v-else-if="providerDetails" class="flex flex-col gap-6 pb-10">
        <section
          class="flex flex-col gap-5 rounded-xl border border-n-weak bg-n-solid-1 p-5 sm:flex-row sm:items-start"
        >
          <ProviderIcon
            :provider-key="providerDetails.key"
            :provider-name="providerDetails.name"
          />
          <div class="min-w-0 flex-1">
            <div class="flex flex-wrap items-center gap-2">
              <h1 class="text-lg font-medium text-n-slate-12">
                {{ providerDetails.name }}
              </h1>
              <span
                class="rounded-md px-2 py-0.5 text-xs"
                :class="
                  providerDetails.connection.connected
                    ? 'bg-n-teal-3 text-n-teal-11'
                    : 'bg-n-alpha-2 text-n-slate-11'
                "
              >
                {{
                  providerDetails.connection.connected
                    ? $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CONNECTED')
                    : $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.NOT_CONNECTED')
                }}
              </span>
            </div>
            <p class="mt-1 text-sm leading-5 text-n-slate-11">
              {{ providerDetails.description }}
            </p>
            <p
              v-if="providerDetails.connection.display_name"
              class="mt-2 text-sm text-n-slate-10"
            >
              {{ providerDetails.connection.display_name }}
            </p>
          </div>
          <div
            class="rounded-lg bg-n-alpha-1 px-4 py-3 text-sm sm:sticky sm:top-4 sm:text-right"
          >
            <p class="text-n-slate-10">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CAPACITY') }}
            </p>
            <p class="font-medium text-n-slate-12">
              {{
                $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CAPACITY_SUMMARY', {
                  used: projectedCapacity,
                  limit: capacity.limit,
                })
              }}
            </p>
          </div>
        </section>

        <section
          v-if="!credentialsEncrypted"
          class="rounded-xl border border-n-amber-7 bg-n-amber-2 p-5"
        >
          <h2 class="font-medium text-n-slate-12">
            {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.PLAINTEXT_STORAGE_TITLE') }}
          </h2>
          <p class="mt-1 text-sm text-n-slate-11">
            {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.PLAINTEXT_STORAGE_NOTICE') }}
          </p>
        </section>

        <div
          ref="statusRef"
          tabindex="-1"
          role="status"
          aria-live="polite"
          class="outline-none"
        >
          <div
            v-if="statusMessage"
            class="rounded-lg bg-n-teal-3 p-4 text-sm text-n-teal-11"
          >
            <p>{{ statusMessage }}</p>
            <router-link
              v-if="installationComplete"
              :to="playgroundUrl"
              class="mt-2 inline-block font-medium underline"
            >
              {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.TRY_PLAYGROUND') }}
            </router-link>
          </div>
          <p
            v-if="errorMessage"
            role="alert"
            class="rounded-lg bg-n-ruby-3 p-4 text-sm text-n-ruby-11"
          >
            {{ errorMessage }}
          </p>
        </div>

        <section
          v-if="providerDetails.connection.connected"
          class="flex flex-col gap-4 rounded-xl border border-n-weak bg-n-solid-1 p-5"
        >
          <div>
            <h2 class="font-medium text-n-slate-12">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.MANAGE_CONNECTION') }}
            </h2>
            <p class="mt-1 text-sm text-n-slate-10">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.MANAGE_CONNECTION_NOTICE') }}
            </p>
          </div>
          <Input
            v-if="providerKey === 'stripe' && isChangingStripeKey"
            v-model="stripeCredential"
            type="password"
            autocomplete="new-password"
            :label="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.STRIPE_KEY_LABEL')"
            :message="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.STRIPE_KEY_HELP')"
          />
          <div class="flex flex-wrap gap-3">
            <Button
              v-if="providerDetails.installed_count"
              outline
              slate
              :label="
                providerKey === 'stripe' && isChangingStripeKey
                  ? $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SAVE_NEW_KEY')
                  : changeConnectionLabel
              "
              :is-loading="isMutating"
              :disabled="
                providerKey === 'stripe' &&
                isChangingStripeKey &&
                !stripeCredential.trim()
              "
              @click="
                providerKey === 'stripe' && isChangingStripeKey
                  ? reconnect()
                  : changeConnection()
              "
            />
            <Button
              outline
              ruby
              :label="revokeConnectionLabel"
              :disabled="isMutating"
              @click="openRevokeDialog"
            />
          </div>
        </section>

        <section
          v-if="
            providerDetails.installed_count &&
            !providerDetails.connection.connected
          "
          class="flex flex-col gap-3 rounded-xl border border-n-amber-7 bg-n-amber-2 p-5 sm:flex-row sm:items-center sm:justify-between"
        >
          <div>
            <h2 class="font-medium text-n-slate-12">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.RECONNECT_REQUIRED') }}
            </h2>
            <p class="mt-1 text-sm text-n-slate-11">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.RECONNECT_NOTICE') }}
            </p>
          </div>
          <Button
            :label="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.RECONNECT')"
            :is-loading="isMutating"
            :disabled="providerKey === 'stripe' && !stripeCredential.trim()"
            @click="reconnect"
          />
        </section>

        <section
          v-if="updates.length"
          class="flex flex-col gap-3 rounded-xl border border-n-blue-7 bg-n-blue-2 p-5 sm:flex-row sm:items-center sm:justify-between"
        >
          <p class="text-sm text-n-slate-11">
            {{
              $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.UPDATE_NOTICE', updates.length)
            }}
          </p>
          <Button
            :label="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.UPDATE_TOOLS')"
            :is-loading="isMutating"
            @click="updateInstalledTools"
          />
        </section>

        <section
          v-if="providerKey === 'stripe' && stripeRequiresCredential"
          class="rounded-xl border border-n-weak bg-n-solid-1 p-5"
        >
          <Input
            v-model="stripeCredential"
            type="password"
            autocomplete="new-password"
            :label="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.STRIPE_KEY_LABEL')"
            :message="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.STRIPE_KEY_HELP')"
          />
        </section>

        <section
          v-if="providerKey === 'shopify' && requiresConnection"
          class="rounded-xl border border-n-weak bg-n-solid-1 p-5"
        >
          <Input
            v-model="shopDomain"
            autocomplete="url"
            :label="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SHOPIFY_DOMAIN_LABEL')"
            :placeholder="
              $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SHOPIFY_DOMAIN_PLACEHOLDER')
            "
            :message="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SHOPIFY_DOMAIN_HELP')"
          />
        </section>

        <div class="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h2 class="font-medium text-n-slate-12">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SELECT_ACTIONS') }}
            </h2>
            <p class="mt-1 text-sm text-n-slate-10">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.RISK_EXPLANATION') }}
            </p>
          </div>
          <Button
            outline
            slate
            :label="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SELECT_STARTER_SET')"
            @click="selectStarterSet"
          />
        </div>

        <fieldset
          v-for="category in providerDetails.categories"
          :key="category.key"
          class="overflow-hidden rounded-xl border border-n-weak bg-n-solid-1"
        >
          <legend class="sr-only">{{ category.name }}</legend>
          <header class="border-b border-n-weak p-5">
            <h2 class="font-medium text-n-slate-12">{{ category.name }}</h2>
            <p class="mt-1 text-sm text-n-slate-10">
              {{ category.description }}
            </p>
          </header>
          <div class="divide-y divide-n-weak">
            <label
              v-for="template in category.templates"
              :key="template.key"
              class="flex cursor-pointer gap-3 p-5"
              :class="{
                'cursor-not-allowed opacity-65':
                  isMutating ||
                  (template.availability !== 'available' &&
                    !template.installed),
              }"
            >
              <input
                type="checkbox"
                class="mt-0.5 size-4 rounded border-n-slate-6 text-n-brand focus:ring-n-brand"
                :checked="selectedKeys.includes(template.key)"
                :disabled="
                  isMutating ||
                  (template.availability !== 'available' && !template.installed)
                "
                @change="toggleTemplate(template, $event.target.checked)"
              />
              <span class="min-w-0 flex-1">
                <span class="flex flex-wrap items-center gap-2">
                  <span class="text-sm font-medium text-n-slate-12">
                    {{ template.name }}
                  </span>
                  <span
                    class="rounded-md bg-n-alpha-2 px-2 py-0.5 text-xs text-n-slate-11"
                  >
                    {{ riskLabel(template.risk_class) }}
                  </span>
                  <span
                    class="rounded-md px-2 py-0.5 text-xs"
                    :class="
                      template.installed
                        ? 'bg-n-teal-3 text-n-teal-11'
                        : 'bg-n-alpha-2 text-n-slate-11'
                    "
                  >
                    {{ availabilityLabel(template) }}
                  </span>
                </span>
                <span class="mt-1 block text-sm leading-5 text-n-slate-10">
                  {{ template.description }}
                </span>
                <details class="mt-3 text-sm text-n-slate-10" @click.stop>
                  <summary class="cursor-pointer text-n-slate-11">
                    {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.HOW_THIS_WORKS') }}
                  </summary>
                  <span
                    class="mt-2 flex flex-col gap-1 rounded-lg bg-n-alpha-1 p-3"
                  >
                    <span>
                      {{
                        $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SCOPES_LIST', {
                          scopes:
                            template.required_scopes.join(', ') ||
                            $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.NONE'),
                        })
                      }}
                    </span>
                    <span>
                      {{
                        $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.OPERATIONS_LIST', {
                          operations: template.operation_keys.join(', '),
                        })
                      }}
                    </span>
                  </span>
                </details>
              </span>
            </label>
          </div>
        </fieldset>

        <section
          v-if="requiresSlackChannel && providerDetails.connection.connected"
          class="rounded-xl border border-n-weak bg-n-solid-1 p-5"
        >
          <h2 class="font-medium text-n-slate-12">
            {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.FIXED_BINDINGS') }}
          </h2>
          <p class="mb-3 mt-1 text-sm text-n-slate-10">
            {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SLACK_CHANNEL_HELP') }}
          </p>
          <Select
            :model-value="
              configurationValue('send_message_to_channel', 'channel_id')
            "
            :options="channelOptions"
            :disabled="isFetchingSetup"
            :placeholder="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SELECT_CHANNEL')"
            :aria-label="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SELECT_CHANNEL')"
            @update:model-value="setSlackChannel"
          />
        </section>

        <section
          v-if="requiresLinearProject && providerDetails.connection.connected"
          class="rounded-xl border border-n-weak bg-n-solid-1 p-5"
        >
          <h2 class="font-medium text-n-slate-12">
            {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.FIXED_BINDINGS') }}
          </h2>
          <p class="mb-3 mt-1 text-sm text-n-slate-10">
            {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.LINEAR_PROJECT_HELP') }}
          </p>
          <div class="flex flex-col gap-3 sm:flex-row">
            <Select
              :model-value="
                configurationValue('create_issue_from_conversation', 'team_id')
              "
              :options="teamOptions"
              :disabled="isFetchingSetup"
              :placeholder="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SELECT_TEAM')"
              :aria-label="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SELECT_TEAM')"
              @update:model-value="selectLinearTeam"
            />
            <Select
              :model-value="
                configurationValue(
                  'create_issue_from_conversation',
                  'project_id'
                )
              "
              :options="projectOptions"
              :disabled="isFetchingSetup || !projectOptions.length"
              :placeholder="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SELECT_PROJECT')"
              :aria-label="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SELECT_PROJECT')"
              @update:model-value="
                value =>
                  setConfiguration(
                    'create_issue_from_conversation',
                    'project_id',
                    value
                  )
              "
            />
          </div>
        </section>

        <section
          class="sticky bottom-0 flex flex-col gap-3 rounded-xl border border-n-weak bg-n-solid-1 p-5 shadow-lg sm:flex-row sm:items-center sm:justify-between"
        >
          <div class="text-sm">
            <p class="font-medium text-n-slate-12">
              {{
                $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SELECTION_SUMMARY', {
                  count: selectedCount,
                  used: projectedCapacity,
                  limit: capacity.limit,
                })
              }}
            </p>
            <p v-if="scopes.length" class="mt-1 text-n-slate-10">
              {{
                $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SCOPES_LIST', {
                  scopes: scopes.join(', '),
                })
              }}
            </p>
            <p v-if="!hasCapacity" class="mt-1 text-n-ruby-10">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CAPACITY_ERROR') }}
            </p>
          </div>
          <Button
            :label="
              requiresConnection
                ? $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CONNECT_AND_CONTINUE')
                : providerDetails.installed_count
                  ? $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SAVE_CHANGES')
                  : $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.INSTALL_SELECTED')
            "
            :is-loading="isMutating"
            :disabled="!canContinue"
            @click="saveSelection"
          />
        </section>
      </div>
    </template>
  </PageLayout>
  <Dialog
    ref="revokeDialogRef"
    type="alert"
    :title="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.REVOKE_CONFIRM_TITLE')"
    :description="revokeConfirmationNotice"
    :confirm-button-label="revokeConnectionLabel"
    :is-loading="isMutating"
    @confirm="revokeConnection"
  />
</template>
