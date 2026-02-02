<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainAssistantMcpServers/getUIFlags'),
  assistantMcpServers: useMapGetter('captainAssistantMcpServers/getRecords'),
  mcpServers: useMapGetter('captainMcpServers/getRecords'),
};

const initialState = {
  mcpServerId: null,
  selectedTools: [],
};

const state = reactive({ ...initialState });

const validationRules = {
  mcpServerId: { required },
};

const availableServers = computed(() => {
  const attachedIds = formState.assistantMcpServers.value.map(
    record => record.captain_mcp_server_id
  );

  return formState.mcpServers.value
    .filter(server => !attachedIds.includes(server.id))
    .map(server => ({
      value: server.id,
      label: server.name,
    }));
});

const selectedServer = computed(() => {
  return formState.mcpServers.value.find(
    server => server.id === state.mcpServerId
  );
});

const availableTools = computed(() => {
  return selectedServer.value?.cached_tools || [];
});

const toolNames = computed(() => availableTools.value.map(tool => tool.name));

const allToolsSelected = computed(
  () =>
    toolNames.value.length > 0 &&
    state.selectedTools.length === toolNames.value.length
);

const isIndeterminate = computed(
  () =>
    state.selectedTools.length > 0 &&
    state.selectedTools.length < toolNames.value.length
);

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const formErrors = computed(() => ({
  mcpServerId: v$.value.mcpServerId.$error
    ? t('CAPTAIN.MCP_SERVERS.FORM.MCP_SERVER.ERROR')
    : '',
}));

const handleCancel = () => emit('cancel');

const toggleAllTools = () => {
  if (allToolsSelected.value) {
    state.selectedTools = [];
  } else {
    state.selectedTools = [...toolNames.value];
  }
};

const toggleTool = toolName => {
  if (state.selectedTools.includes(toolName)) {
    state.selectedTools = state.selectedTools.filter(name => name !== toolName);
  } else {
    state.selectedTools = [...state.selectedTools, toolName];
  }
};

const buildToolFilters = () => {
  if (!toolNames.value.length) return {};
  if (allToolsSelected.value) return {};
  if (!state.selectedTools.length) {
    return { exclude: toolNames.value };
  }
  return { include: state.selectedTools };
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', {
    mcpServerId: state.mcpServerId,
    toolFilters: buildToolFilters(),
  });
};

watch(
  () => state.mcpServerId,
  () => {
    state.selectedTools = [...toolNames.value];
  }
);
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <div class="flex flex-col gap-1">
      <label
        for="mcp-server"
        class="mb-0.5 text-sm font-medium text-n-slate-12"
      >
        {{ t('CAPTAIN.MCP_SERVERS.FORM.MCP_SERVER.LABEL') }}
      </label>
      <ComboBox
        id="mcp-server"
        v-model="state.mcpServerId"
        :options="availableServers"
        :has-error="!!formErrors.mcpServerId"
        :placeholder="t('CAPTAIN.MCP_SERVERS.FORM.MCP_SERVER.PLACEHOLDER')"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
        :message="formErrors.mcpServerId"
      />
    </div>

    <div class="flex flex-col gap-2">
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN.MCP_SERVERS.TOOLS.TITLE') }}
        </span>
        <div class="flex items-center gap-2">
          <Checkbox
            :model-value="allToolsSelected"
            :indeterminate="isIndeterminate"
            :disabled="!toolNames.length"
            @change="toggleAllTools"
          />
          <span class="text-xs text-n-slate-11">
            {{ t('CAPTAIN.MCP_SERVERS.TOOLS.SELECT_ALL') }}
          </span>
        </div>
      </div>

      <p class="text-xs text-n-slate-10">
        {{ t('CAPTAIN.MCP_SERVERS.TOOLS.DESCRIPTION') }}
      </p>

      <div
        v-if="!toolNames.length"
        class="rounded-lg border border-n-container bg-n-solid-2 p-3 text-xs text-n-slate-11"
      >
        {{ t('CAPTAIN.MCP_SERVERS.TOOLS.EMPTY') }}
      </div>

      <div v-else class="flex flex-col gap-2">
        <div
          v-for="tool in availableTools"
          :key="tool.name"
          class="flex items-start gap-3 rounded-lg border border-n-container bg-n-solid-2 p-3"
        >
          <div class="pt-0.5">
            <Checkbox
              :model-value="state.selectedTools.includes(tool.name)"
              @change="toggleTool(tool.name)"
            />
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs font-medium text-n-slate-12">
              {{ tool.name }}
            </span>
            <span v-if="tool.description" class="text-xs text-n-slate-10">
              {{ tool.description }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <div class="flex items-center justify-between w-full gap-3">
      <Button
        type="button"
        variant="faded"
        color="slate"
        :label="t('CAPTAIN.FORM.CANCEL')"
        class="w-full bg-n-alpha-2 text-n-blue-11 hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        type="submit"
        :label="t('CAPTAIN.FORM.CREATE')"
        class="w-full"
        :is-loading="isLoading"
        :disabled="isLoading"
      />
    </div>
  </form>
</template>
