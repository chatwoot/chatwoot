<script setup>
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useConfigStore } from 'widget-v2/stores/config';
import { useConversationsStore } from 'widget-v2/stores/conversations';
import { useArticlesStore } from 'widget-v2/stores/articles';
import { useUiStore } from 'widget-v2/stores/ui';
import ConversationCard from 'widget-v2/components/ConversationCard.vue';
import ArticleCard from 'widget-v2/components/ArticleCard.vue';
import BaseAvatar from 'widget-v2/components/base/BaseAvatar.vue';

const router = useRouter();
const configStore = useConfigStore();
const conversationsStore = useConversationsStore();
const articlesStore = useArticlesStore();
const uiStore = useUiStore();

const channel = computed(() => configStore.channel);
const replyTimeKey = computed(
  () => channel.value.reply_time || 'in_a_few_minutes'
);

const recentConversation = computed(
  () => conversationsStore.humanConversations[0]
);

onMounted(() => {
  conversationsStore.loadSection('human');
  articlesStore.loadPopular();
});

const openConversation = id =>
  router.push({ name: 'conversation-detail', params: { id } });
</script>

<template>
  <div
    class="flex flex-col h-full overflow-y-auto scrollbar-thin bg-cw-background"
  >
    <header class="px-5 pt-6 pb-5">
      <div class="flex items-start justify-between">
        <BaseAvatar
          :src="channel.avatar_url"
          :name="channel.website_name"
          :size="44"
        />
        <button
          type="button"
          class="flex items-center justify-center w-8 h-8 rounded-full text-cw-text-muted hover:bg-cw-muted outline-none focus-visible:ring-2 focus-visible:ring-cw-primary"
          :aria-label="$t('COMMON.CLOSE')"
          @click="uiStore.close()"
        >
          <span class="i-lucide-x text-lg" />
        </button>
      </div>
      <h1 class="mt-4 text-xl font-semibold text-cw-text font-interDisplay">
        {{ channel.welcome_title || $t('HOME.GREETING') }}
      </h1>
      <p v-if="channel.welcome_tagline" class="mt-1 text-sm text-cw-text-muted">
        {{ channel.welcome_tagline }}
      </p>
    </header>

    <div class="flex flex-col gap-3 px-4 pb-6">
      <section class="border border-cw-border rounded-token overflow-hidden">
        <ConversationCard
          v-if="recentConversation"
          :conversation="recentConversation"
          @click="openConversation(recentConversation.id)"
        />
        <button
          type="button"
          class="flex items-center w-full gap-3 px-4 py-3.5 text-left transition-colors hover:bg-cw-surface outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cw-primary"
          :class="{ 'border-t border-cw-border': recentConversation }"
          @click="router.push({ name: 'compose' })"
        >
          <span
            class="flex items-center justify-center w-8 h-8 rounded-full bg-cw-primary text-cw-primary-foreground"
          >
            <span class="i-lucide-send" />
          </span>
          <span class="flex-1">
            <span class="block text-sm font-medium text-cw-text">
              {{ $t('HOME.START_CONVERSATION') }}
            </span>
            <span class="block text-xs text-cw-text-muted">
              {{ $t(`HOME.REPLY_TIME.${replyTimeKey}`) }}
            </span>
          </span>
          <span class="i-lucide-chevron-right text-cw-text-faint" />
        </button>
      </section>

      <section
        v-if="configStore.hasAiAgent"
        class="border border-cw-border rounded-token overflow-hidden"
      >
        <button
          type="button"
          class="flex items-center w-full gap-3 px-4 py-3.5 text-left transition-colors hover:bg-cw-surface outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cw-primary"
          @click="router.push({ name: 'ai-compose' })"
        >
          <span
            class="flex items-center justify-center w-8 h-8 rounded-full bg-cw-primary-soft text-cw-primary"
          >
            <span class="i-lucide-sparkles" />
          </span>
          <span class="flex-1">
            <span class="block text-sm font-medium text-cw-text">
              {{ $t('AI.NEW_CHAT') }}
            </span>
            <span class="block text-xs text-cw-text-muted">
              {{ $t('AI.DESCRIPTION', { name: configStore.aiAgent.name }) }}
            </span>
          </span>
          <span class="i-lucide-chevron-right text-cw-text-faint" />
        </button>
      </section>

      <section
        v-if="configStore.portal && articlesStore.popularArticles.length"
        class="border border-cw-border rounded-token overflow-hidden"
      >
        <h2
          class="px-4 pt-3 pb-1 text-xs font-semibold uppercase tracking-wide text-cw-text-faint"
        >
          {{ $t('HOME.POPULAR_ARTICLES') }}
        </h2>
        <ArticleCard
          v-for="article in articlesStore.popularArticles"
          :key="article.id"
          :article="article"
          @click="
            router.push({
              name: 'help-article',
              params: { slug: article.slug },
            })
          "
        />
      </section>
    </div>
  </div>
</template>
