<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue';
import { useStore } from 'vuex';
import { useRouter, useRoute, onBeforeRouteLeave } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import FlowScreenList from '../components/FlowScreenList.vue';
import FlowCanvas from '../components/FlowCanvas.vue';
import FlowPropertyPanel from '../components/FlowPropertyPanel.vue';
import FlowComponentPalette from '../components/FlowComponentPalette.vue';
import FlowJsonEditor from '../components/FlowJsonEditor.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import {
  createDefaultScreen,
  resetScreenCounter,
  buildFlowJSON,
  extractFlowVariables,
} from 'dashboard/helper/whatsappFlowHelper';

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const route = useRoute();

const isEditing = computed(() => !!route.params.flowId);
const flowId = computed(() => route.params.flowId);

// ── Form state ──────────────────────────────────────────────────────
const flowName = ref('');
const selectedInboxId = ref('');
const screens = ref([]);
const activeScreenIndex = ref(0);
const selectedComponentIndex = ref(null);
const showJsonEditor = ref(false);
const showPalette = ref(false);
const isSaving = ref(false);
const isDirty = ref(false);

// ── Undo / Redo ────────────────────────────────────────────────────
const MAX_HISTORY = 50;
const history = ref([]);
const historyIndex = ref(-1);
const isRestoringHistory = ref(false);

function pushHistory() {
  const snapshot = JSON.stringify(screens.value);
  // Trim future states when new action is taken after undo
  if (historyIndex.value < history.value.length - 1) {
    history.value = history.value.slice(0, historyIndex.value + 1);
  }
  history.value.push(snapshot);
  if (history.value.length > MAX_HISTORY) {
    history.value.shift();
  }
  historyIndex.value = history.value.length - 1;
}

const canUndo = computed(() => historyIndex.value > 0);
const canRedo = computed(() => historyIndex.value < history.value.length - 1);

function restoreSnapshot(snapshot) {
  isRestoringHistory.value = true;
  screens.value = JSON.parse(snapshot).map(s => ({
    ...s,
    layout: {
      ...s.layout,
      children: (s.layout?.children || []).map(c => ({
        ...c,
        // eslint-disable-next-line no-underscore-dangle
        _id: c._id || `${c.type}_${Date.now()}_${Math.random()}`,
      })),
    },
  }));
  isRestoringHistory.value = false;
}

function undo() {
  if (!canUndo.value) return;
  historyIndex.value -= 1;
  restoreSnapshot(history.value[historyIndex.value]);
  selectedComponentIndex.value = null;
}

function redo() {
  if (!canRedo.value) return;
  historyIndex.value += 1;
  restoreSnapshot(history.value[historyIndex.value]);
  selectedComponentIndex.value = null;
}

function handleKeyboard(e) {
  const isCtrlOrMeta = e.ctrlKey || e.metaKey;
  if (!isCtrlOrMeta) return;
  if (e.key === 'z' && !e.shiftKey) {
    e.preventDefault();
    undo();
  } else if ((e.key === 'z' && e.shiftKey) || e.key === 'y') {
    e.preventDefault();
    redo();
  }
}

// Track dirty state
watch(
  [flowName, selectedInboxId, screens],
  () => {
    if (!isRestoringHistory.value) isDirty.value = true;
  },
  { deep: true }
);

// Unsaved changes guard
onBeforeRouteLeave((_to, _from, next) => {
  if (isDirty.value && !isSaving.value) {
    // eslint-disable-next-line no-alert
    const leave = window.confirm(t('WHATSAPP_FLOWS.BUILDER.UNSAVED_CHANGES'));
    next(leave);
  } else {
    next();
  }
});

function handleBeforeUnload(e) {
  if (isDirty.value) {
    e.preventDefault();
    e.returnValue = '';
  }
}

onMounted(() => window.addEventListener('beforeunload', handleBeforeUnload));
onBeforeUnmount(() => {
  window.removeEventListener('beforeunload', handleBeforeUnload);
  window.removeEventListener('keydown', handleKeyboard);
});

