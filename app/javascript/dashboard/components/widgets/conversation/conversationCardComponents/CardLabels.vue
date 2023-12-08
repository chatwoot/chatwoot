<template>
  <card-labels-renderer :conversation-labels="activeLabels" class="mt-0.5" />
</template>
<script>
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';
import CardLabelsRenderer from './CardLabelsRenderer.vue';
export default {
  components: { CardLabelsRenderer },
  mixins: [conversationLabelMixin],
  props: {
    conversationId: {
      type: Number,
      required: true,
    },
  },
};
</script>
