<template>
  <div class="container">
    <edit-article-header
      back-button-label="All Articles"
      draft-state="saved"
      @back="onClickGoBack"
    />
    <edit-article-field />
  </div>
</template>

<script>
import EditArticleHeader from 'dashboard/components/helpCenter/Header/EditArticleHeader';
import EditArticleField from 'dashboard/components/helpCenter/EditArticle';
export default {
  components: {
    EditArticleHeader,
    EditArticleField,
  },
  methods: {
    onClickGoBack() {
      this.$router.push({ name: 'list_all_portals' });
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
