<template>
  <div class="edit-article--container">
    <resizable-text-area
      v-model="articleTitle"
      class="article-header"
      :placeholder="$t('HELP_CENTER.EDIT_ARTICLE.TITLE_PLACEHOLDER')"
      @focus="onFocus"
      @blur="onBlur"
    />
    <woot-message-editor
      v-model="articleContent"
      class="article-content"
      :placeholder="$t('HELP_CENTER.EDIT_ARTICLE.CONTENT_PLACEHOLDER')"
      :is-format-mode="true"
      :min-height="24"
      @focus="onFocus"
      @blur="onBlur"
    />
  </div>
</template>

<script>
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import ResizableTextArea from 'shared/components/ResizableTextArea';
export default {
  components: {
    WootMessageEditor,
    ResizableTextArea,
  },
  props: {
    article: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      articleTitle: '',
      articleContent: '',
    };
  },
  mounted() {
    this.articleTitle = this.article.title;
    this.articleContent = this.article.content;
  },
  methods: {
    onFocus() {
      this.$emit('focus');
    },
    onBlur() {
      this.$emit('blur');
    },
  },
};
</script>

<style lang="scss" scoped>
.edit-article--container {
  margin: var(--space-medium) var(--space-giga);
}

.article-header {
  font-size: var(--font-size-giga);
  font-weight: var(--font-weight-bold);
  min-height: var(--space-jumbo);
  max-height: var(--space-jumbo);
  border: 0px solid transparent;
  padding: 0;
}

::v-deep {
  .ProseMirror-menubar-wrapper {
    .ProseMirror-menubar .ProseMirror-menuitem {
      .ProseMirror-icon {
        margin-right: var(--space-normal);
        font-size: var(--font-size-small);
      }
    }

    .ProseMirror-woot-style {
      min-height: var(--space-giga);
      max-height: 100%;

      p {
        font-size: var(--font-size-default);
        line-height: 1.8;
      }
    }
  }
}
</style>
