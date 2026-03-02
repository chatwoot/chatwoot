<script setup>
import { computed, ref, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ChatPreviewPanel from '../components/preview/ChatPreviewPanel.vue';

import SetupTab from '../components/tabs/SetupTab.vue';
import KnowledgeTab from '../components/tabs/KnowledgeTab.vue';
import ToolsTab from '../components/tabs/ToolsTab.vue';
import VoiceTab from '../components/tabs/VoiceTab.vue';
import WorkflowTab from '../components/tabs/WorkflowTab.vue';
import RunInspectorTab from '../components/tabs/RunInspectorTab.vue';
import TestTab from '../components/tabs/TestTab.vue';
import DeployTab from '../components/tabs/DeployTab.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const uiFlags = useMapGetter('aiAgents/getUIFlags');
const currentAgent = useMapGetter('aiAgents/getCurrentAgent');
const isFetching = computed(() => uiFlags.value.isFetching);

const agentId = computed(() => Number(route.params.agentId));

const tabs = computed(() => [
  {
    key: 'setup',
    label: t('AI_AGENTS.TABS.SETUP'),
    icon: 'i-lucide-settings',
    route: 'ai_agents_setup',
  },
  {
    key: 'knowledge',
    label: t('AI_AGENTS.TABS.KNOWLEDGE'),
    icon: 'i-lucide-database',
    route: 'ai_agents_knowledge',
  },
  {
    key: 'tools',
    label: t('AI_AGENTS.TABS.TOOLS'),
    icon: 'i-lucide-wrench',
    route: 'ai_agents_tools',
  },
  {
    key: 'voice',
    label: t('AI_AGENTS.TABS.VOICE'),
    icon: 'i-lucide-mic',
    route: 'ai_agents_voice',
  },
  {
    key: 'workflow',
    label: t('AI_AGENTS.TABS.WORKFLOW'),
    icon: 'i-lucide-git-branch-plus',
    route: 'ai_agents_workflow',
  },
  {
    key: 'runs',
    label: t('AI_AGENTS.TABS.RUNS'),
    icon: 'i-lucide-play-circle',
    route: 'ai_agents_runs',
  },
  {
    key: 'test',
    label: t('AI_AGENTS.TABS.TEST'),
    icon: 'i-lucide-message-square',
    route: 'ai_agents_test',
  },
  {
    key: 'deploy',
    label: t('AI_AGENTS.TABS.DEPLOY'),
    icon: 'i-lucide-rocket',
    route: 'ai_agents_deploy',
  },
]);

const activeTabKey = computed(() => {
  const name = route.name;
  const matched = tabs.value.find(item => item.route === name);
  return matched ? matched.key : 'setup';
});

const activeComponent = computed(() => {
  const componentMap = {
    setup: SetupTab,
    knowledge: KnowledgeTab,
    tools: ToolsTab,
    voice: VoiceTab,
    workflow: WorkflowTab,
    runs: RunInspectorTab,
    test: TestTab,
    deploy: DeployTab,
  };
  return componentMap[activeTabKey.value] || SetupTab;
});

const navigateToTab = tab => {
  router.push({
    name: tab.route,
    params: {
      accountId: route.params.accountId,
      agentId: agentId.value,
    },
  });
};

const goBack = () => {
  router.push({
    name: 'ai_agents_list',
    params: { accountId: route.params.accountId },
  });
};

const fetchAgent = () => {
  if (agentId.value) {
    store.dispatch('aiAgents/show', agentId.value);
  }
};

watch(agentId, fetchAgent);
onMounted(fetchAgent);

const showPreviewPanel = ref(false);
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header class="sticky top-0 z-10 px-6 border-b border-n-weak">
      <div class="w-full max-w-5xl mx-auto">
        <div class="flex items-center gap-3 py-4">
          <Button
            icon="i-lucide-arrow-left"
            variant="ghost"
            color="slate"
            size="sm"
            @click="goBack"
          />
          <div v-if="currentAgent" class="flex items-center gap-2 min-w-0">
            <div
              class="flex items-center justify-center size-8 rounded-lg bg-n-alpha-2 text-n-slate-11 shrink-0"
            >
              <div class="i-lucide-bot size-4" />
            </div>
            <h1 class="text-xl font-medium text-n-slate-12 truncate">
              {{ currentAgent.name }}
            </h1>
          </div>
        </div>

        <nav class="flex gap-1 -mb-px">
          <button
            v-for="tab in tabs"
            :key="tab.key"
            class="flex items-center gap-1.5 px-3 py-2.5 text-sm font-medium rounded-t-lg transition-colors"
            :class="
              activeTabKey === tab.key
                ? 'text-n-blue-11 border-b-2 border-n-blue-9'
                : 'text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2'
            "
            @click="navigateToTab(tab)"
          >
            <div :class="tab.icon" class="size-4" />
            {{ tab.label }}
          </button>
        </nav>
      </div>
    </header>

    <main
      class="flex-1 overflow-y-auto"
      :class="['workflow', 'runs'].includes(activeTabKey) ? 'px-2' : 'px-6'"
    >
      <div
        class="w-full py-6"
        :class="
          ['workflow', 'runs'].includes(activeTabKey) ? '' : 'max-w-5xl mx-auto'
        "
      >
        <div
          v-if="isFetching"
          class="flex items-center justify-center py-10 text-n-slate-11"
        >
          <Spinner />
        </div>
        <component
          :is="activeComponent"
          v-else-if="currentAgent"
          :agent="currentAgent"
        />
      </div>
    </main>

    <!-- Floating Test Button -->
    <button
      v-if="currentAgent && activeTabKey !== 'test' && !showPreviewPanel"
      type="button"
      class="fixed bottom-6 right-6 z-30 flex items-center gap-2 px-4 py-3 rounded-full bg-n-blue-9 text-white shadow-lg hover:bg-n-blue-10 transition-all hover:shadow-xl"
      @click="showPreviewPanel = true"
    >
      <span class="i-lucide-message-square size-5" />
      <span class="text-sm font-medium">{{
        t('AI_AGENTS.PREVIEW.TITLE')
      }}</span>
    </button>

    <!-- Slide-over Preview Panel -->
    <Teleport to="body">
      <Transition name="slide">
        <div
          v-if="showPreviewPanel && currentAgent"
          class="fixed inset-y-0 right-0 z-50 flex"
        >
          <!-- Backdrop -->
          <div
            class="fixed inset-0 bg-black/20"
            @click="showPreviewPanel = false"
          />
          <!-- Panel -->
          <div
            class="relative ml-auto w-[400px] max-w-full h-full bg-n-surface-1 border-l border-n-weak shadow-2xl flex flex-col"
          >
            <button
              type="button"
              class="absolute top-3 right-3 z-10 flex items-center justify-center size-7 rounded-lg hover:bg-n-alpha-2 text-n-slate-10"
              @click="showPreviewPanel = false"
            >
              <span class="i-lucide-x size-4" />
            </button>
            <ChatPreviewPanel :agent="currentAgent" />
          </div>
        </div>
      </Transition>
    </Teleport>
  </section>
</template>
