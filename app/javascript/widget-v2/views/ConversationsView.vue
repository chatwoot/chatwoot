<script setup>
import { onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useConversationsStore } from 'widget-v2/stores/conversations';
import WidgetHeader from 'widget-v2/components/WidgetHeader.vue';
import ConversationCard from 'widget-v2/components/ConversationCard.vue';
import EmptyState from 'widget-v2/components/EmptyState.vue';
import BaseButton from 'widget-v2/components/base/BaseButton.vue';
import BaseSpinner from 'widget-v2/components/base/BaseSpinner.vue';
import BrandingFooter from 'widget-v2/components/BrandingFooter.vue';

const router = useRouter();
const conversationsStore = useConversationsStore();

onMounted(() => conversationsStore.loadSection('human'));

const section = conversationsStore.sections.human;
</script>

<template>
  <div class="flex flex-col h-full bg-cw-solid">
    <WidgetHeader :title="$t('CONVERSATIONS.TITLE')" show-back>
      <template #actions>
        <button
          type="button"
          class="flex items-center justify-center w-8 h-8 rounded-full text-cw-primary hover:bg-cw-primary-soft outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
          :aria-label="$t('CONVERSATIONS.NEW')"
          @click="router.push({ name: 'compose' })"
        >
          <span class="i-ph-note-pencil text-lg" />
        </button>
      </template>
    </WidgetHeader>

    <div class="flex-1 overflow-y-auto scrollbar-thin">
      <EmptyState
        v-if="!section.loading && !conversationsStore.humanConversations.length"
        icon="i-ph-chat-circle"
        :title="$t('CONVERSATIONS.EMPTY_TITLE')"
        :description="$t('CONVERSATIONS.EMPTY_DESCRIPTION')"
      >
        <BaseButton
          size="sm"
          class="mt-2"
          @click="router.push({ name: 'compose' })"
        >
          {{ $t('CONVERSATIONS.NEW') }}
        </BaseButton>
      </EmptyState>

      <template v-else>
        <ConversationCard
          v-for="conversation in conversationsStore.humanConversations"
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
            section.hasNextPage && conversationsStore.humanConversations.length
          "
          type="button"
          class="w-full py-3 text-xs font-medium text-cw-text-muted hover:text-cw-text outline-none focus-visible:ring-[3px] focus-visible:ring-inset focus-visible:ring-cw-ring"
          @click="conversationsStore.loadSection('human')"
        >
          {{ $t('CONVERSATIONS.LOAD_MORE') }}
        </button>
      </template>

      <button
        type="button"
        class="group flex items-center justify-center w-full gap-1.5 py-3.5 text-sm font-medium text-cw-text-muted border-t border-cw-hairline transition-colors hover:text-cw-text hover:bg-cw-surface outline-none focus-visible:ring-[3px] focus-visible:ring-inset focus-visible:ring-cw-ring"
        @click="router.push({ name: 'conversations-resolved' })"
      >
        <span class="i-ph-clock-counter-clockwise" />
        {{ $t('CONVERSATIONS.SHOW_OLDER') }}
      </button>

      <BrandingFooter />
    </div>
  </div>
</template>
