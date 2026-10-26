<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import McpServersAPI from 'dashboard/api/captain/mcpServers';

import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import McpParamRow from './McpParamRow.vue';
import {
  PARAM_SOURCES,
  fingerprintLabel,
  schemaParams,
  sourceOf,
  usesVerifiedEmail,
  requiresVerification,
} from './mcpTools';

const props = defineProps({
  assistantId: { type: [String, Number], required: true },
});

const emit = defineEmits(['saved']);

const { t } = useI18n();

const STEPS = ['SERVER', 'TOOLS', 'PARAMETERS', 'REVIEW'];
const AUTH_TYPES = { NONE: 'none', OAUTH: 'oauth', TOKEN: 'token' };

const dialogRef = ref(null);
const step = ref('SERVER');
const server = ref(null);
const url = ref('');
const discovery = ref(null);
const authType = ref(AUTH_TYPES.NONE);
const token = ref('');
const authHeader = ref('');
const showHeaderField = ref(false);
const liveTools = ref([]);
const isBusy = ref(false);
const isLoadingTools = ref(false);
// Saving after a failed load would send an empty list and remove every approved tool
const toolsLoadFailed = ref(false);
// Selections by tool name: whether the tool is selected, its parameter sources, and its verification setting
const selections = reactive({});

const isConnecting = computed(() => !server.value?.id);
const title = computed(() =>
  isConnecting.value
    ? t('CAPTAIN.MCP_SERVERS.DIALOG.CONNECT_TITLE')
    : t('CAPTAIN.MCP_SERVERS.DIALOG.MANAGE_TITLE', { name: server.value.name })
);
const visibleSteps = computed(() =>
  isConnecting.value ? STEPS : STEPS.filter(name => name !== 'SERVER')
);

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

const canContinueFromServer = computed(() => {
  if (!discovery.value) return false;
  if (authType.value === AUTH_TYPES.TOKEN) return !!token.value.trim();
  return true;
});

const resetState = () => {
  step.value = 'SERVER';
  url.value = '';
  discovery.value = null;
  authType.value = AUTH_TYPES.NONE;
  token.value = '';
  authHeader.value = '';
  showHeaderField.value = false;
  liveTools.value = [];
  Object.keys(selections).forEach(name => delete selections[name]);
};

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

const open = existingServer => {
  resetState();
  server.value = existingServer;
  if (existingServer) {
    step.value = 'TOOLS';
    loadTools();
  }
  dialogRef.value.open();
};

const close = () => dialogRef.value.close();

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

const check = () =>
  runBusy(async () => {
    discovery.value = null;
    const { data } = await McpServersAPI.discover({
      assistantId: props.assistantId,
      url: url.value.trim(),
    });
    discovery.value = data;
    authType.value = data.auth_type;
  }, 'CAPTAIN.MCP_SERVERS.DIALOG.CHECK_ERROR');

const startSignIn = async savedServer => {
  const { data } = await McpServersAPI.authorizationUrl({
    id: savedServer.id,
    assistantId: props.assistantId,
  });
  window.location.href = data.url;
};

const connect = () =>
  runBusy(async () => {
    const isToken = authType.value === AUTH_TYPES.TOKEN;
    // A token is checked before the server is saved, so a wrong token never lands in a saved server
    if (isToken) {
      await McpServersAPI.discover({
        assistantId: props.assistantId,
        url: url.value.trim(),
        token: token.value.trim(),
        authHeader: authHeader.value.trim(),
      });
    }
    const { data } = await McpServersAPI.create({
      assistantId: props.assistantId,
      url: url.value.trim(),
      name: discovery.value.name,
      auth_type: authType.value,
      ...(isToken && {
        auth_header: authHeader.value.trim() || null,
        auth_config: { token: token.value.trim() },
      }),
    });
    emit('saved');
    if (authType.value === AUTH_TYPES.OAUTH) {
      await startSignIn(data);
      return;
    }
    server.value = data;
    step.value = 'TOOLS';
    await loadTools();
  }, 'CAPTAIN.MCP_SERVERS.DIALOG.CHECK_ERROR');

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

const toolRequiresVerification = tool =>
  requiresVerification({
    paramSources: selections[tool.name].paramSources,
    settings: selections[tool.name].settings,
  });

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

const sourceSummary = tool =>
  schemaParams(toolSchema(tool))
    .map(param => {
      const entry = selections[tool.name].paramSources[param.name];
      const source = sourceOf(selections[tool.name].paramSources, param.name);
      const label =
        source === PARAM_SOURCES.FIXED
          ? t('CAPTAIN.MCP_SERVERS.DIALOG.SOURCE_SUMMARY.FIXED', {
              value: entry.value,
            })
          : t(
              `CAPTAIN.MCP_SERVERS.DIALOG.SOURCE_SUMMARY.${source === PARAM_SOURCES.VERIFIED_EMAIL ? 'VERIFIED_EMAIL' : 'MODEL'}`
            );
      return `${param.name}: ${label}`;
    })
    .join(', ');

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

