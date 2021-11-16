<template>
  <div class="flex py-3 item-border-fix">
    <button @click="onItemClick">
      <div class="flex items-center space-x-2">
        <div class="h-10 w-10 rounded-full border-2 border-woot-100">
          <thumbnail :src="agentAvatar" size="40px" :username="agentName" />
        </div>
        <div class="text-left">
          <div class="flex items-center">
            <h4 class="text-sm font-medium text-slate-900">{{ agentName }}</h4>
            <span class="text-xs text-slate-500 ml-2">
              {{ dynamicTime(lastMessage.created_at) }}
            </span>
          </div>
          <p
            class="inline-block text-sm text-black-700"
            :class="{ 'font-medium': unreadCount }"
          >
            {{ lastMessageContent }}
            <span v-if="unreadCount > 0" class="unread-bubble"></span>
          </p>
        </div>
      </div>
    </button>
  </div>
</template>
<script>
import { computed } from '@vue/composition-api';
import timeMixin from 'dashboard/mixins/time';
import Thumbnail from 'dashboard/components/widgets/Thumbnail';

export default {
  components: { Thumbnail },
  mixins: [timeMixin],
  props: {
    conversation: {
      type: Object,
      default: () => ({}),
    },
    unreadCount: {
      type: Number,
      default: 0,
    },
  },
  setup(props, context) {
    const router = context.root.$router;
    const imageAttachmnetText = context.root.$t(
      'COMPONENTS.CONVERSATION_ITEM.IMAGE_ATTACHMENT'
    );

    const lastMessage = computed(() => {
      const { conversation } = props;
      const { messages = [] } = conversation;
      const message = messages[messages.length - 1];

      if (!message) return {};
      return message;
    });

    const lastMessageContent = computed(() => {
      const { content, attachments } = lastMessage.value;

      if (attachments) {
        return imageAttachmnetText;
      }

      return content;
    });

    const agentName = computed(() => {
      const { websiteName = '' } = window.chatwootWebChannel;
      const { conversation } = props;
      const { assignee } = conversation;

      if (assignee) return assignee.name;
      return websiteName;
    });

    const agentAvatar = computed(() => {
      const { avatarUrl: websiteAvatarUrl = '' } = window.chatwootWebChannel;
      const { conversation } = props;
      const { assignee } = conversation;

      if (assignee) {
        const { avatar_url: avatarUrl } = conversation;
        return avatarUrl;
      }
      return websiteAvatarUrl;
    });

    const onItemClick = () => {
      const { conversation } = props;
      // conversation
      router.push({
        name: 'chat',
        params: {
          conversationId: conversation.id,
        },
      });
    };

    return {
      agentName,
      agentAvatar,
      lastMessage,
      lastMessageContent,
      onItemClick,
    };
  },
};
</script>
<style lang="scss" scoped>
.item-border-fix {
  border: 1px solid transparent;
}

.unread-bubble {
  @apply w-2;
  @apply h-2;
  @apply rounded-full;
  @apply bg-red-300;
  @apply inline-block;
}
</style>
