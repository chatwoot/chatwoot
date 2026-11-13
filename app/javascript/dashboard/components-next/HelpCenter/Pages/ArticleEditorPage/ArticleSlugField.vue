<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { convertToArticleSlug } from 'dashboard/helper/commons';

import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Banner from 'dashboard/components-next/banner/Banner.vue';

const props = defineProps({
  article: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['saveSlug', 'previewArticle']);

const { t } = useI18n();
const uiFlags = useMapGetter('articles/uiFlags');

// The generated timestamp prefix keeps slugs globally unique, so only the rest is editable.
const slugPrefix = computed(
  () => props.article.slug.match(/^\d{10}-/)?.[0] || ''
);
const slugSuffix = computed(() =>
  props.article.slug.slice(slugPrefix.value.length)
);

const slug = ref('');
const isUpdated = ref(false);

const newSlug = computed(() => convertToArticleSlug(slug.value));
const titleSlug = computed(() =>
  convertToArticleSlug(props.article.draftTitle ?? props.article.title)
);
const isChanged = computed(
  () => !!newSlug.value && newSlug.value !== slugSuffix.value
);
const canUseTitle = computed(
  () => !!titleSlug.value && titleSlug.value !== newSlug.value
);
const isUpdating = computed(() => uiFlags.value(props.article.id).isUpdating);

const resetSlug = () => {
  slug.value = slugSuffix.value;
};

watch(
  () => props.article.slug,
  (_slug, previousSlug) => {
    resetSlug();
    isUpdated.value = !!previousSlug;
  },
  { immediate: true }
);

const normalizeSlug = () => {
  slug.value = newSlug.value || slugSuffix.value;
};

const saveSlug = () => {
  if (!isChanged.value || isUpdating.value) return;
  emit('saveSlug', `${slugPrefix.value}${newSlug.value}`);
};
</script>

<template>
  <div>
    <div class="flex items-center w-full gap-3 py-2">
      <label
        for="article-slug"
        class="mb-0.5 text-sm font-medium whitespace-nowrap min-w-[7.5rem] text-n-slate-12"
      >
        {{ t('HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.SLUG') }}
      </label>
      <div class="flex items-center flex-1 min-w-0">
        <span class="flex-shrink-0 text-sm text-n-slate-10">
          {{ slugPrefix }}
        </span>
        <InlineInput
          id="article-slug"
          v-model="slug"
          :disabled="isUpdating"
          :placeholder="
            t(
              'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.SLUG_PLACEHOLDER'
            )
          "
          @enter-press="saveSlug"
          @escape-press="resetSlug"
          @blur="normalizeSlug"
        />
        <Button
          v-if="canUseTitle"
          v-tooltip.top="
            t('HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.SLUG_USE_TITLE')
          "
          icon="i-lucide-refresh-cw"
          size="xs"
          variant="ghost"
          color="slate"
          class="flex-shrink-0"
          :disabled="isUpdating"
          @click="slug = titleSlug"
        />
      </div>
    </div>
    <Banner
      v-if="isChanged"
      color="amber"
      class="mb-2"
      :action-label="
        t('HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.SLUG_UPDATE')
      "
      :is-loading="isUpdating"
      @action="saveSlug"
    >
      {{ t('HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.SLUG_WARNING') }}
    </Banner>
    <Banner
      v-else-if="isUpdated"
      color="teal"
      class="mb-2"
      :action-label="
        t('HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.SLUG_OPEN')
      "
      @action="emit('previewArticle')"
    >
      {{ t('HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.SLUG_UPDATED') }}
    </Banner>
  </div>
</template>
