<template>
  <div class="edit-article--container">
    <resizable-text-area
      v-model="articleTitle"
      type="text"
      :rows="1"
      class="article-heading"
      :placeholder="$t('HELP_CENTER.EDIT_ARTICLE.TITLE_PLACEHOLDER')"
      @focus="onFocus"
      @blur="onBlur"
      @input="onTitleInput"
    />
    <woot-article-editor
      v-model="articleContent"
      class="article-content"
      :placeholder="$t('HELP_CENTER.EDIT_ARTICLE.CONTENT_PLACEHOLDER')"
      :enabled-menu-options="customEditorMenuOptions"
      @focus="onFocus"
      @blur="onBlur"
      @input="onContentInput"
    />
  </div>
</template>

<script>
import { debounce } from '@chatwoot/utils';
import ResizableTextArea from 'shared/components/ResizableTextArea.vue';
import WootArticleEditor from 'dashboard/components/widgets/WootWriter/FullEditor.vue';
import { ARTICLE_EDITOR_MENU_OPTIONS } from 'dashboard/constants/editor';

export default {
  components: {
    WootArticleEditor,
    ResizableTextArea,
  },
  props: {
    article: {
      type: Object,
      default: () => ({}),
    },
    isSettingsSidebarOpen: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      articleTitle: '',
      articleContent: '',
      saveArticle: () => {},
      customEditorMenuOptions: ARTICLE_EDITOR_MENU_OPTIONS,
    };
  },
  mounted() {
    this.articleTitle = this.article.title;
    this.articleContent = this.article.content;
    this.saveArticle = debounce(
      values => {
        this.$emit('save-article', values);
      },
      300,
      false
    );
  },
  methods: {
    onFocus() {
      this.$emit('focus');
    },
    onBlur() {
      this.$emit('blur');
    },
    onTitleInput() {
      this.saveArticle({ title: this.articleTitle });
    },
    onContentInput() {
      this.saveArticle({ content: this.articleContent });
    },
  },
};
</script>

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
