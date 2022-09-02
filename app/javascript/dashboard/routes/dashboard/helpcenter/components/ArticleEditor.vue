<template>
  <div
    class="edit-article--container"
    :class="{ 'is-settings-sidebar-open': isSettingsSidebarOpen }"
  >
    <input
      v-model="articleTitle"
      type="text"
      class="article-heading"
      :placeholder="$t('HELP_CENTER.EDIT_ARTICLE.TITLE_PLACEHOLDER')"
      @focus="onFocus"
      @blur="onBlur"
      @input="onTitleInput"
    />
    <woot-message-editor
      v-model="articleContent"
      class="article-content"
      :placeholder="$t('HELP_CENTER.EDIT_ARTICLE.CONTENT_PLACEHOLDER')"
      :is-format-mode="true"
      @focus="onFocus"
      @blur="onBlur"
      @input="onContentInput"
    />
  </div>
</template>

<script>
import { debounce } from '@chatwoot/utils';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';

export default {
  components: {
    WootMessageEditor,
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
  width: 640px;
}

.is-settings-sidebar-open {
  margin: var(--space-large) var(--space-small);
}

.article-heading {
  font-size: var(--font-size-giga);
  font-weight: var(--font-weight-bold);
  min-height: var(--space-jumbo);
  max-height: var(--space-jumbo);
  border: 0px solid transparent;
  padding: 0;
  color: var(--s-900);
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
        line-height: 1.5;
      }

      li::marker {
        font-size: var(--font-size-default);
      }
    }
  }
}
</style>
