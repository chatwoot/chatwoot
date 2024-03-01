<template>
  <div class="flex-1 overflow-auto p-4">
    <p v-if="!dashboardApps.length">Nenhum Integração com App encontrada</p>
    <woot-tabs
      v-if="dashboardApps.length"
      :index="activeIndex"
      class="dashboard-app--tabs bg-white dark:bg-slate-900 -mt-px"
      @change="onDashboardAppTabChange"
    >
      <woot-tabs-item
        v-for="tab in dashboardAppTabs"
        :key="tab.key"
        :name="tab.name"
        :show-badge="false"
      />
    </woot-tabs>
    <dashboard-app-frame
      v-for="(dashboardApp, index) in dashboardApps"
      v-show="activeIndex === index"
      :key="dashboardApp.id"
      :is-visible="activeIndex === index"
      :config="dashboardApps[index].content"
      :position="index"
      :current-chat="null"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import DashboardAppFrame from './Frame.vue';

export default {
  components: { DashboardAppFrame },
  mixins: [],
  data() {
    return { activeIndex: -1 };
  },
  computed: {
    ...mapGetters({
      dashboardApps: 'dashboardApps/getRecords',
    }),
    dashboardAppTabs() {
      return [
        ...this.dashboardApps.map(dashboardApp => ({
          key: `dashboard-${dashboardApp.id}`,
          name: dashboardApp.title,
        })),
      ];
    },
  },
  mounted() {
    this.$store.dispatch('dashboardApps/get');
  },
  methods: {
    onDashboardAppTabChange(index) {
      this.activeIndex = index;
    },
  },
};
</script>
