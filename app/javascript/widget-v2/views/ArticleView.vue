<script setup>
import { computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useArticlesStore } from 'widget-v2/stores/articles';
import { useConfigStore } from 'widget-v2/stores/config';
import WidgetHeader from 'widget-v2/components/WidgetHeader.vue';
import BaseSpinner from 'widget-v2/components/base/BaseSpinner.vue';

const route = useRoute();
const articlesStore = useArticlesStore();
const configStore = useConfigStore();

const { formatMessage } = useMessageFormatter();

const article = computed(() => articlesStore.activeArticle);

// Article content is markdown; render it with the shared formatter.
const contentHtml = computed(() =>
  article.value ? formatMessage(article.value.content || '', false) : ''
);

const externalUrl = computed(() => {
  const portal = configStore.portal;
  if (!portal || !article.value) return '#';
  return `/hc/${portal.slug}/articles/${article.value.slug}`;
});

onMounted(() => articlesStore.open(route.params.slug));
</script>

<template>
  <div class="flex flex-col h-full bg-cw-solid">
    <WidgetHeader :title="article?.title || $t('HELP.TITLE')" show-back>
      <template #actions>
        <a
          :href="externalUrl"
          target="_blank"
          rel="noreferrer noopener"
          class="flex items-center justify-center w-8 h-8 rounded-full text-cw-text-muted hover:bg-cw-muted outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
          :aria-label="$t('HELP.OPEN_IN_NEW_TAB')"
        >
          <span class="i-ph-arrow-square-out" />
        </a>
      </template>
    </WidgetHeader>

    <div class="flex-1 overflow-y-auto scrollbar-thin px-5 py-5">
      <div v-if="articlesStore.loading" class="flex justify-center py-8">
        <BaseSpinner />
      </div>
      <article v-else-if="article" class="mx-auto max-w-2xl">
        <h1 class="text-lg font-620 text-cw-text type-display mb-3 sm:text-2xl">
          {{ article.title }}
        </h1>
        <!-- Same prose treatment as the help center portal renders articles
             with, so an article reads identically in both places. -->
        <div
          v-dompurify-html="contentHtml"
          class="prose max-w-none break-words text-cw-text prose-headings:font-620 prose-headings:text-cw-text prose-p:font-420 prose-li:font-420 prose-blockquote:font-420 prose-p:text-cw-text prose-li:text-cw-text prose-strong:text-cw-text prose-a:text-cw-primary prose-a:underline [&_li>p]:m-0 [&_img]:rounded-token-sm [&_img]:max-w-full [&_.tableWrapper]:overflow-x-auto [&_pre]:overflow-x-auto"
        />
      </article>
    </div>
  </div>
</template>
