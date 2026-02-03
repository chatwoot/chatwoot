<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, url } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  mode: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
  server: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainMcpServers/getUIFlags'),
};

const initialState = {
  name: '',
  description: '',
  url: '',
  auth_type: 'none',
  auth_config: {},
  transport: 'auto',
  rpc_endpoint: '',
  enabled: true,
};

const state = reactive({ ...initialState });

watch(
  () => props.server,
  newServer => {
    if (props.mode === 'edit' && newServer && newServer.id) {
      state.name = newServer.name || '';
      state.description = newServer.description || '';
      state.url = newServer.url || '';
      state.auth_type = newServer.auth_type || 'none';
      state.auth_config = newServer.auth_config || {};
      state.transport = newServer.auth_config?.transport || 'auto';
      state.rpc_endpoint = newServer.auth_config?.rpc_endpoint || '';
      state.enabled = newServer.enabled ?? true;
    }
  },
  { immediate: true }
);

const validationRules = {
  name: { required },
  url: { required, url },
  auth_type: { required },
};

const authTypeOptions = computed(() => [
  { value: 'none', label: t('CAPTAIN_SETTINGS.MCP_SERVERS.AUTH_TYPES.NONE') },
  {
    value: 'bearer',
    label: t('CAPTAIN_SETTINGS.MCP_SERVERS.AUTH_TYPES.BEARER'),
  },
  {
    value: 'api_key',
    label: t('CAPTAIN_SETTINGS.MCP_SERVERS.AUTH_TYPES.API_KEY'),
  },
]);

const transportOptions = computed(() => [
  {
    value: 'auto',
    label: t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.TRANSPORT.AUTO'),
  },
  {
    value: 'streamable_http',
    label: t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.TRANSPORT.STREAMABLE_HTTP'),
  },
  {
    value: 'sse',
    label: t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.TRANSPORT.SSE'),
  },
  {
    value: 'http',
    label: t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.TRANSPORT.HTTP'),
  },
]);

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() =>
  props.mode === 'edit'
    ? formState.uiFlags.value.updatingItem
    : formState.uiFlags.value.creatingItem
);

const getErrorMessage = field => {
  if (!v$.value[field].$error) return '';

  const errors = v$.value[field].$errors;
  if (errors.length === 0) return '';

  const firstError = errors[0].$validator;

  const errorMessages = {
    name: {
      required: t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.NAME.ERROR'),
    },
    url: {
      required: t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.URL.ERROR'),
      url: t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.URL.INVALID'),
    },
  };

  return (
    errorMessages[field]?.[firstError] ||
    t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.GENERIC_ERROR')
  );
};

const formErrors = computed(() => ({
  name: getErrorMessage('name'),
  url: getErrorMessage('url'),
  rpc_endpoint: '',
}));

const handleAuthConfigChange = (key, value) => {
  state.auth_config = { ...state.auth_config, [key]: value };
};

const handleCancel = () => emit('cancel');

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  const submitData = {
    name: state.name,
    description: state.description,
    url: state.url,
    auth_type: state.auth_type,
    enabled: state.enabled,
  };

  const authConfig = {
    transport: state.transport,
  };

  if (state.rpc_endpoint) {
    authConfig.rpc_endpoint = state.rpc_endpoint;
  }

  if (state.auth_type !== 'none') {
    Object.assign(authConfig, state.auth_config);
  }

  if (Object.keys(authConfig).length > 0) {
    submitData.auth_config = authConfig;
  }

  emit('submit', submitData);
};
</script>

