<script setup>
import { ref, computed, watch } from 'vue';
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
  'goBack',
  'setAuthor',
  'setCategory',
  'previewArticle',
  'createArticle',
]);

const { t } = useI18n();

const isNewArticle = computed(() => !props.article?.id);

const localTitle = ref(props.article?.title ?? '');
const localContent = ref(props.article?.content ?? '');

// Sync local state when navigating to a different article or on initial fetch
watch(
  () => props.article?.id,
  newId => {
    if (newId) {
      localTitle.value = props.article?.title ?? '';
      localContent.value = props.article?.content ?? '';
    }
  }
);

const debouncedSave = debounce(value => emit('saveArticle', value), 500, false);

const handleSave = value => {
  if (isNewArticle.value) return;
  debouncedSave(value);
};

const articleTitle = computed({
  get: () => localTitle.value,
  set: value => {
    localTitle.value = value;
    handleSave({ title: value });
  },
});

const articleContent = computed({
  get: () => localContent.value,
  set: content => {
    localContent.value = content;
    handleSave({ content });
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

const handleCreateArticle = event => {
  if (!isNewArticle.value) return;
  const title = event?.target?.value || '';
  if (title.trim()) {
    emit('createArticle', { title, content: localContent.value });
  }
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
          @blur="handleCreateArticle"
        />
        <ArticleEditorControls
          :article="article"
          @save-article="values => emit('saveArticle', values)"
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
    @apply text-n-slate-10 text-base;
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
    .ProseMirror-menubar:not(:has(*)) {
      display: none !important;
    }

    .ProseMirror-menubar {
      @apply rounded-lg !px-3 !py-1.5 z-50 bg-n-background items-center gap-4 ml-0 mb-0 shadow-md outline outline-1 outline-n-weak;
      display: flex;
      top: var(--selection-top, auto) !important;
      left: var(--selection-left, 0) !important;
      width: fit-content !important;
      position: absolute !important;

      .ProseMirror-menuitem {
        @apply ltr:mr-0 rtl:ml-0 size-4 flex items-center;

        .ProseMirror-icon {
          @apply p-0.5 flex-shrink-0 ltr:mr-2 rtl:ml-2;
        }
      }

      .ProseMirror-menu-active {
        @apply bg-n-slate-3;
      }
    }
  }
}
</style>
