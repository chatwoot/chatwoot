<script setup>
import { computed, onMounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

import PanelTest from '../components/panel/PanelTest.vue';
import PanelKnowledge from '../components/panel/PanelKnowledge.vue';
import PanelChannels from '../components/panel/PanelChannels.vue';
import PanelPerformance from '../components/panel/PanelPerformance.vue';
import PanelTune from '../components/panel/PanelTune.vue';
import PanelPublish from '../components/panel/PanelPublish.vue';

const props = defineProps({
  agentId: {
    type: [String, Number],
    required: true,
  },
  tab: {
    type: String,
    default: 'test',
  },
});

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const uiFlags = useMapGetter('autonomiaAgents/getUIFlags');

const agent = computed(() =>
  store.getters['autonomiaAgents/getRecord'](Number(props.agentId))
);

const isLoading = computed(
  () => uiFlags.value.fetchingItem && !agent.value?.id
);

// Tab icon per key (segmented control). Static, full class names so Tailwind's
// JIT picks them up; never interpolated.
const TAB_ICONS = {
  test: 'i-lucide-flask-conical',
  knowledge: 'i-lucide-book-open',
  channels: 'i-lucide-radio',
  performance: 'i-lucide-bar-chart-3',
  tune: 'i-lucide-sliders-horizontal',
};

// The first four sit in the segmented group; "Ajustar" (tune) is pulled out to
// the right of a divider because it edits the agent rather than inspecting it.
const MAIN_TAB_KEYS = ['test', 'knowledge', 'channels', 'performance'];

const buildTab = key => ({
  key,
  label: t(`AGENTS.PANEL.TABS.${key.toUpperCase()}`),
  icon: TAB_ICONS[key],
});

// V2.2 — an internal agent has no channels by design, so the "Canais" tab is
// hidden for it. external/both keep it. `both` is still connectable.
const isInternal = computed(() => agent.value?.actuation === 'internal');

const visibleTabKeys = computed(() =>
  isInternal.value
    ? MAIN_TAB_KEYS.filter(key => key !== 'channels')
    : MAIN_TAB_KEYS
);

const mainTabs = computed(() => visibleTabKeys.value.map(buildTab));
const tuneTab = computed(() => buildTab('tune'));

// Active/inactive pill styling. Active reads as an elevated chip on the subtle
// segmented background; inactive is muted with a hover lift. Tokens only.
const pillClass = key =>
  props.tab === key
    ? 'bg-n-solid-1 text-n-slate-12 shadow-sm'
    : 'text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2';

const activeComponent = computed(() => {
  switch (props.tab) {
    case 'knowledge':
      return PanelKnowledge;
    case 'channels':
      return PanelChannels;
    case 'performance':
      return PanelPerformance;
    case 'tune':
      return PanelTune;
    // Superfície de publicação (o hub roteia rascunho pra cá): externo conecta
    // canal, interno ativa direto — não entra na barra de abas.
    case 'publish':
      return PanelPublish;
    default:
      return PanelTest;
  }
});

const statusLabel = computed(() => {
  const status = agent.value?.status || 'draft';
  return t(`AGENTS.HUB.STATUS.${status.toUpperCase()}`);
});

const statusClass = computed(() => {
  switch (agent.value?.status) {
    case 'active':
      return 'bg-n-teal-9/15 text-n-teal-11';
    case 'paused':
      return 'bg-n-amber-9/15 text-n-amber-11';
    default:
      return 'bg-n-slate-9/15 text-n-slate-11';
  }
});

const onTabChanged = key => {
  if (key === props.tab) return;
  router.replace({
    name: 'autonomia_agent_panel',
    params: { agentId: props.agentId, tab: key },
  });
};

// Deep-linking straight to /channels for an internal agent (hidden tab) would
// render PanelChannels with no tab to return to. Bounce it back to the default
// tab once the agent record is known.
watch(
  [isInternal, () => props.tab],
  ([internal, tab]) => {
    if (internal && tab === 'channels') {
      router.replace({
        name: 'autonomia_agent_panel',
        params: { agentId: props.agentId, tab: 'test' },
      });
    }
  },
  { immediate: true }
);

// A rota reutiliza este componente ao navegar entre agentes (/agents/1 ->
// /agents/2): onMounted não redispara, então recarrega via watch — senão o
// cabeçalho/painéis mostram o agente anterior com ações apontando pro novo.
watch(
  () => props.agentId,
  () => store.dispatch('autonomiaAgents/show', Number(props.agentId))
);

onMounted(() => {
  store.dispatch('autonomiaAgents/show', Number(props.agentId));
});
</script>

<template>
  <div class="flex flex-col w-full h-full overflow-hidden bg-n-background">
    <header
      class="flex items-center justify-between flex-shrink-0 gap-4 px-6 py-4 border-b border-n-weak"
    >
      <div v-if="agent" class="flex items-center min-w-0 gap-3">
        <Avatar :name="agent.name" :src="agent.avatar_url" :size="40" />
        <div class="flex flex-col min-w-0">
          <h1 class="text-base font-medium truncate text-n-slate-12">
            {{ agent.name }}
          </h1>
          <span
            class="px-2 py-0.5 mt-0.5 text-xs font-medium rounded-full w-fit"
            :class="statusClass"
          >
            {{ statusLabel }}
          </span>
        </div>
      </div>
      <div v-else class="h-10" />

      <div
        v-if="agent"
        role="tablist"
        class="inline-flex items-center gap-1 p-1 rounded-lg bg-n-alpha-1"
      >
        <button
          v-for="item in mainTabs"
          :key="item.key"
          type="button"
          role="tab"
          :aria-selected="tab === item.key"
          class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm font-medium transition-colors"
          :class="pillClass(item.key)"
          @click="onTabChanged(item.key)"
        >
          <i :class="item.icon" class="size-4" />
          {{ item.label }}
        </button>
        <span class="w-px h-5 mx-1 bg-n-weak" aria-hidden="true" />
        <button
          type="button"
          role="tab"
          :aria-selected="tab === tuneTab.key"
          class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md text-sm font-medium transition-colors"
          :class="pillClass(tuneTab.key)"
          @click="onTabChanged(tuneTab.key)"
        >
          <i :class="tuneTab.icon" class="size-4" />
          {{ tuneTab.label }}
        </button>
      </div>
    </header>

    <div class="flex-1 min-h-0 overflow-y-auto">
      <div
        v-if="isLoading"
        class="flex items-center justify-center w-full h-full text-n-slate-11"
      >
        <Spinner :size="28" />
      </div>
      <!-- :key remonta o painel ao trocar de agente — os painéis (Conhecimento,
           Canais) buscam dados no onMounted e sem isso exibiriam a lista do
           agente anterior. -->
      <component
        :is="activeComponent"
        v-else-if="agent"
        :key="agentId"
        :agent="agent"
        :agent-id="Number(agentId)"
      />
    </div>
  </div>
</template>
