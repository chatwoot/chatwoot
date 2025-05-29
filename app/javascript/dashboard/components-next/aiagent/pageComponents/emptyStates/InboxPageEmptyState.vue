<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import InboxCard from 'dashboard/components-next/aiagent/assistant/InboxCard.vue';
import { inboxes } from 'dashboard/components-next/aiagent/pageComponents/emptyStates/aiagentEmptyStateContent.js';

const emit = defineEmits(['click']);

const onClick = () => {
  emit('click');
};
</script>

<template>
  <EmptyStateLayout
    :title="$t('AIAGENT.INBOXES.EMPTY_STATE.TITLE')"
    :subtitle="$t('AIAGENT.INBOXES.EMPTY_STATE.SUBTITLE')"
    :action-perms="['administrator']"
  >
    <template #empty-state-item>
      <div class="grid grid-cols-1 gap-4 p-px overflow-hidden">
        <InboxCard
          v-for="(inbox, index) in inboxes.slice(0, 5)"
          :id="inbox.id"
          :key="`inbox-${index}`"
          :inbox="inbox"
        />
      </div>
    </template>
    <template #actions>
      <Button
        :label="$t('AIAGENT.INBOXES.ADD_NEW')"
        icon="i-lucide-plus"
        @click="onClick"
      />
    </template>
  </EmptyStateLayout>
</template>