<template>
  <form
    class="flex flex-col px-4 -mx-4 gap-4 max-h-[calc(100vh-200px)] overflow-y-scroll"
    @submit.prevent="handleSubmit"
  >
    <Input
      v-model="state.name"
      :label="t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.NAME.LABEL')"
      :placeholder="t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.NAME.PLACEHOLDER')"
      :message="formErrors.name"
      :message-type="formErrors.name ? 'error' : ''"
    />

    <TextArea
      v-model="state.description"
      :label="t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.DESCRIPTION.LABEL')"
      :placeholder="
        t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.DESCRIPTION.PLACEHOLDER')
      "
      rows="2"
    />

    <div
      class="flex items-center justify-between gap-4 rounded-lg border border-n-slate-6 bg-n-slate-2 p-3"
    >
      <div class="flex flex-col gap-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.ENABLED.LABEL') }}
        </span>
        <span class="text-xs text-n-slate-10">
          {{ t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.ENABLED.HINT') }}
        </span>
      </div>
      <Switch v-model="state.enabled" />
    </div>

    <Input
      v-model="state.url"
      :label="t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.URL.LABEL')"
      :placeholder="t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.URL.PLACEHOLDER')"
      :message="formErrors.url"
      :message-type="formErrors.url ? 'error' : ''"
    >
      <template #message>
        <span v-if="!formErrors.url" class="text-xs text-n-slate-10">
          {{ t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.URL.HINT') }}
        </span>
      </template>
    </Input>

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.TRANSPORT.LABEL') }}
      </label>
      <ComboBox
        v-model="state.transport"
        :options="transportOptions"
        :placeholder="
          t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.TRANSPORT.PLACEHOLDER')
        "
      />
    </div>

    <Input
      v-model="state.rpc_endpoint"
      :label="t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.RPC_ENDPOINT.LABEL')"
      :placeholder="
        t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.RPC_ENDPOINT.PLACEHOLDER')
      "
      :message="formErrors.rpc_endpoint"
      :message-type="formErrors.rpc_endpoint ? 'error' : ''"
    >
      <template #message>
        <span v-if="!formErrors.rpc_endpoint" class="text-xs text-n-slate-10">
          {{ t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.RPC_ENDPOINT.HINT') }}
        </span>
      </template>
    </Input>

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.AUTH_TYPE.LABEL') }}
      </label>
      <ComboBox
        v-model="state.auth_type"
        :options="authTypeOptions"
        :placeholder="
          t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.AUTH_TYPE.PLACEHOLDER')
        "
      />
    </div>

    <!-- Bearer Token Auth -->
    <div
      v-if="state.auth_type === 'bearer'"
      class="flex flex-col gap-4 p-4 rounded-lg bg-n-slate-2 border border-n-slate-6"
    >
      <Input
        :model-value="state.auth_config.token || ''"
        type="password"
        :label="
          t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.AUTH_CONFIG.BEARER_TOKEN.LABEL')
        "
        :placeholder="
          t(
            'CAPTAIN_SETTINGS.MCP_SERVERS.FORM.AUTH_CONFIG.BEARER_TOKEN.PLACEHOLDER'
          )
        "
        @update:model-value="handleAuthConfigChange('token', $event)"
      />
    </div>

    <!-- API Key Auth -->
    <div
      v-if="state.auth_type === 'api_key'"
      class="flex flex-col gap-4 p-4 rounded-lg bg-n-slate-2 border border-n-slate-6"
    >
      <Input
        :model-value="state.auth_config.header_name || ''"
        :label="
          t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.AUTH_CONFIG.HEADER_NAME.LABEL')
        "
        :placeholder="
          t(
            'CAPTAIN_SETTINGS.MCP_SERVERS.FORM.AUTH_CONFIG.HEADER_NAME.PLACEHOLDER'
          )
        "
        @update:model-value="handleAuthConfigChange('header_name', $event)"
      />
      <Input
        :model-value="state.auth_config.key || ''"
        type="password"
        :label="
          t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.AUTH_CONFIG.API_KEY.LABEL')
        "
        :placeholder="
          t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.AUTH_CONFIG.API_KEY.PLACEHOLDER')
        "
        @update:model-value="handleAuthConfigChange('key', $event)"
      />
    </div>

    <div class="flex justify-end gap-2 pt-4 mt-2 border-t border-n-slate-6">
      <Button
        type="button"
        color="slate"
        variant="faded"
        :label="t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.CANCEL')"
        @click="handleCancel"
      />
      <Button
        type="submit"
        color="blue"
        :label="
          mode === 'edit'
            ? t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.UPDATE')
            : t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.CREATE')
        "
        :is-loading="isLoading"
      />
    </div>
  </form>
</template>
