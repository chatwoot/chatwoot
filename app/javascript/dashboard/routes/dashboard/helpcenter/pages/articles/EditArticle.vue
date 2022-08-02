<template>
  <div class="container">
    <edit-article-header
      back-button-label="All Articles"
      draft-state="saved"
      @back="onClickGoBack"
    />
    <edit-article-field :article="article" />
  </div>
</template>

<script>
import EditArticleHeader from 'dashboard/routes/dashboard/helpcenter/components/Header/EditArticleHeader';
import EditArticleField from 'dashboard/components/helpCenter/EditArticle';
export default {
  components: {
    EditArticleHeader,
    EditArticleField,
  },
  props: {
    article: {
      type: Object,
      default: () => {},
    },
  },
  methods: {
    onClickGoBack() {
      this.$router.push({ name: 'list_all_locale_articles' });
    },
  },
};
</script>

<style lang="scss" scoped>
.container {
  padding: var(--space-small) var(--space-normal);
  width: 100%;
}
</style>
