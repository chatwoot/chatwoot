<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import McpServersAPI from 'dashboard/api/captain/mcpServers';

import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import McpStepper from './McpStepper.vue';
import McpToolsStep from './McpToolsStep.vue';
import McpParametersStep from './McpParametersStep.vue';
import McpReviewStep from './McpReviewStep.vue';
import { PARAM_SOURCES } from './mcpTools';

const props = defineProps({
  assistantId: { type: [String, Number], required: true },
});

const emit = defineEmits(['saved']);

const { t } = useI18n();

const STEPS = ['TOOLS', 'PARAMETERS', 'REVIEW'];

const panelRef = ref(null);
const step = ref('TOOLS');
const server = ref(null);
const liveTools = ref([]);
// Approved tools the server no longer lists
const missingTools = ref([]);
const isBusy = ref(false);
const isLoadingTools = ref(false);
// Saving after a failed load would send an empty list and remove every approved tool
const toolsLoadFailed = ref(false);
// Selections by tool name: whether the tool is selected, its parameter sources, and its verification setting
const selections = reactive({});

const approvedTool = name =>
  server.value?.tools.find(tool => tool.name === name);

// An approved tool keeps its approved schema. A new tool uses the live one.
const toolSchema = tool =>
  approvedTool(tool.name)?.input_schema || tool.input_schema;
const toolDigest = tool =>
  approvedTool(tool.name)?.approved_digest || tool.digest;

const selectedTools = computed(() =>
  liveTools.value.filter(tool => selections[tool.name]?.selected)
);
const selectedNames = computed(() =>
  selectedTools.value.map(tool => tool.name)
);

const buildSelections = () => {
  liveTools.value.forEach(tool => {
    const approved = approvedTool(tool.name);
    selections[tool.name] = {
      selected: !!approved,
      paramSources: { ...(approved?.param_sources || {}) },
      settings: {
        requires_email_verification:
          approved?.settings?.requires_email_verification === true,
      },
    };
  });
};

const loadTools = async () => {
  isLoadingTools.value = true;
  toolsLoadFailed.value = false;
  try {
    const { data } = await McpServersAPI.liveTools({
      id: server.value.id,
      assistantId: props.assistantId,
    });
    liveTools.value = data.payload;
    missingTools.value = data.missing;
    buildSelections();
  } catch (error) {
    toolsLoadFailed.value = true;
    useAlert(
      parseAPIErrorResponse(error) ||
        t('CAPTAIN.MCP_SERVERS.DIALOG.TOOLS_ERROR')
    );
  } finally {
    isLoadingTools.value = false;
  }
};

const currentStepIndex = computed(() => STEPS.indexOf(step.value));

const open = existingServer => {
  step.value = 'TOOLS';
  server.value = existingServer;
  liveTools.value = [];
  missingTools.value = [];
  Object.keys(selections).forEach(name => delete selections[name]);
  loadTools();
  panelRef.value.open();
};

const close = () => panelRef.value.close();

const runBusy = async (action, fallbackKey) => {
  isBusy.value = true;
  try {
    return await action();
  } catch (error) {
    useAlert(parseAPIErrorResponse(error) || t(fallbackKey));
    return null;
  } finally {
    isBusy.value = false;
  }
};

const updateSource = (tool, param, source) => {
  const sources = selections[tool.name].paramSources;
  if (source === PARAM_SOURCES.MODEL) {
    delete sources[param.name];
    return;
  }
  sources[param.name] =
    source === PARAM_SOURCES.FIXED
      ? { source, value: sources[param.name]?.value || '' }
      : { source };
};

const updateFixedValue = (tool, param, value) => {
  selections[tool.name].paramSources[param.name] = {
    source: PARAM_SOURCES.FIXED,
    value,
  };
};

const setRequiresVerification = (tool, value) => {
  selections[tool.name].settings.requires_email_verification = value;
};

const missingFixedValue = () => {
  const tool = selectedTools.value.find(item =>
    Object.values(selections[item.name].paramSources).some(
      entry => entry.source === PARAM_SOURCES.FIXED && !entry.value?.trim()
    )
  );
  if (!tool) return null;
  const param = Object.entries(selections[tool.name].paramSources).find(
    ([, entry]) => entry.source === PARAM_SOURCES.FIXED && !entry.value?.trim()
  )[0];
  return { tool: tool.name, param };
};

