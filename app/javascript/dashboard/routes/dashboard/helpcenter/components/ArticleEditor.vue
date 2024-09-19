<script setup>
import { computed, defineEmits } from 'vue';
import { debounce } from '@chatwoot/utils';
import ResizableTextArea from 'shared/components/ResizableTextArea.vue';
import FullEditor from 'dashboard/components/widgets/WootWriter/FullEditor.vue';
import { ARTICLE_EDITOR_MENU_OPTIONS } from 'dashboard/constants/editor';

const { article } = defineProps({
  article: {
    type: Object,
    default: () => ({}),
  },
});
const emit = defineEmits(['saveArticle']);

const saveArticle = debounce(value => emit('saveArticle', value), 400, false);

const articleTitle = computed({
  get: () => article.title,
  set: title => {
    saveArticle({ title });
  },
});

const articleContent = computed({
  get: () => article.content,
  set: content => {
    saveArticle({ content });
  },
});
</script>

<template>
  <div class="edit-article--container">
    <ResizableTextArea
      v-model="articleTitle"
      type="text"
      :rows="1"
      class="article-heading"
      :placeholder="$t('HELP_CENTER.EDIT_ARTICLE.TITLE_PLACEHOLDER')"
    />
    <FullEditor
      v-model="articleContent"
      class="article-content"
      :placeholder="$t('HELP_CENTER.EDIT_ARTICLE.CONTENT_PLACEHOLDER')"
      :enabled-menu-options="ARTICLE_EDITOR_MENU_OPTIONS"
    />
  </div>
</template>

<style lang="scss" scoped>
.edit-article--container {
  @apply my-8 mx-auto py-0 max-w-[56rem] w-full;
}

.article-heading {
  @apply text-[2.5rem] font-semibold leading-normal w-full text-slate-900 dark:text-slate-75 p-4 hover:bg-slate-25 dark:hover:bg-slate-800 hover:rounded-md resize-none min-h-[4rem] max-h-[40rem] h-auto mb-2 border-0 border-solid border-transparent dark:border-transparent;
}

.article-content {
  @apply py-0 px-4 h-fit;
}

::v-deep {
  .ProseMirror-menubar-wrapper {
    .ProseMirror-woot-style {
      @apply min-h-[15rem] max-h-full;
    }
  }
}
</style>
