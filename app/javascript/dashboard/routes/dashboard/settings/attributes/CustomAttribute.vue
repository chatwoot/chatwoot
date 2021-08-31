<template>
  <section class="attribute-table-wrap">
    <woot-tabs :index="selectedTabIndex" @change="onClickTabChange">
      <woot-tabs-item
        v-for="tab in tabs"
        :key="tab.key"
        :name="tab.name"
        :show-badge="false"
      />
    </woot-tabs>

    <empty-state v-if="showEmptyResult" :title="emptyMessage" />
    <ve-table
      v-else
      :columns="columns"
      scroll-width="136rem"
      max-height="calc(100vh - 132px)"
      :table-data="tableData"
    />
    <div v-if="isLoading" class="attribute_loader">
      <spinner />
      <span>{{ $t('ATTRIBUTES_MGMT.LIST.LOADING_MESSAGE') }}</span>
    </div>
  </section>
</template>

<script>
import { mapGetters } from 'vuex';
import { VeTable } from 'vue-easytable';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import Spinner from 'shared/components/Spinner.vue';
import WootButton from 'dashboard/components/ui/WootButton.vue';

export default {
  components: {
    VeTable,
    EmptyState,
    Spinner,
  },
  data() {
    return {
      selectedTabIndex: 0,
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
      return this.$store.getters['attributes/getAttributes'](attributeModel);
    },
    tabs() {
      const tabs = [
        {
          key: 'conversation_attribute',
          name: this.$t('ATTRIBUTES_MGMT.TABS.CONVERSATION'),
        },
        {
          key: 'contact_attribute',
          name: this.$t('ATTRIBUTES_MGMT.TABS.CONTACT'),
        },
      ];

      return tabs;
    },
    showEmptyResult() {
      const hasEmptyResults =
        !this.uiFlags.isFetching && this.attributes.length === 0;
      return hasEmptyResults;
    },
    emptyMessage() {
      return this.attributes.length
        ? this.$t('ATTRIBUTES_MGMT.LIST.EMPTY_RESULT.404')
        : this.$t('ATTRIBUTES_MGMT.LIST.EMPTY_RESULT.NOT_FOUND');
    },
    selectedTabKey() {
      return this.tabs[this.selectedTabIndex]?.key;
    },
    isLoading() {
      return this.uiFlags.isFetching;
    },
    tableData() {
      if (this.isLoading) {
        return [];
      }
      return this.attributes.map(item => ({
        name: item.attribute_display_name,
        description: item.attribute_description,
        model: item.attribute_model,
        type: item.attribute_display_type,
        key: item.attribute_key,
      }));
    },
    columns() {
      const attributeTable = [
        {
          field: 'name',
          key: 'name',
          title: this.$t('ATTRIBUTES_MGMT.LIST.TABLE_HEADER.NAME'),
          fixed: 'left',
          align: 'left',
          width: 200,
          renderBodyCell: ({ row }) => (
            <div class="row--title-block">
              <h6 class="text-block-title text-truncate">{row.name}</h6>
            </div>
          ),
        },

        {
          field: 'description',
          key: 'description',
          title: this.$t('ATTRIBUTES_MGMT.LIST.TABLE_HEADER.DESCRIPTION'),
          align: 'left',
          width: 250,
          renderBodyCell: ({ row }) => (
            <div class="row--title-block">
              <h6 class="text-block-title text-truncate">{row.description}</h6>
            </div>
          ),
        },
        {
          field: 'key',
          key: 'key',
          title: this.$t('ATTRIBUTES_MGMT.LIST.TABLE_HEADER.KEY'),
          align: 'left',
          width: 200,
          renderBodyCell: ({ row }) => (
            <div class="row--title-block">
              <h6 class="text-block-title text-truncate">{row.key}</h6>
            </div>
          ),
        },
        {
          field: 'type',
          key: 'type',
          title: this.$t('ATTRIBUTES_MGMT.LIST.TABLE_HEADER.TYPE'),
          align: 'left',
          width: 150,
          renderBodyCell: ({ row }) => (
            <div class="row--title-block">
              <h6 class="text-block-title text-truncate">{row.type}</h6>
            </div>
          ),
        },
        {
          field: 'buttons',
          key: 'buttons',
          title: '',
          align: 'left',
          width: 150,
          renderBodyCell: row => (
            <div>
              <WootButton
                variant="clear"
                icon="ion-edit"
                color-scheme="secondary"
                classNames="edit-btn"
                onClick={() => this.$emit('edit', row)}
              >
                {this.$t('ATTRIBUTES_MGMT.LIST.BUTTONS.EDIT')}
              </WootButton>
              <WootButton
                variant="link"
                icon="ion-close-circled"
                color-scheme="secondary"
                onClick={() => this.$emit('delete', row)}
              >
                {this.$t('ATTRIBUTES_MGMT.LIST.BUTTONS.DELETE')}
              </WootButton>
            </div>
          ),
        },
      ];
      return [...attributeTable];
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
.attribute-table-wrap {
  padding: var(--space-two) var(--space-normal);
}

.tabs {
  padding: 0;
  margin-bottom: -1px;
}

.edit-btn {
  margin-right: var(--space-normal);
}

.attribute_loader {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: var(--font-size-medium);
  margin-top: var(--space-two);
}

::v-deep {
  .ve-table-header-th {
    font-weight: var(--font-weight-bold) !important;
    padding: var(--space-one) var(--space-normal) !important;
  }

  .ve-table-body-td {
    padding: var(--space-small) var(--space-normal) !important;
  }

  .row--title-block {
    align-items: center;
    display: flex;
    text-align: left;
  }
}
</style>
