<template>
  <div class="pipeline-stage flex-shrink-0 w-80 bg-slate-50 rounded-xl flex flex-col max-h-full border border-slate-200">
    <div class="p-4 flex justify-between items-center border-b border-slate-200 bg-white rounded-t-xl">
      <h3 class="text-sm font-bold text-slate-700 uppercase tracking-wider">{{ stage.name }}</h3>
      <span class="bg-slate-100 text-slate-500 text-xs px-2 py-1 rounded-full">{{ deals.length }}</span>
    </div>
    
    <div class="p-3 overflow-y-auto flex-grow h-full min-h-[200px]" @dragover.prevent @drop="onDrop">
      <deal-card
        v-for="deal in deals"
        :key="deal.id"
        :deal="deal"
        draggable="true"
        @dragstart="onDragStart($event, deal)"
      />
    </div>
  </div>
</template>

<script>
import DealCard from './DealCard.vue';

export default {
  components: { DealCard },
  props: {
    stage: { type: Object, required: true },
    deals: { type: Array, default: () => [] }
  },
  methods: {
    onDragStart(event, deal) {
      event.dataTransfer.setData('dealId', deal.id);
      event.dataTransfer.effectAllowed = 'move';
    },
    onDrop(event) {
      const dealId = event.dataTransfer.getData('dealId');
      this.$emit('move-deal', { dealId, stageId: this.stage.id });
    }
  }
}
</script>
