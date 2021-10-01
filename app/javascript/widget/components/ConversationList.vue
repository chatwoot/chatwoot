<template>
  <div class="flex flex-col">
    <div
      class="divide-y divide-x-0 divide-slate-50 flex flex-col flex-1 overflow-auto h-full"
    >
      <conversation-item
        v-for="conversation in conversations"
        :key="conversation.id"
        :conversation="conversation"
      />
    </div>
    <custom-button
      class="font-medium rounded-full mt-8"
      :bg-color="widgetColor"
      :text-color="textColor"
      @click="startConversation"
    >
      <i class="ion-send" />
      {{ $t('START_CONVERSATION') }}
    </custom-button>
  </div>
</template>
<script>
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
  setup(props) {
    console.log(props);
  },
};
</script>
