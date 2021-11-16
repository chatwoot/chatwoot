<template>
  <div class="px-4 mb-4">
    <div class="flex justify-between items-center">
      <h3 class="text-lg font-medium text-gray-900">
        {{ $t('ACTIVE_CONVERSATIONS.TITLE') }}
      </h3>
      <button
        class="font-medium text-sm text-woot-600 hover:text-woot-500 transition
          ease-in-out duration-150"
        @click="clickAllConversations"
      >
        {{ $t('ACTIVE_CONVERSATIONS.VIEW_ALL') }}
        <span aria-hidden="true">&rarr;</span>
      </button>
    </div>
    <conversation-item
      v-for="conversation in conversations"
      :key="conversation.id"
      :conversation="conversation"
      :unread-count="unreadCount(conversation.id)"
    />
  </div>
</template>
<script>
import availabilityMixin from 'widget/mixins/availability';
import ConversationItem from 'widget/components/ConversationItem';

export default {
  components: { ConversationItem },
  mixins: [availabilityMixin],
  props: {
    conversations: {
      type: Array,
      default: () => [],
    },
    availableAgents: {
      type: Array,
      default: () => [],
    },
  },
  setup(props, context) {
    const router = context.root.$router;
    const unreadCount = conversationId => {
      const count =
        context.root.$store.getters['conversationV2/unreadTextMessagesCountIn'](
          conversationId
        ) || 0;
      return count;
    };

    const clickAllConversations = () => {
      router.push({
        name: 'conversations',
      });
    };
    return {
      unreadCount,
      clickAllConversations,
    };
  },
};
</script>
<style lang="scss" scoped></style>
