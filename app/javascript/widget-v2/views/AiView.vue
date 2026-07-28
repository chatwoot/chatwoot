<script setup>
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useConfigStore } from 'widget-v2/stores/config';
import { useConversationsStore } from 'widget-v2/stores/conversations';
import WidgetHeader from 'widget-v2/components/WidgetHeader.vue';
import ConversationCard from 'widget-v2/components/ConversationCard.vue';
import EmptyState from 'widget-v2/components/EmptyState.vue';
import BaseButton from 'widget-v2/components/base/BaseButton.vue';
import BaseAvatar from 'widget-v2/components/base/BaseAvatar.vue';

const router = useRouter();
const { t } = useI18n();
const configStore = useConfigStore();
const conversationsStore = useConversationsStore();

const aiAgent = computed(() => configStore.aiAgent);
const aiName = computed(
  () => aiAgent.value?.name || t('AI_STATE.AI_DEFAULT_NAME')
);

onMounted(() => {
  if (configStore.hasAiAgent) conversationsStore.loadSection('ai');
});
</script>

<template>
  <div class="flex flex-col h-full bg-cw-solid">
    <WidgetHeader :title="$t('AI.TITLE')" show-back />

    <div class="flex-1 overflow-y-auto scrollbar-thin">
      <div class="flex flex-col items-center px-6 pt-8 pb-6 text-center">
        <BaseAvatar :src="aiAgent?.avatar_url" :name="aiName" :size="56" />
        <h2 class="mt-3 text-base font-620 text-cw-text type-display">
          {{ aiName }}
        </h2>
        <p class="mt-1 text-sm text-cw-text-muted max-w-64">
          {{ aiAgent?.description || $t('AI.DESCRIPTION', { name: aiName }) }}
        </p>
        <BaseButton class="mt-4" @click="router.push({ name: 'ai-compose' })">
          <span class="i-ph-sparkle" />
          {{ $t('AI.NEW_CHAT') }}
        </BaseButton>
      </div>

      <template v-if="conversationsStore.aiConversations.length">
        <h3
          class="px-4 pt-2 pb-1 text-xs font-semibold uppercase tracking-wide text-cw-text-faint"
        >
          {{ $t('AI.PAST_CHATS') }}
        </h3>
        <ConversationCard
          v-for="conversation in conversationsStore.aiConversations"
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
      </template>
      <EmptyState
        v-else-if="!conversationsStore.sections.ai.loading"
        icon="i-ph-sparkle"
        :title="$t('AI.EMPTY_TITLE')"
        :description="$t('AI.EMPTY_DESCRIPTION')"
      />
    </div>
  </div>
</template>
