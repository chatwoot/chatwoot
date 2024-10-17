<script setup>
import { computed } from 'vue';
import { debounce } from '@chatwoot/utils';
import { useI18n } from 'vue-i18n';
import { ARTICLE_EDITOR_MENU_OPTIONS } from 'dashboard/constants/editor';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import FullEditor from 'dashboard/components/widgets/WootWriter/FullEditor.vue';
import Thumbnail from 'dashboard/components-next/thumbnail/Thumbnail.vue';

const props = defineProps({
  article: {
    type: Object,
    default: () => ({}),
  },
  isUpdating: {
    type: Boolean,
    default: false,
  },
  isSaved: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['saveArticle', 'goBack']);

const { t } = useI18n();

const statusText = computed(() => {
  return props.isUpdating
    ? t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.STATUS.SAVING')
    : t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.STATUS.SAVED');
});

const saveArticle = debounce(value => emit('saveArticle', value), 400, false);

const articleTitle = computed({
  get: () => props.article.title,
  set: title => {
    saveArticle({ title });
  },
});

const articleContent = computed({
  get: () => props.article.content,
  set: content => {
    saveArticle({ content });
  },
});

const author = computed(() => {
  return props.article?.author;
});

const authorName = computed(() => {
  return author.value?.name || author.value?.available_name || '-';
});

const authorThumbnailSrc = computed(() => {
  return author.value?.thumbnail;
});

const onClickGoBack = () => {
  emit('goBack');
};
</script>

<template>
  <HelpCenterLayout :show-header-title="false" :show-pagination-footer="false">
    <template #header-actions>
      <div class="flex items-center justify-between h-20">
        <Button
          :label="t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.BACK_TO_ARTICLES')"
          icon="chevron-lucide-left"
          icon-lib="lucide"
          variant="link"
          text-variant="info"
          size="sm"
          @click="onClickGoBack"
        />
        <div class="flex items-center gap-4">
          <span
            v-if="isUpdating || isSaved"
            class="text-xs font-medium transition-all duration-300 text-slate-500 dark:text-slate-400"
          >
            {{ statusText }}
          </span>
          <div class="flex items-center gap-2">
            <Button
              :label="t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.PREVIEW')"
              variant="secondary"
              size="sm"
            />
            <Button
              :label="t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.PUBLISH')"
              icon="chevron-lucide-down"
              icon-position="right"
              icon-lib="lucide"
              size="sm"
            />
          </div>
        </div>
      </div>
    </template>
    <template #content>
      <div class="flex flex-col gap-3 pl-4 mb-3 rtl:pr-3 rtl:pl-0">
        <TextArea
          v-model="articleTitle"
          class="h-12"
          custom-text-area-class="border-0 !text-[32px] !bg-transparent !py-0 !px-0 !h-auto !leading-[48px] !font-medium !tracking-[0.2px]"
          placeholder="Title"
        />
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-2">
            <Thumbnail
              v-if="author"
              :author="author"
              :name="authorName"
              :size="20"
              :src="authorThumbnailSrc"
            />
            <span class="text-sm text-slate-500 dark:text-slate-400">
              {{ authorName }}
            </span>
          </div>
          <div class="w-px h-3 bg-slate-50 dark:bg-slate-800" />
          <Button
            :label="
              t('HELP_CENTER.EDIT_ARTICLE_PAGE.EDIT_ARTICLE.UNCATEGORIZED')
            "
            icon="play-shape"
            variant="ghost"
            class="!px-2 font-normal"
            text-variant="info"
          />
          <div class="w-px h-3 bg-slate-50 dark:bg-slate-800" />
          <Button
            :label="
              t('HELP_CENTER.EDIT_ARTICLE_PAGE.EDIT_ARTICLE.MORE_PROPERTIES')
            "
            icon="add"
            variant="ghost"
            class="!px-2 font-normal"
          />
        </div>
      </div>
      <FullEditor
        v-model="articleContent"
        class="py-0 pb-10 pl-4 rtl:pr-4 rtl:pl-0 h-fit"
        :placeholder="
          t('HELP_CENTER.EDIT_ARTICLE_PAGE.EDIT_ARTICLE.EDITOR_PLACEHOLDER')
        "
        :enabled-menu-options="ARTICLE_EDITOR_MENU_OPTIONS"
      />
    </template>
  </HelpCenterLayout>
</template>

<style lang="scss" scoped>
::v-deep {
  .ProseMirror .empty-node::before {
    @apply text-slate-200 dark:text-slate-500 text-base;
  }

  .ProseMirror-menubar-wrapper {
    .ProseMirror-woot-style {
      @apply min-h-[15rem] max-h-full;
    }
  }

  .ProseMirror-menubar {
    display: none; // Hide by default
  }

  .editor-root .has-selection {
    .ProseMirror-menubar {
      @apply h-8 rounded-lg !px-2 z-50 bg-slate-50 dark:bg-slate-800 items-center gap-4 ml-0 mb-0 shadow-md border border-slate-75 dark:border-slate-700/50;
      display: flex;
      top: var(--selection-top, auto) !important;
      left: var(--selection-left, 0) !important;
      width: fit-content !important;
      position: absolute !important;

      .ProseMirror-menuitem {
        @apply mr-0;
        .ProseMirror-icon {
          @apply p-0 mt-1 !mr-0;
          svg {
            width: 20px !important;
            height: 20px !important;
          }
        }
      }
    }
  }
}
</style>
