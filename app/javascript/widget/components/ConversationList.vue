<template>
  <div class="flex flex-col">
    <div
      class="divide-y divide-x-0 divide-slate-50 flex flex-col flex-1 overflow-auto h-full"
    >
      <conversation-item
        v-for="conversation in conversations"
        :key="conversation.id"
        :conversation="conversation"
        :unread-count="unreadCount(conversation.id)"
      />
    </div>
    <custom-button
      class="font-medium rounded-full mt-8"
      :bg-color="widgetColor.value"
      :text-color="textColor.value"
      @click="startConversationClick"
    >
      <i class="ion-send" />
      {{ $t('START_CONVERSATION') }}
    </custom-button>
  </div>
</template>
<script>
import { computed } from '@vue/composition-api';
import { getContrastingTextColor } from '@chatwoot/utils';

import CustomButton from 'shared/components/Button';
import ConversationItem from './ConversationItem';

export default {
  components: { ConversationItem, CustomButton },
  props: {
    conversations: {
      type: Array,
      default: () => [],
    },
  },
  setup(props, context) {
    const router = context.root.$router;
    const store = context.root.$store;
    const widgetColor = computed(() => {
      return store.getters['appConfig/getWidgetColor'];
    });
    const textColor = computed(() =>
      getContrastingTextColor(widgetColor.value)
    );

    const startConversationClick = async () => {
      const conversationId = await context.root.$store.dispatch(
        'conversationV2/createConversation'
      );

      router.push({
        name: 'chat',
        params: {
          conversationId: conversationId,
        },
      });
    };

    const unreadCount = conversationId => {
      const count =
        context.root.$store.getters['conversationV2/unreadTextMessagesCountIn'](
          conversationId
        ) || 0;
      return count;
    };

    return {
      textColor,
      widgetColor,
      unreadCount,
      startConversationClick,
    };
  },
};
</script>
