<template>
  <div class="item--wrap">
    <button @click="onItemClick">
      <div class="flex items-center space-x-4">
        <div class="h-10 w-10 rounded-full border-2 border-woot-100">
          <thumbnail
            src="https://images.unsplash.com/photo-1519345182560-3f2917c472ef?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
            size="40px"
            username="Erin Lindford"
          />
        </div>
        <div class="ml-2 text-left">
          <p class="text-sm font-medium text-gray-900">Nithin David</p>
          <p class="text-sm text-gray-500">
            {{ lastMessageContent }}
          </p>
        </div>
      </div>
    </button>
  </div>
</template>
<script>
import { computed } from '@vue/composition-api';
import Thumbnail from 'dashboard/components/widgets/Thumbnail';

export default {
  components: { Thumbnail },
  props: {
    conversation: {
      type: Object,
      default: () => ({}),
    },
  },
  setup(props, context) {
    const router = context.root.$router;

    const lastMessageContent = computed(() => {
      const { conversation } = props;
      const { messages = [] } = conversation;
      const lastMessage = messages[messages.length - 1];

      if (lastMessage) return lastMessage.content;
      return '';
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
  @apply px-2;
  border: 1px solid transparent;
}
</style>
