<script setup>
import ConversationWorkflowCard from './ConversationWorkflowCard.vue';

defineProps({
  lockToSingleConversation: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['update']);
</script>

<template>
  <div class="grid grid-cols-1 gap-4 w-full sm:grid-cols-2">
    <ConversationWorkflowCard
      :active="!lockToSingleConversation"
      :title="$t('INBOX_MGMT.EDIT.LOCK_TO_SINGLE_CONVERSATION.DISABLED')"
      :description="
        $t('INBOX_MGMT.EDIT.LOCK_TO_SINGLE_CONVERSATION.DISABLED_DESCRIPTION')
      "
      radio-name="conversation-workflow"
      @click="$emit('update', false)"
    />

    <ConversationWorkflowCard
      :active="lockToSingleConversation"
      :title="$t('INBOX_MGMT.EDIT.LOCK_TO_SINGLE_CONVERSATION.ENABLED')"
      :description="
        $t('INBOX_MGMT.EDIT.LOCK_TO_SINGLE_CONVERSATION.ENABLED_DESCRIPTION')
      "
      radio-name="conversation-workflow"
      @click="$emit('update', true)"
    />
  </div>
</template>
