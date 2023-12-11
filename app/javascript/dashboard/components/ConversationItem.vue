<template>
  <div>
    <conversation-card
      :key="source.id"
      :active-label="label"
      :team-id="teamId"
      :folders-id="foldersId"
      :chat="source"
      :conversation-type="conversationType"
      :selected="true"
    />
  </div>
</template>

<script>
import ConversationCard from './widgets/conversation/ConversationCard.vue';
export default {
  components: {
    ConversationCard,
  },
  props: {
    source: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      teamId: 0,
      foldersId: 0,
      label: '',
      conversationType: '',
    };
  },
};
</script>
<style scoped>
@tailwind components;
@layer components {
  .flex-basis-clamp {
    flex-basis: clamp(20rem, 4vw + 21.25rem, 27.5rem);
  }
}
</style>

<style scoped lang="scss">
.conversations-list-wrap {
  &.hide {
    @apply hidden;
  }

  &.list--full-width {
    @apply basis-full;
  }
}

.conversations-list {
  @apply overflow-hidden hover:overflow-y-auto;
}

.load-more--button {
  @apply text-center rounded-none;
}

.tab--chat-type {
  @apply py-0 px-4;

  ::v-deep {
    .tabs {
      @apply p-0;
    }
  }
}
</style>