const whatsappInboxes = computed(() =>
  store.getters['inboxes/getInboxes'].filter(
    inbox => inbox.channel_type === 'Channel::Whatsapp'
  )
);
const inboxOptions = computed(() =>
  whatsappInboxes.value.map(i => ({ value: i.id, label: i.name }))
);

const activeScreen = computed(() => screens.value[activeScreenIndex.value]);

const selectedComponent = computed(() => {
  if (selectedComponentIndex.value === null || !activeScreen.value) return null;
  return activeScreen.value.layout.children[selectedComponentIndex.value];
});

const flowVariables = computed(() => extractFlowVariables(screens.value));

const flowJSON = computed(() => buildFlowJSON(screens.value));

const canSave = computed(
  () =>
    flowName.value.trim() && selectedInboxId.value && screens.value.length > 0
);

// ── Load existing flow if editing ───────────────────────────────────
onMounted(async () => {
  await store.dispatch('inboxes/get');
  if (isEditing.value) {
    await loadFlow(); // eslint-disable-line no-use-before-define
  } else if (route.query.cloneFrom) {
    await loadCloneSource(); // eslint-disable-line no-use-before-define
  } else {
    resetScreenCounter();
    screens.value = [createDefaultScreen()];
  }
  isDirty.value = false;
  pushHistory();
  window.addEventListener('keydown', handleKeyboard);
});

async function loadCloneSource() {
  try {
    await store.dispatch('whatsappFlows/get');
    const allFlows = store.getters['whatsappFlows/getWhatsappFlows'];
    const source = allFlows.find(f => f.id === Number(route.query.cloneFrom));
    if (source) {
      flowName.value = `${source.name}_copy`;
      selectedInboxId.value = source.inbox_id;
      if (source.flow_json?.screens?.length) {
        screens.value = source.flow_json.screens.map(s => ({
          ...s,
          layout: {
            ...s.layout,
            children: (s.layout?.children || []).map(c => ({
              ...c,
              _id: `${c.type}_${Date.now()}_${Math.random()}`,
            })),
          },
        }));
      } else {
        resetScreenCounter();
        screens.value = [createDefaultScreen()];
      }
    }
  } catch {
    useAlert(t('WHATSAPP_FLOWS.BUILDER.LOAD_ERROR'));
  }
}

async function loadFlow() {
  try {
    await store.dispatch('whatsappFlows/get');
    const allFlows = store.getters['whatsappFlows/getWhatsappFlows'];
    const flow = allFlows.find(f => f.id === Number(flowId.value));
    if (flow) {
      flowName.value = flow.name;
      selectedInboxId.value = flow.inbox_id;
      if (flow.flow_json?.screens?.length) {
        screens.value = flow.flow_json.screens.map(s => ({
          ...s,
          layout: {
            ...s.layout,
            children: (s.layout?.children || []).map(c => ({
              ...c,
              _id: `${c.type}_${Date.now()}_${Math.random()}`,
            })),
          },
        }));
      } else {
        resetScreenCounter();
        screens.value = [createDefaultScreen()];
      }
    }
  } catch {
    useAlert(t('WHATSAPP_FLOWS.BUILDER.LOAD_ERROR'));
  }
}

// ── Screen management ───────────────────────────────────────────────
function addScreen() {
  const isTerminal = screens.value.length === 0;
  screens.value.push(createDefaultScreen(isTerminal));
  activeScreenIndex.value = screens.value.length - 1;
  selectedComponentIndex.value = null;
  pushHistory();
}

function removeScreen(index) {
  if (screens.value.length <= 1) return;
  screens.value.splice(index, 1);
  if (activeScreenIndex.value >= screens.value.length) {
    activeScreenIndex.value = screens.value.length - 1;
  }
  selectedComponentIndex.value = null;
  pushHistory();
}

function selectScreen(index) {
  activeScreenIndex.value = index;
  selectedComponentIndex.value = null;
}

