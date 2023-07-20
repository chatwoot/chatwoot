<template>
  <div
    class="ring-1 ring-inset ring-slate-50 rounded-md bg-white px-4 py-2 shadow-sm hover:bg-slate-25"
  >
    <div class=" flex flex-wrap items-center justify-between">
      <div class="">
        <h3 class="text-sm font-semibold leading-6 text-slate-800">
          {{
            isOnline
              ? $t('TEAM_AVAILABILITY.ONLINE')
              : $t('TEAM_AVAILABILITY.OFFLINE')
          }}
          <span
            class="w-2 h-2 rounded-full inline-block mx-1"
            :class="isOnline ? 'bg-green-600' : 'bg-slate-500'"
          />
        </h3>
        <p class="m-0 text-sm text-slate-700 leading-5">
          <span class="h-5 group-hover:hidden text-sm">
            {{ replyWaitMessage }}
          </span>
          <button
            class="rounded h-5 px-1 -ml-1 text-sm font-medium hidden hover:bg-slate-75 group-hover:inline chat-with-us"
            @click="startConversation"
          >
            Chat with us
          </button>
        </p>
      </div>
      <div class="ml-4 mt-4 flex-shrink-0">
        <available-agents v-if="isOnline" :agents="availableAgents" />
      </div>
    </div>
  </div>
</template>
<script>
import AvailableAgents from 'widget/components/AvailableAgents';

export default {
  components: { AvailableAgents },
  props: {
    articles: {
      type: Array,
      default: () => [],
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
    availableAgents: {
      type: Array,
      default: () => [],
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
<style lang="scss" scoped>
.chat-with-us {
  color: var(--brand-textButtonClear);
}
</style>
