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
  <div class="flex flex-col h-full bg-cw-background">
    <WidgetHeader :title="article?.title || $t('HELP.TITLE')" show-back>
      <template #actions>
        <a
          :href="externalUrl"
          target="_blank"
          rel="noreferrer noopener"
          class="flex items-center justify-center w-8 h-8 rounded-full text-cw-text-muted hover:bg-cw-muted outline-none focus-visible:ring-2 focus-visible:ring-cw-primary"
          :aria-label="$t('HELP.OPEN_IN_NEW_TAB')"
        >
          <span class="i-lucide-external-link" />
        </a>
      </template>
    </WidgetHeader>

    <div class="flex-1 overflow-y-auto scrollbar-thin px-5 py-5">
      <div v-if="articlesStore.loading" class="flex justify-center py-8">
        <BaseSpinner />
      </div>
      <article v-else-if="article">
        <h1 class="text-lg font-semibold text-cw-text font-interDisplay mb-3">
          {{ article.title }}
        </h1>
        <div
          v-dompurify-html="contentHtml"
          class="prose prose-bubble max-w-none text-sm text-cw-text [&_a]:text-cw-primary [&_img]:rounded-token-sm [&_img]:max-w-full"
        />
      </article>
    </div>
  </div>
</template>