function updateScreenTitle(index, title) {
  screens.value[index].title = title;
  pushHistory();
}

function updateScreenId(index, id) {
  screens.value[index].id = id;
  pushHistory();
}

// ── Component management ────────────────────────────────────────────
function addComponent(component) {
  if (!activeScreen.value) return;
  const children = activeScreen.value.layout.children;
  // Insert before Footer if it exists
  const footerIndex = children.findIndex(c => c.type === 'Footer');
  if (footerIndex >= 0) {
    children.splice(footerIndex, 0, { ...component });
  } else {
    children.push({ ...component });
  }
  selectedComponentIndex.value =
    footerIndex >= 0 ? footerIndex : children.length - 1;
  showPalette.value = false;
  pushHistory();
}

function removeComponent(index) {
  if (!activeScreen.value) return;
  activeScreen.value.layout.children.splice(index, 1);
  selectedComponentIndex.value = null;
  pushHistory();
}

function selectComponent(index) {
  selectedComponentIndex.value = index;
}

function updateComponent(index, updates) {
  if (!activeScreen.value) return;
  const child = activeScreen.value.layout.children[index];
  Object.assign(child, updates);
  pushHistory();
}

function moveComponent(fromIndex, toIndex) {
  if (!activeScreen.value) return;
  const children = activeScreen.value.layout.children;
  const [moved] = children.splice(fromIndex, 1);
  children.splice(toIndex, 0, moved);
  selectedComponentIndex.value = toIndex;
  pushHistory();
}

// ── JSON editor ─────────────────────────────────────────────────────
function applyJsonEdit(json) {
  try {
    const parsed = JSON.parse(json);
    if (parsed.screens) {
      screens.value = parsed.screens.map(s => ({
        ...s,
        layout: {
          ...s.layout,
          children: (s.layout?.children || []).map(c => ({
            ...c,
            _id: `${c.type}_${Date.now()}_${Math.random()}`,
          })),
        },
      }));
      showJsonEditor.value = false;
      useAlert(t('WHATSAPP_FLOWS.BUILDER.JSON_APPLIED'));
      pushHistory();
    }
  } catch {
    useAlert(t('WHATSAPP_FLOWS.BUILDER.JSON_INVALID'));
  }
}

