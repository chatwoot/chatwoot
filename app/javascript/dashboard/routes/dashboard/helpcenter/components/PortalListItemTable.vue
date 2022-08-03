<template>
  <table>
    <thead>
      <tr>
        <th scope="col">
          {{
            $t(
              'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.NAME'
            )
          }}
        </th>
        <th scope="col">
          {{
            $t(
              'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.CODE'
            )
          }}
        </th>
        <th scope="col">
          {{
            $t(
              'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.ARTICLE_COUNT'
            )
          }}
        </th>
        <th scope="col">
          {{
            $t(
              'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.CATEGORIES'
            )
          }}
        </th>
        <th scope="col" />
      </tr>
    </thead>
    <tr>
      <td colspan="100%" class="horizontal-line" />
    </tr>
    <tbody>
      <tr v-for="locale in portals.locales" :key="locale.code">
        <td>
          <span>{{ locale.name }}</span>
          <Label
            v-if="locale.code === selectedLocaleCode"
            :title="
              $t(
                'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.DEFAULT_LOCALE'
              )
            "
            color-scheme="primary"
            :small="true"
            class="default-status"
          />
        </td>
        <td>
          <span>{{ locale.code }}</span>
        </td>
        <td>
          <span>{{ locale.articles_count }}</span>
        </td>
        <td>
          <span>{{ locale.categories_count }}</span>
        </td>
        <td>
          <woot-button
            v-tooltip.top-end="
              $t(
                'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.SWAP'
              )
            "
            size="tiny"
            variant="smooth"
            icon="arrow-swap"
            color-scheme="primary"
            :disabled="locale.code === selectedLocaleCode"
            @click="swapLocale"
          />
          <woot-button
            v-tooltip.top-end="
              $t(
                'HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.AVAILABLE_LOCALES.TABLE.DELETE'
              )
            "
            size="tiny"
            variant="smooth"
            icon="delete"
            color-scheme="secondary"
            @click="deleteLocale"
          />
        </td>
      </tr>
    </tbody>
  </table>
</template>

<script>
import Label from 'dashboard/components/ui/Label';
export default {
  components: {
    Label,
  },
  props: {
    portals: {
      type: Object,
      default: () => {},
    },
    selectedLocaleCode: {
      type: String,
      default: '',
    },
  },
  methods: {
    swapLocale() {
      this.$emit('swap');
    },
    deleteLocale() {
      this.$emit('delete');
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
      .default-status {
        margin: 0 0 0 var(--space-smaller);
      }
    }
  }
}
.horizontal-line {
  border-bottom: 1px solid var(--color-border);
}
</style>
