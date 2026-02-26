<template>
  <div class="pipelines-view h-full flex flex-col bg-white">
    <div class="flex-shrink-0 p-6 border-b border-slate-100 flex justify-between items-center">
      <div class="flex items-center gap-4">
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">CRM Pipelines</h1>
        <select 
          v-model="selectedPipelineId" 
          @change="fetchPipelineData"
          class="bg-slate-50 border border-slate-200 text-slate-700 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 p-2.5 ml-4"
        >
          <option v-for="pipeline in pipelines" :key="pipeline.id" :value="pipeline.id">
            {{ pipeline.name }}
          </option>
        </select>
      </div>
      <button class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-lg shadow-sm transition-all text-sm">
        + Create Deal
      </button>
    </div>

    <div v-if="loading" class="flex-grow flex items-center justify-center italic text-slate-400">
      Loading CRM data...
    </div>

    <div v-else class="flex-grow overflow-x-auto overflow-y-hidden p-6 gap-6 flex">
      <pipeline-stage
        v-for="stage in selectedPipeline.pipeline_stages"
        :key="stage.id"
        :stage="stage"
        :deals="dealsByStage[stage.id] || []"
        @move-deal="onMoveDeal"
      />
    </div>
  </div>
</template>

<script>
import PipelineStage from './PipelineStage.vue';
import axios from 'axios';

export default {
  components: { PipelineStage },
  data() {
    return {
      pipelines: [],
      deals: [],
      selectedPipelineId: null,
      loading: true
    };
  },
  computed: {
    selectedPipeline() {
      return this.pipelines.find(p => p.id === this.selectedPipelineId) || { pipeline_stages: [] };
    },
    dealsByStage() {
      return this.deals.reduce((acc, deal) => {
        if (!acc[deal.pipeline_stage_id]) acc[deal.pipeline_stage_id] = [];
        acc[deal.pipeline_stage_id].push(deal);
        return acc;
      }, {});
    }
  },
  async created() {
    await this.fetchPipelines();
    this.loading = false;
  },
  methods: {
    async fetchPipelines() {
      try {
        const { data } = await axios.get('/api/v1/accounts/' + window.chatwootConfig.accountId + '/pipelines');
        this.pipelines = data;
        if (this.pipelines.length > 0) {
          this.selectedPipelineId = this.pipelines[0].id;
          await this.fetchPipelineData();
        }
      } catch (e) { console.error('Error fetching pipelines', e); }
    },
    async fetchPipelineData() {
      try {
        const { data } = await axios.get('/api/v1/accounts/' + window.chatwootConfig.accountId + '/deals');
        this.deals = data;
      } catch (e) { console.error('Error fetching deals', e); }
    },
    async onMoveDeal({ dealId, stageId }) {
      try {
        await axios.patch(`/api/v1/accounts/${window.chatwootConfig.accountId}/deals/${dealId}`, {
          deal: { pipeline_stage_id: stageId }
        });
        await this.fetchPipelineData();
      } catch (e) { console.error('Error moving deal', e); }
    }
  }
}
</script>

<style scoped>
.pipelines-view { min-height: 100%; height: 100vh; overflow: hidden; }
</style>