// ── Save / Submit ───────────────────────────────────────────────────
async function saveFlow() {
  if (!canSave.value || isSaving.value) return;
  isSaving.value = true;

  const payload = {
    whatsapp_flow: {
      name: flowName.value.trim(),
      inbox_id: selectedInboxId.value,
      flow_json: flowJSON.value,
    },
  };

  try {
    if (isEditing.value) {
      await store.dispatch('whatsappFlows/update', {
        id: Number(flowId.value),
        ...payload,
      });
      useAlert(t('WHATSAPP_FLOWS.BUILDER.UPDATE_SUCCESS'));
      isDirty.value = false;
    } else {
      const result = await store.dispatch('whatsappFlows/create', payload);
      useAlert(t('WHATSAPP_FLOWS.BUILDER.CREATE_SUCCESS'));
      isDirty.value = false;
      router.push({
        name: 'whatsapp_flows_edit',
        params: { flowId: result.id },
      });
    }
  } catch (error) {
    useAlert(t('WHATSAPP_FLOWS.BUILDER.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
}

function goBack() {
  router.push({ name: 'whatsapp_flows_index' });
}

// Reset selection when switching screens
watch(activeScreenIndex, () => {
  selectedComponentIndex.value = null;
});
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <!-- Top bar -->
    <header
      class="flex items-center justify-between px-4 py-3 border-b border-n-weak bg-white"
    >
      <div class="flex items-center gap-3">
        <button
          class="p-2 rounded-lg text-n-slate-9 hover:bg-n-alpha-1"
          @click="goBack"
        >
          <span class="i-lucide-arrow-left size-5" />
        </button>
        <input
          v-model="flowName"
          :placeholder="t('WHATSAPP_FLOWS.BUILDER.FLOW_NAME_PLACEHOLDER')"
          class="text-lg font-semibold bg-transparent border-none outline-none text-n-slate-12 placeholder:text-n-slate-8 w-64"
        />
      </div>
      <div class="flex items-center gap-3">
        <div class="flex items-center gap-1 border-r border-n-weak pr-3">
          <button
            :disabled="!canUndo"
            class="p-1.5 rounded text-n-slate-9 hover:bg-n-alpha-1 disabled:opacity-30 disabled:cursor-not-allowed"
            :title="t('WHATSAPP_FLOWS.BUILDER.UNDO')"
            @click="undo"
          >
            <span class="i-lucide-undo-2 size-4" />
          </button>
          <button
            :disabled="!canRedo"
            class="p-1.5 rounded text-n-slate-9 hover:bg-n-alpha-1 disabled:opacity-30 disabled:cursor-not-allowed"
            :title="t('WHATSAPP_FLOWS.BUILDER.REDO')"
            @click="redo"
          >
            <span class="i-lucide-redo-2 size-4" />
          </button>
        </div>
        <Select
          v-model="selectedInboxId"
          :options="inboxOptions"
          :placeholder="t('WHATSAPP_FLOWS.BUILDER.SELECT_INBOX')"
        />
        <button
          class="flex items-center gap-1.5 px-3 py-1.5 text-sm rounded-lg border border-n-weak hover:bg-n-alpha-1 text-n-slate-11"
          @click="showJsonEditor = !showJsonEditor"
        >
          <span class="i-lucide-code size-4" />
          {{ t('WHATSAPP_FLOWS.BUILDER.JSON_EDITOR') }}
        </button>
        <button
          :disabled="!canSave || isSaving"
          class="flex items-center gap-1.5 px-4 py-1.5 text-sm font-medium text-white bg-n-brand rounded-lg hover:bg-n-brand-dark disabled:opacity-50 disabled:cursor-not-allowed"
          @click="saveFlow"
        >
          <span v-if="isSaving" class="i-lucide-loader-2 size-4 animate-spin" />
          <span v-else class="i-lucide-save size-4" />
          {{
            isEditing
              ? t('WHATSAPP_FLOWS.BUILDER.UPDATE')
              : t('WHATSAPP_FLOWS.BUILDER.SAVE')
          }}
        </button>
      </div>
    </header>

    <!-- JSON Editor overlay -->
    <FlowJsonEditor
      v-if="showJsonEditor"
      :flow-json="flowJSON"
      @apply="applyJsonEdit"
      @close="showJsonEditor = false"
    />

    <!-- Three-panel layout -->
    <div v-else class="flex flex-1 overflow-hidden">
      <!-- Left: Screen list -->
      <FlowScreenList
        :screens="screens"
        :active-index="activeScreenIndex"
        @select="selectScreen"
        @add="addScreen"
        @remove="removeScreen"
        @update-title="updateScreenTitle"
        @update-id="updateScreenId"
      />

      <!-- Center: Canvas -->
      <div class="flex-1 flex flex-col overflow-hidden relative">
        <FlowCanvas
          v-if="activeScreen"
          :screen="activeScreen"
          :selected-index="selectedComponentIndex"
          :screens="screens"
          @select="selectComponent"
          @remove="removeComponent"
          @move="moveComponent"
          @add="showPalette = true"
        />

        <!-- Component palette modal -->
        <FlowComponentPalette
          v-if="showPalette"
          @select="addComponent"
          @close="showPalette = false"
        />
      </div>

      <!-- Right: Property panel -->
      <FlowPropertyPanel
        v-if="selectedComponent"
        :component="selectedComponent"
        :component-index="selectedComponentIndex"
        :screens="screens"
        :variables="flowVariables"
        @update="updateComponent"
        @close="selectedComponentIndex = null"
      />
    </div>
  </section>
</template>