const back = () => {
  const index = visibleSteps.value.indexOf(step.value);
  step.value = visibleSteps.value[index - 1];
};

defineExpose({ open });
</script>

<template>
  <SidePanel
    ref="dialogRef"
    width="2xl"
    :title="title"
    :close-on-click-outside="false"
  >
    <ol class="flex flex-wrap gap-1 p-0 m-0 list-none">
      <li
        v-for="(name, index) in visibleSteps"
        :key="name"
        class="text-xs px-2.5 py-1 rounded-full"
        :class="
          name === step
            ? 'bg-n-brand text-white'
            : 'bg-n-alpha-2 text-n-slate-11'
        "
      >
        {{ index + 1 }}. {{ t(`CAPTAIN.MCP_SERVERS.DIALOG.STEPS.${name}`) }}
      </li>
    </ol>

    <div class="flex flex-col gap-4 mt-5">
      <template v-if="step === 'SERVER'">
        <div class="flex items-end gap-2">
          <Input
            v-model="url"
            class="flex-1"
            :label="t('CAPTAIN.MCP_SERVERS.DIALOG.URL_LABEL')"
            :placeholder="t('CAPTAIN.MCP_SERVERS.DIALOG.URL_PLACEHOLDER')"
            :disabled="isBusy"
            @enter="check"
          />
          <Button
            :label="t('CAPTAIN.MCP_SERVERS.DIALOG.CHECK')"
            :is-loading="isBusy && !discovery"
            :disabled="!url.trim() || isBusy"
            @click="check"
          />
        </div>

        <div
          v-if="discovery"
          class="flex flex-col gap-3 p-3 rounded-lg border border-n-weak"
        >
          <div class="flex flex-col gap-0.5">
            <span class="text-xs text-n-slate-11">
              {{ t('CAPTAIN.MCP_SERVERS.DIALOG.SERVER_LABEL') }}
            </span>
            <span class="text-sm font-medium text-n-slate-12">
              {{ discovery.name }}
              <span v-if="discovery.version" class="text-n-slate-11">
                {{
                  t('CAPTAIN.MCP_SERVERS.DIALOG.VERSION', {
                    version: discovery.version,
                  })
                }}
              </span>
            </span>
          </div>

          <div class="flex flex-col gap-1.5">
            <span class="text-xs text-n-slate-11">
              {{ t('CAPTAIN.MCP_SERVERS.DIALOG.SIGN_IN_LABEL') }}
            </span>
            <span
              v-if="authType === AUTH_TYPES.NONE"
              class="text-sm text-n-slate-12"
            >
              {{ t('CAPTAIN.MCP_SERVERS.DIALOG.NO_SIGN_IN') }}
            </span>
            <template v-else-if="authType === AUTH_TYPES.OAUTH">
              <span class="text-sm text-n-slate-12">
                {{ t('CAPTAIN.MCP_SERVERS.DIALOG.OAUTH_NOTE') }}
              </span>
              <button
                type="button"
                class="p-0 text-xs underline text-n-blue-11 text-start"
                @click="authType = AUTH_TYPES.TOKEN"
              >
                {{ t('CAPTAIN.MCP_SERVERS.DIALOG.USE_TOKEN') }}
              </button>
            </template>
            <template v-else>
              <Input
                v-model="token"
                type="password"
                :label="t('CAPTAIN.MCP_SERVERS.DIALOG.TOKEN_LABEL')"
              />
              <Input
                v-if="showHeaderField"
                v-model="authHeader"
                :label="t('CAPTAIN.MCP_SERVERS.DIALOG.HEADER_LABEL')"
                :placeholder="
                  t('CAPTAIN.MCP_SERVERS.DIALOG.HEADER_PLACEHOLDER')
                "
              />
              <span v-else class="text-xs text-n-slate-11">
                {{ t('CAPTAIN.MCP_SERVERS.DIALOG.DEFAULT_HEADER') }}
                <button
                  type="button"
                  class="p-0 underline text-n-blue-11"
                  @click="showHeaderField = true"
                >
                  {{ t('CAPTAIN.MCP_SERVERS.DIALOG.CUSTOM_HEADER') }}
                </button>
              </span>
              <button
                v-if="discovery.auth_type === AUTH_TYPES.OAUTH"
                type="button"
                class="p-0 text-xs underline text-n-blue-11 text-start"
                @click="authType = AUTH_TYPES.OAUTH"
              >
                {{ t('CAPTAIN.MCP_SERVERS.DIALOG.USE_OAUTH') }}
              </button>
            </template>
          </div>

          <p
            v-if="authType !== AUTH_TYPES.NONE"
            class="text-xs mb-0 px-3 py-2 rounded-lg bg-n-alpha-2 text-n-slate-11"
          >
            {{ t('CAPTAIN.MCP_SERVERS.DIALOG.SHARED_CREDENTIAL') }}
          </p>
        </div>
      </template>

      <template v-else-if="step === 'TOOLS'">
        <div class="flex flex-col gap-1">
          <h4 class="text-sm font-medium text-n-slate-12 m-0">
            {{ t('CAPTAIN.MCP_SERVERS.DIALOG.TOOLS_TITLE') }}
          </h4>
          <p class="text-xs text-n-slate-11 mb-0">
            {{ t('CAPTAIN.MCP_SERVERS.DIALOG.TOOLS_DESCRIPTION') }}
          </p>
        </div>
        <div v-if="isLoadingTools" class="flex justify-center py-8">
          <Spinner />
        </div>
        <p v-else-if="toolsLoadFailed" class="text-sm text-n-ruby-11 mb-0">
          {{ t('CAPTAIN.MCP_SERVERS.DIALOG.TOOLS_ERROR') }}
        </p>
        <p v-else-if="!liveTools.length" class="text-sm text-n-slate-11 mb-0">
          {{ t('CAPTAIN.MCP_SERVERS.DIALOG.NO_LIVE_TOOLS') }}
        </p>
        <template v-else>
          <label
            v-for="tool in liveTools"
            :key="tool.name"
            class="flex flex-col gap-2 p-3 rounded-lg border border-n-weak"
            :class="{ 'opacity-60': !tool.read_only }"
          >
            <span class="flex items-center justify-between gap-3">
              <span class="flex items-center gap-2 min-w-0">
                <Checkbox
                  v-model="selections[tool.name].selected"
                  :disabled="!tool.read_only"
                />
                <code class="text-sm text-n-slate-12 truncate">
                  {{ tool.name }}
                </code>
              </span>
              <span class="flex items-center gap-1.5 shrink-0">
                <span
                  v-if="tool.changed"
                  class="text-xs px-2 py-0.5 rounded-full bg-n-amber-3 text-n-amber-11"
                >
                  {{ t('CAPTAIN.MCP_SERVERS.DIALOG.CHANGED') }}
                </span>
                <span
                  class="text-xs px-2 py-0.5 rounded-full"
                  :class="
                    tool.read_only
                      ? 'bg-n-alpha-2 text-n-slate-11'
                      : 'bg-n-amber-3 text-n-amber-11'
                  "
                >
                  {{
                    tool.read_only
                      ? t('CAPTAIN.MCP_SERVERS.DIALOG.READ')
                      : t('CAPTAIN.MCP_SERVERS.DIALOG.WRITE')
                  }}
                </span>
              </span>
            </span>
            <span
              class="flex flex-col gap-0.5 ps-3 border-s-2 border-n-weak text-sm text-n-slate-11"
            >
              <span class="text-xs text-n-slate-10">
                {{ t('CAPTAIN.MCP_SERVERS.DIALOG.WRITTEN_BY_SERVER') }}
              </span>
              {{ tool.description }}
            </span>
            <span v-if="!tool.read_only" class="text-xs text-n-amber-11">
              {{ t('CAPTAIN.MCP_SERVERS.DIALOG.WRITE_BLOCKED') }}
            </span>
          </label>
        </template>
      </template>

      <template v-else-if="step === 'PARAMETERS'">
        <div class="flex flex-col gap-1">
          <h4 class="text-sm font-medium text-n-slate-12 m-0">
            {{ t('CAPTAIN.MCP_SERVERS.DIALOG.PARAMS_TITLE') }}
          </h4>
          <p class="text-xs text-n-slate-11 mb-0">
            {{ t('CAPTAIN.MCP_SERVERS.DIALOG.PARAMS_DESCRIPTION') }}
          </p>
        </div>
        <div
          v-for="tool in selectedTools"
          :key="tool.name"
          class="flex flex-col gap-3 p-3 rounded-lg border border-n-weak"
        >
          <code class="text-sm font-medium text-n-slate-12">
            {{ tool.name }}
          </code>
          <p
            v-if="!schemaParams(toolSchema(tool)).length"
            class="text-sm text-n-slate-11 mb-0"
          >
            {{ t('CAPTAIN.MCP_SERVERS.DIALOG.NO_PARAMS') }}
          </p>
          <McpParamRow
            v-for="param in schemaParams(toolSchema(tool))"
            :key="param.name"
            :param="param"
            :source="sourceOf(selections[tool.name].paramSources, param.name)"
            :fixed-value="
              selections[tool.name].paramSources[param.name]?.value || ''
            "
            :verified-email-taken="
              usesVerifiedEmail(selections[tool.name].paramSources) &&
              sourceOf(selections[tool.name].paramSources, param.name) !==
                PARAM_SOURCES.VERIFIED_EMAIL
            "
            @update:source="updateSource(tool, param, $event)"
            @update:fixed-value="updateFixedValue(tool, param, $event)"
          />
          <div class="flex flex-col gap-1 pt-3 border-t border-n-weak">
            <label class="flex items-center gap-2 text-sm text-n-slate-12">
              <Switch
                :model-value="toolRequiresVerification(tool)"
                :disabled="
                  usesVerifiedEmail(selections[tool.name].paramSources)
                "
                @update:model-value="setRequiresVerification(tool, $event)"
              />
              {{ t('CAPTAIN.MCP_SERVERS.DIALOG.REQUIRE_VERIFICATION') }}
            </label>
            <span
              v-if="usesVerifiedEmail(selections[tool.name].paramSources)"
              class="text-xs text-n-slate-11"
            >
              {{ t('CAPTAIN.MCP_SERVERS.DIALOG.REQUIRE_VERIFICATION_LOCKED') }}
            </span>
          </div>
        </div>
      </template>

      <template v-else>
        <h4 class="text-sm font-medium text-n-slate-12 m-0">
          {{ t('CAPTAIN.MCP_SERVERS.DIALOG.REVIEW_TITLE') }}
        </h4>
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="text-xs text-n-slate-11 text-start">
                <th class="py-2 pe-3 font-medium text-start">
                  {{ t('CAPTAIN.MCP_SERVERS.DIALOG.REVIEW_COLUMNS.TOOL') }}
                </th>
                <th class="py-2 pe-3 font-medium text-start">
                  {{ t('CAPTAIN.MCP_SERVERS.DIALOG.REVIEW_COLUMNS.WHO') }}
                </th>
                <th class="py-2 pe-3 font-medium text-start">
                  {{
                    t('CAPTAIN.MCP_SERVERS.DIALOG.REVIEW_COLUMNS.PARAMETERS')
                  }}
                </th>
                <th class="py-2 font-medium text-start">
                  {{
                    t('CAPTAIN.MCP_SERVERS.DIALOG.REVIEW_COLUMNS.FINGERPRINT')
                  }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="tool in selectedTools"
                :key="tool.name"
                class="border-t border-n-weak align-top"
              >
                <td class="py-2 pe-3">
                  <code>{{ tool.name }}</code>
                </td>
                <td class="py-2 pe-3 text-n-slate-11">
                  {{
                    toolRequiresVerification(tool)
                      ? t('CAPTAIN.MCP_SERVERS.WHO.VERIFIED')
                      : t('CAPTAIN.MCP_SERVERS.WHO.ANYONE')
                  }}
                </td>
                <td class="py-2 pe-3 text-xs text-n-slate-11">
                  {{ sourceSummary(tool) }}
                </td>
                <td class="py-2 font-mono text-xs text-n-slate-11">
                  {{ fingerprintLabel(toolDigest(tool)) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>
    </div>

    <template #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          v-if="step !== visibleSteps[0]"
          type="button"
          faded
          slate
          :label="t('CAPTAIN.MCP_SERVERS.DIALOG.BACK')"
          class="w-full"
          :disabled="isBusy"
          @click="back"
        />
        <Button
          v-if="step === 'SERVER'"
          type="button"
          class="w-full"
          :label="t('CAPTAIN.MCP_SERVERS.DIALOG.CONTINUE')"
          :is-loading="isBusy && !!discovery"
          :disabled="!canContinueFromServer || isBusy"
          @click="connect"
        />
        <Button
          v-else-if="step === 'TOOLS'"
          type="button"
          class="w-full"
          :label="t('CAPTAIN.MCP_SERVERS.DIALOG.CONTINUE')"
          :disabled="isLoadingTools || toolsLoadFailed"
          @click="step = 'PARAMETERS'"
        />
        <Button
          v-else-if="step === 'PARAMETERS'"
          type="button"
          class="w-full"
          :label="t('CAPTAIN.MCP_SERVERS.DIALOG.CONTINUE')"
          @click="goToReview"
        />
        <Button
          v-else
          type="button"
          class="w-full"
          :label="t('CAPTAIN.MCP_SERVERS.DIALOG.SAVE')"
          :is-loading="isBusy"
          :disabled="isBusy"
          @click="save"
        />
      </div>
    </template>
  </SidePanel>
</template>
