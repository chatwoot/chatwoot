<template>
  <div>
    <table>
      <thead>
        <tr>
          <th scope="col">
            {{ $t('HELP_CENTER.PORTAL.EDIT.CATEGORIES.TABLE.NAME') }}
          </th>
          <th scope="col">
            {{ $t('HELP_CENTER.PORTAL.EDIT.CATEGORIES.TABLE.DESCRIPTION') }}
          </th>
          <th scope="col">
            {{ $t('HELP_CENTER.PORTAL.EDIT.CATEGORIES.TABLE.LOCALE') }}
          </th>
          <th scope="col">
            {{ $t('HELP_CENTER.PORTAL.EDIT.CATEGORIES.TABLE.ARTICLE_COUNT') }}
          </th>
          <th scope="col" />
        </tr>
      </thead>
      <tr>
        <td colspan="100%" class="horizontal-line" />
      </tr>
      <tbody>
        <tr v-for="category in categories" :key="category.id">
          <td>
            <span>{{ category.name }}</span>
          </td>
          <td>
            <span>{{ category.description }}</span>
          </td>
          <td>
            <span>{{ category.locale }}</span>
          </td>
          <td>
            <span>{{ category.meta.articles_count }}</span>
          </td>
          <td>
            <woot-button
              v-tooltip.top-end="
                $t(
                  'HELP_CENTER.PORTAL.EDIT.CATEGORIES.TABLE.ACTION_BUTTON.EDIT'
                )
              "
              size="tiny"
              variant="smooth"
              icon="edit"
              color-scheme="secondary"
              @click="editCategory(category)"
            />
            <woot-button
              v-tooltip.top-end="
                $t(
                  'HELP_CENTER.PORTAL.EDIT.CATEGORIES.TABLE.ACTION_BUTTON.DELETE'
                )
              "
              size="tiny"
              variant="smooth"
              icon="delete"
              color-scheme="alert"
              @click="deleteCategory(category.id)"
            />
          </td>
        </tr>
      </tbody>
    </table>
    <p v-if="categories.length === 0" class="empty-text">
      {{ $t('HELP_CENTER.PORTAL.EDIT.CATEGORIES.TABLE.EMPTY_TEXT') }}
    </p>
  </div>
</template>

<script>
export default {
  props: {
    categories: {
      type: Array,
      default: () => [],
    },
  },

  methods: {
    editCategory(category) {
      this.$emit('edit', category);
    },
    deleteCategory(categoryId) {
      this.$emit('delete', categoryId);
    },
  },
};
</script>

<style lang="scss" scoped>
table {
  thead tr th {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
    text-transform: none;
    color: var(--s-600);
    padding-left: 0;
    padding-top: 0;
  }

  tbody tr {
    border-bottom: 0;
    td {
      font-size: var(--font-size-small);
      padding-left: 0;
    }
  }
}
.horizontal-line {
  border-bottom: 1px solid var(--color-border);
}

.empty-text {
  display: flex;
  justify-content: center;
  color: var(--s-500);
  font-size: var(--font-size-default);
  margin-top: var(--space-large);
}
</style>
