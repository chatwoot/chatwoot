<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';

import Policy from 'dashboard/components/policy.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import AgentsList from '../agents/Index.vue';
import TeamsList from '../teams/Index.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();

// The tab rides in the query rather than a child route so the sidebar keeps a
// single entry that stays highlighted across both halves of the page.
const TABS = [
  { key: 'agents', labelKey: 'PEOPLE.TABS.AGENTS' },
  { key: 'teams', labelKey: 'PEOPLE.TABS.TEAMS' },
];

const activeKey = computed(() =>
  TABS.some(tab => tab.key === route.query.tab) ? route.query.tab : 'agents'
);

const activeIndex = computed(() =>
  TABS.findIndex(tab => tab.key === activeKey.value)
);

const tabs = computed(() => TABS.map(tab => ({ label: t(tab.labelKey) })));

const onTabChange = index => {
  router.replace({ query: { tab: TABS[index].key } });
};
</script>

<template>
  <div class="flex flex-col w-full h-full">
    <div class="px-1 pt-1">
      <TabBar
        :tabs="tabs"
        :initial-active-tab="activeIndex"
        @tab-changed="onTabChange"
      />
    </div>
    <Policy
      v-if="activeKey === 'agents'"
      class="flex flex-col flex-1 min-h-0"
      :feature-flag="FEATURE_FLAGS.AGENT_MANAGEMENT"
      :permissions="['administrator']"
    >
      <AgentsList />
    </Policy>
    <Policy
      v-else
      class="flex flex-col flex-1 min-h-0"
      :feature-flag="FEATURE_FLAGS.TEAM_MANAGEMENT"
      :permissions="['administrator']"
    >
      <TeamsList />
    </Policy>
  </div>
</template>
