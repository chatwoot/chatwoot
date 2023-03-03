<template>
  <div class="edit-article--container">
    <resizable-text-area
      v-model="articleTitle"
      type="text"
      rows="1"
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
      @focus="onFocus"
      @blur="onBlur"
      @input="onContentInput"
    />
  </div>
</template>

<script>
import { debounce } from '@chatwoot/utils';
import ResizableTextArea from 'shared/components/ResizableTextArea';
import WootArticleEditor from 'dashboard/components/widgets/WootWriter/FullEditor.vue';

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
  margin: var(--space-large) auto;
  padding: 0 var(--space-medium);
  max-width: 89.6rem;
  width: 100%;
}

.article-heading {
  font-size: var(--font-size-giga);
  font-weight: var(--font-weight-bold);
  width: 100%;
  min-height: var(--space-jumbo);
  max-height: 64rem;
  height: auto;
  margin-bottom: var(--space-small);
  border: 0px solid transparent;
  padding: 0;
  color: var(--s-900);
  padding: var(--space-normal);
  resize: none;

  &:hover {
    background: var(--s-25);
    border-radius: var(--border-radius-normal);
  }
}

.article-content {
  padding: 0 var(--space-normal);
  height: fit-content;
}

::v-deep {
  .ProseMirror-menubar-wrapper {
    .ProseMirror-woot-style {
      min-height: var(--space-giga);
      max-height: 100%;
    }
  }
}
</style>
