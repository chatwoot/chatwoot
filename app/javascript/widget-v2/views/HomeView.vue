<script setup>
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useConfigStore } from 'widget-v2/stores/config';
import { useConversationsStore } from 'widget-v2/stores/conversations';
import { useArticlesStore } from 'widget-v2/stores/articles';
import { useUiStore } from 'widget-v2/stores/ui';
import { useAvailability } from 'widget-v2/composables/useAvailability';
import { isWebUrl } from 'widget-v2/helpers/urlHelpers';
import ConversationCard from 'widget-v2/components/ConversationCard.vue';
import ArticleCard from 'widget-v2/components/ArticleCard.vue';
import NoticeBanner from 'widget-v2/components/NoticeBanner.vue';
import BrandLinks from 'widget-v2/components/BrandLinks.vue';
import BlogPosts from 'widget-v2/components/BlogPosts.vue';
import BaseAvatar from 'widget-v2/components/base/BaseAvatar.vue';

const router = useRouter();
const configStore = useConfigStore();
const conversationsStore = useConversationsStore();
const articlesStore = useArticlesStore();
const uiStore = useUiStore();
const { isOnline, replyTimeKey } = useAvailability();

const channel = computed(() => configStore.channel);

// Brand hero: the widget lives on the customer's site, so the hero can carry
// their cover image (or color band) and logo, all host-configured.
const brand = computed(() => configStore.hostBrand || {});
const coverImage = computed(() =>
  isWebUrl(brand.value.coverImage) ? brand.value.coverImage : null
);
const coverColor = computed(() =>
  /^#(?:[0-9a-f]{3}|[0-9a-f]{6})$/i.test(brand.value.coverColor || '')
    ? brand.value.coverColor
    : null
);
const hasCover = computed(() => Boolean(coverImage.value || coverColor.value));
const logoUrl = computed(() =>
  isWebUrl(brand.value.logo) ? brand.value.logo : channel.value.avatar_url
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
    <header :class="hasCover ? 'pb-6' : 'px-6 pt-7 pb-6'">
      <div v-if="hasCover" class="relative h-28">
        <img
          v-if="coverImage"
          :src="coverImage"
          alt=""
          class="absolute inset-0 w-full h-full object-cover"
        />
        <div
          v-else
          class="absolute inset-0"
          :style="{ backgroundColor: coverColor }"
        />
        <button
          type="button"
          class="absolute top-3 right-3 flex items-center justify-center w-8 h-8 rounded-full bg-cw-solid text-cw-text-muted shadow-sm outline-none transition-colors hover:text-cw-text focus-visible:ring-[3px] focus-visible:ring-cw-ring"
          :aria-label="$t('COMMON.CLOSE')"
          @click="uiStore.close()"
        >
          <span class="i-ph-x text-lg" />
        </button>
      </div>

      <div :class="hasCover ? 'px-6 -mt-7 relative' : ''">
        <div class="flex items-start justify-between">
          <span class="relative inline-flex">
            <BaseAvatar
              :src="logoUrl"
              :name="channel.website_name"
              :size="hasCover ? 56 : 48"
              class="shadow-sm"
              :class="
                hasCover ? 'ring-4 ring-cw-solid' : 'ring-2 ring-cw-solid'
              "
            />
            <span
              v-if="isOnline"
              class="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-n-teal-9 ring-2 ring-cw-solid"
              :title="$t('AVAILABILITY.ONLINE')"
            />
          </span>
          <button
            v-if="!hasCover"
            type="button"
            class="flex items-center justify-center w-8 h-8 rounded-full text-cw-text-muted hover:bg-cw-muted outline-none transition-colors focus-visible:ring-[3px] focus-visible:ring-cw-ring"
            :aria-label="$t('COMMON.CLOSE')"
            @click="uiStore.close()"
          >
            <span class="i-ph-x text-lg" />
          </button>
        </div>
        <h1 class="mt-5 text-2xl font-620 text-cw-text type-display">
          {{ channel.welcome_title || $t('HOME.GREETING') }}
        </h1>
        <p
          v-if="channel.welcome_tagline"
          class="mt-1.5 text-sm leading-relaxed text-cw-text-muted max-w-72"
        >
          {{ channel.welcome_tagline }}
        </p>
      </div>
    </header>

    <div class="flex flex-col gap-4 px-4 pb-6">
      <NoticeBanner
        v-for="announcement in configStore.announcements"
        :key="announcement.id"
        :notice="{
          title: announcement.title,
          message: announcement.message,
          level: announcement.level,
          url: announcement.action_url,
        }"
      />

      <NoticeBanner
        v-if="configStore.hostNotice"
        :notice="configStore.hostNotice"
      />

      <section class="surface-card overflow-hidden">
        <ConversationCard
          v-if="recentConversation"
          :conversation="recentConversation"
          @click="openConversation(recentConversation.id)"
        />
        <button
          type="button"
          class="group flex items-center w-full gap-3.5 px-4 py-4 text-left transition-colors hover:bg-cw-surface outline-none focus-visible:ring-[3px] focus-visible:ring-inset focus-visible:ring-cw-ring"
          :class="{ 'border-t border-cw-hairline': recentConversation }"
          @click="router.push({ name: 'compose' })"
        >
          <span
            class="flex items-center justify-center w-9 h-9 rounded-full bg-cw-primary text-cw-primary-foreground shadow-sm"
          >
            <span class="i-ph-paper-plane-tilt-fill text-sm" />
          </span>
          <span class="flex-1">
            <span class="block text-sm font-520 text-cw-text">
              {{ $t('HOME.START_CONVERSATION') }}
            </span>
            <span class="block mt-0.5 text-xs text-cw-text-muted">
              {{
                isOnline
                  ? $t(`HOME.REPLY_TIME.${replyTimeKey}`)
                  : $t('AVAILABILITY.TEAM_AWAY')
              }}
            </span>
          </span>
          <span
            class="i-ph-caret-right text-cw-text-faint transition-transform group-hover:translate-x-0.5"
          />
        </button>
      </section>

      <section
        v-if="configStore.hasAiAgent"
        class="surface-card overflow-hidden"
      >
        <button
          type="button"
          class="group flex items-center w-full gap-3.5 px-4 py-4 text-left transition-colors hover:bg-cw-surface outline-none focus-visible:ring-[3px] focus-visible:ring-inset focus-visible:ring-cw-ring"
          @click="router.push({ name: 'ai-compose' })"
        >
          <span
            class="flex items-center justify-center w-9 h-9 rounded-full bg-cw-primary-soft text-cw-primary"
          >
            <span class="i-ph-sparkle-fill text-sm" />
          </span>
          <span class="flex-1">
            <span class="block text-sm font-520 text-cw-text">
              {{ $t('AI.NEW_CHAT') }}
            </span>
            <span class="block mt-0.5 text-xs text-cw-text-muted">
              {{ $t('AI.DESCRIPTION', { name: configStore.aiAgent.name }) }}
            </span>
          </span>
          <span
            class="i-ph-caret-right text-cw-text-faint transition-transform group-hover:translate-x-0.5"
          />
        </button>
      </section>

      <section
        v-if="configStore.portal && articlesStore.popularArticles.length"
        class="surface-card overflow-hidden"
      >
        <h2 class="px-4 pt-4 pb-1 type-overline text-cw-text-faint">
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

      <BlogPosts v-if="configStore.hostPosts" :posts="configStore.hostPosts" />

      <BrandLinks v-if="configStore.hostBrand" :brand="configStore.hostBrand" />
    </div>
  </div>
</template>
