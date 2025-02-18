<script setup>
import { computed } from 'vue';
import { debounce } from '@chatwoot/utils';
import { useI18n } from 'vue-i18n';
import { ARTICLE_EDITOR_MENU_OPTIONS } from 'dashboard/constants/editor';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import FullEditor from 'dashboard/components/widgets/WootWriter/FullEditor.vue';
import ArticleEditorHeader from 'dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleEditorHeader.vue';
import ArticleEditorControls from 'dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleEditorControls.vue';

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

const emit = defineEmits([
  'saveArticle',
  'saveArticleAsync',
  'goBack',
  'setAuthor',
  'setCategory',
  'previewArticle',
]);

const { t } = useI18n();

const saveAndSync = value => {
  emit('saveArticle', value);
};

// this will only send the data to the backend
// but will not update the local state preventing unnecessary re-renders
// since the data is already saved and we keep the editor text as the source of truth
const quickSave = debounce(
  value => emit('saveArticleAsync', value),
  400,
  false
);

// 2.5 seconds is enough to know that the user has stopped typing and is taking a pause
// so we can save the data to the backend and retrieve the updated data
// this will update the local state with response data
const saveAndSyncDebounced = debounce(saveAndSync, 2500, false);

const articleTitle = computed({
  get: () => props.article.title,
  set: value => {
    quickSave({ title: value });
    saveAndSyncDebounced({ title: value });
  },
});

const articleContent = computed({
  get: () => props.article.content,
  set: content => {
    quickSave({ content });
    saveAndSyncDebounced({ content });
  },
});

const onClickGoBack = () => {
  emit('goBack');
};

const setAuthorId = authorId => {
  emit('setAuthor', authorId);
};

const setCategoryId = categoryId => {
  emit('setCategory', categoryId);
};

const previewArticle = () => {
  emit('previewArticle');
};
</script>

<template>
  <HelpCenterLayout :show-header-title="false" :show-pagination-footer="false">
    <template #header-actions>
      <ArticleEditorHeader
        :is-updating="isUpdating"
        :is-saved="isSaved"
        :status="article.status"
        :article-id="article.id"
        @go-back="onClickGoBack"
        @preview-article="previewArticle"
      />
    </template>
    <template #content>
      <div class="flex flex-col gap-3 pl-4 mb-3 rtl:pr-3 rtl:pl-0">
        <TextArea
          v-model="articleTitle"
          auto-height
          min-height="4rem"
          custom-text-area-class="!text-[32px] !leading-[48px] !font-medium !tracking-[0.2px]"
          custom-text-area-wrapper-class="border-0 !bg-transparent dark:!bg-transparent !py-0 !px-0"
          placeholder="Title"
          autofocus
        />
        <ArticleEditorControls
          :article="article"
          @save-article="saveAndSync"
          @set-author="setAuthorId"
          @set-category="setCategoryId"
        />
      </div>
      <FullEditor
        v-model="articleContent"
        class="py-0 pb-10 pl-4 rtl:pr-4 rtl:pl-0 h-fit"
        :placeholder="
          t('HELP_CENTER.EDIT_ARTICLE_PAGE.EDIT_ARTICLE.EDITOR_PLACEHOLDER')
        "
        :enabled-menu-options="ARTICLE_EDITOR_MENU_OPTIONS"
        :autofocus="false"
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
