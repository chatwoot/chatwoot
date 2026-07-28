<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useConfigStore } from 'widget-v2/stores/config';
import { useConversationsStore } from 'widget-v2/stores/conversations';
import { useArticlesStore } from 'widget-v2/stores/articles';
import { useUiStore } from 'widget-v2/stores/ui';
import { useAvailability } from 'widget-v2/composables/useAvailability';
import { isWebUrl } from 'widget-v2/helpers/urlHelpers';
import HomeComposer from 'widget-v2/components/HomeComposer.vue';
import HomeSection from 'widget-v2/components/HomeSection.vue';
import ConversationCard from 'widget-v2/components/ConversationCard.vue';
import ArticleCard from 'widget-v2/components/ArticleCard.vue';
import NoticeBanner from 'widget-v2/components/NoticeBanner.vue';
import BrandLinks from 'widget-v2/components/BrandLinks.vue';
import BlogPosts from 'widget-v2/components/BlogPosts.vue';
import BaseAvatar from 'widget-v2/components/base/BaseAvatar.vue';
import BrandingFooter from 'widget-v2/components/BrandingFooter.vue';

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

// Picking up where you left off is the returning visitor's main job, so the
// two most recent threads sit above everything a first-time visitor needs.
const CONTINUE_LIMIT = 2;
const ongoing = computed(() =>
  [
    ...conversationsStore.humanConversations,
    ...conversationsStore.aiConversations,
  ]
    .filter(conversation => conversation.status !== 'resolved')
    .sort((a, b) => (b.last_activity_at || 0) - (a.last_activity_at || 0))
    .slice(0, CONTINUE_LIMIT)
);

const starting = ref(false);

onMounted(() => {
  conversationsStore.loadSection('human');
  if (configStore.hasAiAgent) conversationsStore.loadSection('ai');
  articlesStore.loadPopular();
});

const openConversation = id =>
  router.push({ name: 'conversation-detail', params: { id } });

const preChatFields = computed(() => {
  if (!channel.value.pre_chat_form_enabled) return [];
  const options = channel.value.pre_chat_form_options || {};
  return (options.pre_chat_fields || []).filter(field => field.enabled);
});

// The draft goes straight out unless the inbox asks for details first, in
// which case the compose screen collects them with the message carried over.
const startConversation = async ({ content, section }) => {
  if (starting.value) return;
  if (section === 'human' && preChatFields.value.length) {
    router.push({ name: 'compose', query: { draft: content } });
    return;
  }

  starting.value = true;
  try {
    const conversation = await conversationsStore.create({ section, content });
    router.push({
      name: 'conversation-detail',
      params: { id: conversation.id },
    });
  } finally {
    starting.value = false;
  }
};
</script>

<template>
  <div
    class="flex flex-col h-full overflow-y-auto scrollbar-thin bg-cw-background"
  >
    <header :class="hasCover ? 'pb-5' : 'px-6 pt-7 pb-5'">
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
          <BaseAvatar
            :src="logoUrl"
            :name="channel.website_name"
            :size="hasCover ? 56 : 48"
            class="shadow-sm"
            :class="hasCover ? 'ring-4 ring-cw-solid' : 'ring-2 ring-cw-solid'"
          />
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
        <!-- Availability answers the visitor's first question, so it reads as
             a line of the greeting rather than fine print on a button. -->
        <p class="flex items-center gap-1.5 mt-2 text-xs text-cw-text-muted">
          <span
            class="w-1.5 h-1.5 rounded-full"
            :class="isOnline ? 'bg-n-teal-9' : 'bg-cw-text-faint'"
          />
          {{
            isOnline
              ? $t(`HOME.REPLY_TIME.${replyTimeKey}`)
              : $t('AVAILABILITY.TEAM_AWAY')
          }}
        </p>
      </div>
    </header>

    <div class="flex flex-col stack-gap px-4 pb-24">
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

      <HomeComposer @submit="startConversation" />

      <section v-if="ongoing.length" class="surface-card overflow-hidden">
        <ConversationCard
          v-for="(conversation, index) in ongoing"
          :key="conversation.id"
          :conversation="conversation"
          :class="{ 'border-t border-cw-hairline': index }"
          @click="openConversation(conversation.id)"
        />
      </section>

      <HomeSection
        v-if="configStore.portal && articlesStore.popularArticles.length"
        :label="$t('HOME.SUGGESTED')"
      >
        <ArticleCard
          v-for="article in articlesStore.popularArticles"
          :key="article.id"
          :article="article"
          flat
          @click="
            router.push({
              name: 'help-article',
              params: { slug: article.slug },
            })
          "
        />
        <button
          type="button"
          class="group flex items-center gap-1 self-start px-2 py-2 text-xs font-520 text-cw-text-muted rounded-token-sm transition-colors hover:text-cw-text outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
          @click="router.push({ name: 'help' })"
        >
          {{ $t('HOME.BROWSE_ARTICLES') }}
          <span
            class="i-ph-caret-right transition-transform group-hover:translate-x-0.5"
          />
        </button>
      </HomeSection>

      <BlogPosts v-if="configStore.hostPosts" :posts="configStore.hostPosts" />

      <BrandLinks v-if="configStore.hostBrand" :brand="configStore.hostBrand" />

      <BrandingFooter />
    </div>
  </div>
</template>
