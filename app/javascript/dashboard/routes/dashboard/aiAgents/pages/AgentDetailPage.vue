<script setup>
import { computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';

import SetupTab from '../components/tabs/SetupTab.vue';
import KnowledgeTab from '../components/tabs/KnowledgeTab.vue';
import ToolsTab from '../components/tabs/ToolsTab.vue';
import VoiceTab from '../components/tabs/VoiceTab.vue';
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

    <main class="flex-1 px-6 overflow-y-auto">
      <div class="w-full max-w-5xl mx-auto py-6">
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
  </section>
</template>
