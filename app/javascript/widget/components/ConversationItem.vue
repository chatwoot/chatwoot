<template>
  <div class="item--wrap">
    <button @click="onItemClick">
      <div class="flex items-center space-x-2">
        <div class="h-10 w-10 rounded-full border-2 border-woot-100">
          <thumbnail
            src="https://randomuser.me/api/portraits/women/11.jpg"
            size="40px"
            username="Erin Lindford"
          />
        </div>
        <div class="text-left">
          <div class="flex items-center">
            <h4 class="text-sm font-medium text-slate-900">{{ agentName }}</h4>
            <span class="text-xs text-slate-500 ml-2">
              {{ dynamicTime(lastMessage.created_at) }}
            </span>
          </div>
          <p class="text-sm text-black-700">
            {{ lastMessageContent }}
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
        debugger;
        return imageAttachmnetText;
      }

      return content;
    });

    const agentName = computed(() => {
      const { websiteName = '' } = window.chatwootWebChannel;

      return websiteName;
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
      lastMessage,
      lastMessageContent,
      onItemClick,
    };
  },
};
</script>
<style lang="scss" scoped>
.item--wrap {
  @apply flex;
  @apply py-3;
  border: 1px solid transparent;
}
</style>
