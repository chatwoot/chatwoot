<script setup>
import { onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useConversationsStore } from 'widget-v2/stores/conversations';
import WidgetHeader from 'widget-v2/components/WidgetHeader.vue';
import ConversationCard from 'widget-v2/components/ConversationCard.vue';
import EmptyState from 'widget-v2/components/EmptyState.vue';
import BaseSpinner from 'widget-v2/components/base/BaseSpinner.vue';

const router = useRouter();
const conversationsStore = useConversationsStore();

onMounted(() => conversationsStore.loadSection('resolved'));

const section = conversationsStore.sections.resolved;
</script>

<template>
  <div class="flex flex-col h-full bg-cw-solid">
    <WidgetHeader :title="$t('CONVERSATIONS.RESOLVED_TITLE')" show-back />

    <div class="flex-1 overflow-y-auto scrollbar-thin">
      <EmptyState
        v-if="
          !section.loading && !conversationsStore.resolvedConversations.length
        "
        icon="i-ph-check-circle"
        :title="$t('CONVERSATIONS.RESOLVED_EMPTY_TITLE')"
        :description="$t('CONVERSATIONS.RESOLVED_EMPTY_DESCRIPTION')"
      />

      <template v-else>
        <ConversationCard
          v-for="conversation in conversationsStore.resolvedConversations"
          :key="conversation.id"
          :conversation="conversation"
          class="border-b border-cw-hairline last:border-b-0"
          @click="
            router.push({
              name: 'conversation-detail',
              params: { id: conversation.id },
            })
          "
        />
        <div v-if="section.loading" class="flex justify-center py-4">
          <BaseSpinner />
        </div>
        <button
          v-else-if="
            section.hasNextPage &&
            conversationsStore.resolvedConversations.length
          "
          type="button"
          class="w-full py-3 text-xs font-medium text-cw-text-muted hover:text-cw-text outline-none focus-visible:ring-[3px] focus-visible:ring-inset focus-visible:ring-cw-ring"
          @click="conversationsStore.loadSection('resolved')"
        >
          {{ $t('CONVERSATIONS.LOAD_MORE') }}
        </button>
      </template>
    </div>
  </div>
</template>
