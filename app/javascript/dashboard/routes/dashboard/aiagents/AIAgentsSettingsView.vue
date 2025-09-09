<script setup>
import { useRoute } from 'vue-router';
import AiAgentGeneralSettingsView from './AiAgentGeneralSettingsView.vue';
import AiAgentKnowledgeSources from './AiAgentKnowledgeSources.vue';
import AiAgentWebsiteSettingsView from './AiAgentWebsiteSettingsView.vue';
import ConfigurationView from './ConfigurationView.vue';
import CSBotView from './botconfigs/CSBotView.vue';
import RestaurantBotView from './botconfigs/RestaurantBotView.vue';
import BookingBotView from './botconfigs/BookingBotView.vue';
import SalesBotView from './botconfigs/SalesBotView.vue';
import { onMounted, ref, computed } from 'vue';
import aiAgents from '../../../api/aiAgents';

const route = useRoute();
const allTabs = [
  {
    key: '0',
    index: 0,
    name: 'Umum',
    type: 'general',
  },
  // {
  //   key: '1',
  //   index: 1,
  //   name: 'Sumber Pengetahuan',
  // },
  {
    key: '2',
    index: 2,
    name: 'Website',
    type: 'website',
  },
  {
    key: '3',
    index: 3,
    name: 'CS Bot',
    type: 'customer_service',
  },
  {
    key: '4',
    index: 4,
    name: 'Restaurant Bot',
    type: 'restaurant',
  },
  {
    key: '5',
    index: 5,
    name: 'Booking Bot',
    type: 'booking',
  },
  {
    key: '6',
    index: 6,
    name: 'Sales Bot',
    type: 'sales',
  },
];

const visibleTabs = computed(() => {
  if (!data.value?.display_flow_data) {
    // If no data yet, show only general tabs
    return allTabs.filter(tab => tab.type === 'general' || tab.type === 'website');
  }

  // custom_agent type
  if (data.value.display_flow_data.type === 'custom_agent') {
    return allTabs.filter(tab => tab.type === 'general').map((tab, index) => ({
      ...tab,
      displayIndex: index
    }));
  }

  if (!data.value?.display_flow_data?.enabled_agents) {
    // If no enabled_agents yet, show only general tabs
    return allTabs.filter(tab => tab.type === 'general' || tab.type === 'website');
  }

  const enabledAgents = data.value.display_flow_data.enabled_agents;
  
  return allTabs.filter(tab => {
    if (tab.type === 'general' || tab.type === 'website') {
      return true;
    }
    
    return enabledAgents.includes(tab.type);
  }).map((tab, index) => ({
    ...tab,
    displayIndex: index
  }));
});

// Helper function to get the original tab configuration for content display
const getTabByOriginalIndex = (originalIndex) => {
  return allTabs.find(tab => tab.index === originalIndex);
};

const activeIndex = ref(0);
const loadingData = ref(false);
const data = ref();

const showData = async () => {
  try {
    loadingData.value = true;
    data.value = await aiAgents
      .detailAgent(route.params.aiAgentId)
      .then(v => v?.data);
  } finally {
    loadingData.value = false;
  }
};

onMounted(() => {
  showData();
});
</script>

<template>
  <div class="w-full px-8 py-8 bg-n-background dark:bg-gray-900 overflow-auto">
    <div>
      <center v-if="loadingData">
        <span class="mt-4 mb-4 spinner" />
      </center>
      <div class="mb-3 mt-6">
        <h1
          class="text-2xl font-semibold font-interDisplay tracking-[0.3px] text-slate-900 dark:text-slate-25"
        >
          {{ data?.name }}
        </h1>
      </div>
    </div>

    <woot-tabs
      :index="activeIndex"
      class="mb-3 tabs-rm-margin"
      @change="
        i => {
          activeIndex = i;
        }
      "
    >
      <woot-tabs-item
        v-for="tab in visibleTabs"
        :key="tab.key"
        :index="tab.displayIndex"
        :name="tab.name"
        :show-badge="false"
      />
    </woot-tabs>

    <div v-show="activeIndex === 0">
      <AiAgentGeneralSettingsView :data="data" :bot-type="data?.display_flow_data?.type" />
    </div>

    <!-- <div v-show="activeIndex === 1">
      <AiAgentKnowledgeSources :data="data" />
    </div> -->

    <!-- <div v-show="activeIndex === 2" class="w-full">
      <ConfigurationView :data="data" />
    </div> -->

    <div v-show="visibleTabs[activeIndex]?.index === 2" class="w-full">
      <AiAgentWebsiteSettingsView :data="data" />
    </div>

    <div v-show="visibleTabs[activeIndex]?.index === 3">
      <CSBotView :data="data" />
    </div>

    <div v-show="visibleTabs[activeIndex]?.index === 4">
      <RestaurantBotView :data="data" />
    </div>

    <div v-show="visibleTabs[activeIndex]?.index === 5">
      <BookingBotView :data="data" />
    </div>

    <div v-show="visibleTabs[activeIndex]?.index === 6">
      <SalesBotView :data="data" />
    </div>
  </div>
</template>

<style>
.tabs-rm-margin .tabs {
  padding-left: 0px !important;
}
</style>