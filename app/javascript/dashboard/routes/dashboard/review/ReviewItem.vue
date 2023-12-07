<template>
  <div class="border-b border-slate-50 flex bg-white px-4 py-1 flex-1">
    <div class="whitespace-nowrap text-xs text-gray-300">#{{ source.id }}</div>
    <div
      class="whitespace-nowrap px-2 py-2 text-sm font-medium text-gray-900 flex-1"
    >
      <CardLabelsRenderer :conversation-labels="source.labels || []" />
    </div>
    <TimeAgo />
  </div>
</template>

<script>
import CardLabelsRenderer from 'dashboard/components/widgets/conversation/conversationCardComponents/CardLabelsRenderer.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
export default {
  components: { CardLabelsRenderer, TimeAgo },
  props: {
    source: {
      type: Object,
      default() {
        return {};
      },
    },
  },
};
</script>
