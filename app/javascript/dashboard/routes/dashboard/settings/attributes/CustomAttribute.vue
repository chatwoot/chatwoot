<template>
  <div class="flex flex-row gap-4 p-8">
    <div class="w-full lg:w-3/5">
      <woot-tabs :index="selectedTabIndex" @change="onClickTabChange">
        <woot-tabs-item
          v-for="tab in tabs"
          :key="tab.key"
          :name="tab.name"
          :show-badge="false"
        />
      </woot-tabs>

      <div class="w-full">
        <p
          v-if="!uiFlags.isFetching && !attributes.length"
          class="flex items-center justify-center mt-12"
        >
          {{ $t('ATTRIBUTES_MGMT.LIST.EMPTY_RESULT.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="$t('ATTRIBUTES_MGMT.LOADING')"
        />
        <table
          v-if="!uiFlags.isFetching && attributes.length"
          class="w-full mt-2 table-fixed woot-table"
        >
          <thead>
            <th
              v-for="tableHeader in $t('ATTRIBUTES_MGMT.LIST.TABLE_HEADER')"
              :key="tableHeader"
              class="pl-0 max-w-[6.25rem] min-w-[5rem]"
            >
              {{ tableHeader }}
            </th>
          </thead>
          <tbody>
            <tr v-for="attribute in attributes" :key="attribute.attribute_key">
              <td
                class="pl-0 max-w-[6.25rem] min-w-[5rem] overflow-hidden whitespace-nowrap text-ellipsis"
              >
                {{ attribute.attribute_display_name }}
              </td>
              <td
                class="pl-0 max-w-[10rem] min-w-[6.25rem] overflow-hidden whitespace-nowrap text-ellipsis"
              >
                {{ attribute.attribute_description }}
              </td>
              <td
                class="pl-0 max-w-[6.25rem] min-w-[5rem] overflow-hidden whitespace-nowrap text-ellipsis"
              >
                {{ attribute.attribute_display_type }}
              </td>
              <td
                class="attribute-key pl-0 max-w-[6.25rem] min-w-[5rem] overflow-hidden whitespace-nowrap text-ellipsis"
              >
                {{ attribute.attribute_key }}
              </td>
              <td class="button-wrapper">
                <woot-button
                  v-tooltip.top="$t('ATTRIBUTES_MGMT.LIST.BUTTONS.EDIT')"
                  variant="smooth"
                  size="tiny"
                  color-scheme="secondary"
                  class-names="grey-btn"
                  icon="edit"
                  @click="openEditPopup(attribute)"
                />
                <woot-button
                  v-tooltip.top="$t('ATTRIBUTES_MGMT.LIST.BUTTONS.DELETE')"
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  icon="dismiss-circle"
                  class-names="grey-btn"
                  @click="openDelete(attribute)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    <div class="hidden w-1/3 lg:block">
      <span v-dompurify-html="$t('ATTRIBUTES_MGMT.SIDEBAR_TXT')" />
    </div>
    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <edit-attribute
        :selected-attribute="selectedAttribute"
        :is-updating="uiFlags.isUpdating"
        @on-close="hideEditPopup"
      />
    </woot-modal>
    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      :show.sync="showDeletePopup"
      :title="confirmDeleteTitle"
      :message="$t('ATTRIBUTES_MGMT.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedAttribute.attribute_display_name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      @on-confirm="confirmDeletion"
      @on-close="closeDelete"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import EditAttribute from './EditAttribute.vue';

export default {
  components: {
    EditAttribute,
  },
  data() {
    return {
      selectedTabIndex: 0,
      showEditPopup: false,
      showDeletePopup: false,
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

      return this.$store.getters['attributes/getAttributesByModel'](
        attributeModel
      );
    },
    tabs() {
      return [
        {
          key: 0,
          name: this.$t('ATTRIBUTES_MGMT.TABS.CONVERSATION'),
        },
        {
          key: 1,
          name: this.$t('ATTRIBUTES_MGMT.TABS.CONTACT'),
        },
      ];
    },
    deleteConfirmText() {
      return `${this.$t('ATTRIBUTES_MGMT.DELETE.CONFIRM.YES')} ${
        this.selectedAttribute.attribute_display_name
      }`;
    },
    deleteRejectText() {
      return this.$t('ATTRIBUTES_MGMT.DELETE.CONFIRM.NO');
    },
    confirmDeleteTitle() {
      return this.$t('ATTRIBUTES_MGMT.DELETE.CONFIRM.TITLE', {
        attributeName: this.selectedAttribute.attribute_display_name,
      });
    },
    confirmPlaceHolderText() {
      return `${this.$t('ATTRIBUTES_MGMT.DELETE.CONFIRM.PLACE_HOLDER', {
        attributeName: this.selectedAttribute.attribute_display_name,
      })}`;
    },
  },
  mounted() {
    this.fetchAttributes(this.selectedTabIndex);
  },
  methods: {
    onClickTabChange(index) {
      this.selectedTabIndex = index;
      this.fetchAttributes(index);
    },
    fetchAttributes(index) {
      this.$store.dispatch('attributes/get', index);
    },
    async deleteAttributes({ id }) {
      try {
        await this.$store.dispatch('attributes/delete', id);
        useAlert(this.$t('ATTRIBUTES_MGMT.DELETE.API.SUCCESS_MESSAGE'));
      } catch (error) {
        const errorMessage =
          error?.response?.message ||
          this.$t('ATTRIBUTES_MGMT.DELETE.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
    openEditPopup(response) {
      this.showEditPopup = true;
      this.selectedAttribute = response;
    },
    hideEditPopup() {
      this.showEditPopup = false;
    },
    confirmDeletion() {
      this.deleteAttributes(this.selectedAttribute);
      this.closeDelete();
    },
    openDelete(value) {
      this.showDeletePopup = true;
      this.selectedAttribute = value;
    },
    closeDelete() {
      this.showDeletePopup = false;
      this.selectedAttribute = {};
    },
  },
};
</script>

<style lang="scss" scoped>
.attribute-key {
  font-family: monospace;
}

::v-deep {
  .tabs--container {
    .tabs {
      @apply p-0;
    }
  }

  .tabs-title a {
    font-weight: var(--font-weight-medium);
    padding-top: 0;
  }
}
</style>
