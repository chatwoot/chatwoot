<template>
  <elevated-sheet class="pt-0 sticky top-0 bg-brand-primary">
    <div class="pt-6 group">
      <h1
        v-dompurify-html="title"
        class="text-2xl font-bold leading-8 text-slate-900 mb-2 drop-shadow-sm text-brand-title"
      />
      <p
        v-dompurify-html="body"
        class=" text-slate-700 leading-6 drop-shadow-sm text-brand-body"
      />
      <div class="pt-4">
        <availability-card
          :agents="agents"
          :is-online="isOnline"
          :reply-wait-message="replyWaitMessage"
          @start="startConversation"
        />
      </div>
    </div>
  </elevated-sheet>
</template>
<script>
import ElevatedSheet from './ElevatedSheet.vue';
import AvailabilityCard from './AvailabilityCard.vue';

export default {
  components: { ElevatedSheet, AvailabilityCard },
  props: {
    title: {
      type: String,
      default: '',
    },
    body: {
      type: String,
      default: '',
    },
    agents: {
      type: Array,
      default: () => [],
    },
    isOnline: {
      type: Boolean,
      default: false,
    },
    replyWaitMessage: {
      type: String,
      default: '',
    },
  },
  data() {
    return {};
  },
  methods: {
    startConversation() {
      this.$emit('start');
    },
  },
};
</script>
