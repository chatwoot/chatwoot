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
            <span>{{ category.icon }} {{ category.name }}</span>
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
              @click="deleteCategory(category)"
            />
          </td>
        </tr>
      </tbody>
    </table>
    <p
      v-if="categories.length === 0"
      class="flex justify-center text-slate-500 dark:text-slate-300 text-base mt-8"
    >
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
    deleteCategory(category) {
      this.$emit('delete', category);
    },
  },
};
</script>

<style lang="scss" scoped>
table {
  thead tr th {
    @apply text-sm font-medium normal-case text-slate-800 dark:text-slate-100 pl-0 rtl:pl-2.5 rtl:pr-0 pt-0;
  }

  tbody tr {
    @apply border-b-0;
    td {
      @apply text-sm pl-0 rtl:pl-2.5 rtl:pr-0 text-slate-700 dark:text-slate-100;
    }
  }
}
.horizontal-line {
  @apply border-b border-solid border-slate-75 dark:border-slate-700;
}
</style>
