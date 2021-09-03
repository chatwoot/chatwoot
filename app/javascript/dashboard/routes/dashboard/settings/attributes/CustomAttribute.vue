<template>
  <div class="row table-wrap">
    <div class="column">
      <woot-tabs :index="selectedTabIndex" @change="onClickTabChange">
        <woot-tabs-item
          v-for="tab in tabs"
          :key="tab.key"
          :name="tab.name"
          :show-badge="false"
        />
      </woot-tabs>

      <div class="columns with-right-space ">
        <p
          v-if="!uiFlags.isFetching && !attributes.length"
          class="no-items-error-message"
        >
          {{ $t('ATTRIBUTES_MGMT.LIST.EMPTY_RESULT.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="$t('ATTRIBUTES_MGMT.LOADING')"
        />
        <table
          v-if="!uiFlags.isFetching && attributes.length"
          class="woot-table"
        >
          <thead>
            <th
              v-for="tableHeader in $t('ATTRIBUTES_MGMT.LIST.TABLE_HEADER')"
              :key="tableHeader"
              class="item"
            >
              {{ tableHeader }}
            </th>
          </thead>
          <tbody>
            <tr v-for="attribute in attributes" :key="attribute.model">
              <td class="item text-truncate">
                {{ attribute.attribute_display_name }}
              </td>
              <td class="item text-truncate">
                {{ attribute.attribute_description }}
              </td>
              <td class="item text-truncatee">
                {{ attribute.attribute_display_type }}
              </td>
              <td class="item key text-truncate">
                {{ attribute.attribute_key }}
              </td>
              <td class="button-wrapper">
                <woot-button
                  variant="link"
                  color-scheme="secondary"
                  class-names="grey-btn"
                  icon="ion-edit"
                >
                  {{ $t('ATTRIBUTES_MGMT.LIST.BUTTONS.EDIT') }}
                </woot-button>
                <woot-button
                  variant="link"
                  color-scheme="secondary"
                  icon="ion-close-circled"
                  class-names="grey-btn"
                >
                  {{ $t('ATTRIBUTES_MGMT.LIST.BUTTONS.DELETE') }}
                </woot-button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    <div class="small-4 columns">
      <span v-html="$t('ATTRIBUTES_MGMT.SIDEBAR_TXT')"></span>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  data() {
    return {
      selectedTabIndex: 0,
      selectedAttribute: {},
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'attributes/getUIFlags',
    }),
    attributes() {
      const attributeModel = this.selectedTabIndex
        ? 'contact_attribute'
        : 'conversation_attribute';

      return this.$store.getters['attributes/getAttributeModel'](
        attributeModel
      );
    },
    tabs() {
      const tabs = [
        {
          key: 0,
          name: this.$t('ATTRIBUTES_MGMT.TABS.CONVERSATION'),
        },
        {
          key: 1,
          name: this.$t('ATTRIBUTES_MGMT.TABS.CONTACT'),
        },
      ];
      return tabs;
    },
    selectedTabKey() {
      return this.tabs[this.selectedTabIndex]?.key;
    },
  },

  methods: {
    onClickTabChange(index) {
      this.selectedTabIndex = index;
    },
  },
};
</script>

<style lang="scss" scoped>
.table-wrap {
  padding-left: var(--space-small);
}

.woot-table {
  table-layout: fixed;
  width: 95%;
  margin-top: var(--space-small);
}

.no-items-error-message {
  margin-top: var(--space-larger);
}

.tabs {
  padding-left: 0;
  margin-right: 2.4rem;
  user-select: none;
}

.item {
  padding-left: 0;
}

.key {
  font-family: monospace;
}

::v-deep {
  .tabs-title a {
    font-weight: var(--font-weight-medium);
    padding-top: 0;
  }
}
</style>