const goToReview = () => {
  const missing = missingFixedValue();
  if (missing) {
    useAlert(t('CAPTAIN.MCP_SERVERS.DIALOG.FIXED_VALUE_MISSING', missing));
    return;
  }
  step.value = 'REVIEW';
};

const save = () =>
  runBusy(async () => {
    await McpServersAPI.update(server.value.id, {
      assistantId: props.assistantId,
      tools: selectedTools.value.map(tool => ({
        name: tool.name,
        enabled: approvedTool(tool.name)?.enabled ?? true,
        param_sources: selections[tool.name].paramSources,
        settings: selections[tool.name].settings,
      })),
    });
    useAlert(t('CAPTAIN.MCP_SERVERS.DIALOG.SAVED'));
    emit('saved');
    close();
  }, 'CAPTAIN.MCP_SERVERS.DIALOG.SAVE_ERROR');

const approveChange = tool =>
  runBusy(async () => {
    const { data } = await McpServersAPI.approveTool({
      id: server.value.id,
      assistantId: props.assistantId,
      name: tool.name,
    });
    server.value = data;
    useAlert(t('CAPTAIN.MCP_SERVERS.DIALOG.CHANGE_APPROVED'));
    emit('saved');
    await loadTools();
  }, 'CAPTAIN.MCP_SERVERS.DIALOG.APPROVE_ERROR');

const toggleTool = (name, selected) => {
  selections[name].selected = selected;
};

const selectAllReadTools = selected => {
  liveTools.value
    .filter(tool => tool.read_only)
    .forEach(tool => {
      selections[tool.name].selected = selected;
    });
};

// The main action names what happens next
const primaryAction = computed(() => {
  if (step.value === 'TOOLS') {
    return {
      label: t('CAPTAIN.MCP_SERVERS.DIALOG.CONTINUE'),
      disabled: isLoadingTools.value || toolsLoadFailed.value,
      run: () => {
        step.value = 'PARAMETERS';
      },
    };
  }
  if (step.value === 'PARAMETERS') {
    return {
      label: t('CAPTAIN.MCP_SERVERS.DIALOG.ACTIONS.REVIEW'),
      run: goToReview,
    };
  }
  return {
    label: t('CAPTAIN.MCP_SERVERS.DIALOG.ACTIONS.SAVE', {
      n: selectedTools.value.length,
    }),
    run: save,
  };
});

const back = () => {
  step.value = STEPS[currentStepIndex.value - 1];
};

defineExpose({ open });
</script>

<template>
  <SidePanel
    ref="panelRef"
    width="2xl"
    :title="
      t('CAPTAIN.MCP_SERVERS.DIALOG.MANAGE_TITLE', { name: server?.name })
    "
    :close-on-click-outside="false"
  >
    <div class="flex flex-col gap-8">
      <McpStepper :steps="STEPS" :current="currentStepIndex" />

      <McpToolsStep
        v-if="step === 'TOOLS'"
        :tools="liveTools"
        :selected-names="selectedNames"
        :approved-tools="server?.tools || []"
        :missing-tools="missingTools"
        :is-loading="isLoadingTools"
        :load-failed="toolsLoadFailed"
        :is-busy="isBusy"
        @toggle="toggleTool"
        @select-all="selectAllReadTools"
        @approve="approveChange"
      />

      <McpParametersStep
        v-else-if="step === 'PARAMETERS'"
        :tools="selectedTools"
        :selections="selections"
        :tool-schema="toolSchema"
        @update-source="updateSource"
        @update-fixed-value="updateFixedValue"
        @set-verification="setRequiresVerification"
      />

      <McpReviewStep
        v-else
        :server-name="server?.name || ''"
        :server-url="server?.url || ''"
        :auth-type="server?.auth_type"
        :tools="selectedTools"
        :selections="selections"
        :tool-schema="toolSchema"
        :tool-digest="toolDigest"
      />
    </div>

    <template #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          v-if="currentStepIndex > 0"
          ghost
          slate
          icon="i-lucide-arrow-left"
          :label="t('CAPTAIN.MCP_SERVERS.DIALOG.BACK')"
          :disabled="isBusy"
          @click="back"
        />
        <span v-else />
        <Button
          :label="primaryAction.label"
          :is-loading="isBusy && step !== 'TOOLS'"
          :disabled="primaryAction.disabled || isBusy"
          @click="primaryAction.run"
        />
      </div>
    </template>
  </SidePanel>
</template>
