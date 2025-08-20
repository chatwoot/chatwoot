<script setup>
import { useRoute } from 'vue-router';
import AiAgentGeneralSettingsView from './AiAgentGeneralSettingsView.vue';
import AiAgentKnowledgeSources from './AiAgentKnowledgeSources.vue';
import ConfigurationView from './ConfigurationView.vue';
import CSBotView from './botconfigs/CSBotView.vue';
import RestaurantBotView from './botconfigs/RestaurantBotView.vue';
import BookingBotView from './botconfigs/BookingBotView.vue';
import SalesBotView from './botconfigs/SalesBotView.vue';
import { onMounted, ref } from 'vue';
import aiAgents from '../../../api/aiAgents';

const route = useRoute();
const tabs = [
  {
    key: '0',
    index: 0,
    name: 'Umum',
  },
  // {
  //   key: '1',
  //   index: 1,
  //   name: 'Sumber Pengetahuan',
  // },
  // {
  //   key: '2',
  //   index: 2,
  //   name: 'Konfigurasi',
  // },
  {
    key: '3',
    index: 3,
    name: 'CS Bot',
  },
  {
    key: '4',
    index: 4,
    name: 'Restaurant Bot',
  },
  {
    key: '5',
    index: 5,
    name: 'Booking Bot',
  },
  {
    key: '6',
    index: 6,
    name: 'Sales Bot',
  },
];

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
        v-for="tab in tabs"
        :key="tab.key"
        :index="tab.index"
        :name="tab.name"
        :show-badge="false"
      />
    </woot-tabs>

    <div v-show="activeIndex === 0">
      <AiAgentGeneralSettingsView :data="data" />
    </div>

    <!-- <div v-show="activeIndex === 1">
      <AiAgentKnowledgeSources :data="data" />
    </div>

    <div v-show="activeIndex === 2" class="w-full">
      <ConfigurationView :data="data" />
    </div> -->

    <div v-show="activeIndex === 3">
      <CSBotView :data="data" />
    </div>

    <div v-show="activeIndex === 4">
      <RestaurantBotView :data="data" />
    </div>

    <div v-show="activeIndex === 5">
      <BookingBotView :data="data" />
    </div>

    <div v-show="activeIndex === 6">
      <SalesBotView :data="data" />
    </div>
  </div>
</template>

<style>
.tabs-rm-margin .tabs {
  padding-left: 0px !important;
}
</style>