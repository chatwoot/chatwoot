<script>
import PreviewCard from 'dashboard/components/ui/PreviewCard.vue';

export default {
  components: {
    PreviewCard,
  },
  props: {
    lockToSingleConversation: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['update'],
  data() {
    return {
      lockOptions: [
        {
          key: true,
          heading: this.$t(
            'INBOX_MGMT.EDIT.LOCK_TO_SINGLE_CONVERSATION.ENABLED'
          ),
          content:
            'When a contact messages again, the previous conversation will be reopened.',
        },
        {
          key: false,
          heading: this.$t(
            'INBOX_MGMT.EDIT.LOCK_TO_SINGLE_CONVERSATION.DISABLED'
          ),
          content:
            'A new conversation will be created each time after the previous one is resolved.',
        },
      ],
    };
  },
  methods: {
    toggleLockToSingleConversation(key) {
      this.$emit('update', key);
    },
  },
};
</script>

<template>
  <div class="flex flex-col lg:flex-row items-start lg:items-center gap-4">
    <button
      v-for="option in lockOptions"
      :key="option.key"
      class="text-slate-800 dark:text-slate-100 cursor-pointer p-0"
      @click="toggleLockToSingleConversation(option.key)"
    >
      <PreviewCard
        :heading="option.heading"
        :content="option.content"
        :active="option.key === lockToSingleConversation"
      >
        <div class="p-3" />
      </PreviewCard>
    </button>
  </div>
</template>
