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
          v-if="!uiFlags.isFetching && !stages.length"
          class="mt-12 flex items-center justify-center"
        >
          {{ $t('STAGES_MGMT.LIST.EMPTY_RESULT.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="$t('STAGES_MGMT.LOADING')"
        />
        <table
          v-if="!uiFlags.isFetching && stages.length"
          class="w-full mt-2 table-fixed woot-table"
        >
          <thead>
            <th
              v-for="tableHeader in $t('STAGES_MGMT.LIST.TABLE_HEADER')"
              :key="tableHeader"
              class="pl-0 max-w-[6.25rem] min-w-[5rem]"
            >
              {{ tableHeader }}
            </th>
          </thead>
          <tbody>
            <tr v-for="stage in stages" :key="stage.code">
              <td
                class="pl-0 max-w-[6.25rem] min-w-[5rem] overflow-hidden whitespace-nowrap text-ellipsis"
              >
                {{ stage.name }}
              </td>
              <td
                class="pl-0 max-w-[15rem] min-w-[6.25rem] overflow-hidden whitespace-nowrap text-ellipsis"
              >
                {{ stage.description }}
              </td>
              <td
                class="pl-0 max-w-[4.25rem] min-w-[4rem] overflow-hidden whitespace-nowrap text-ellipsis"
              >
                {{ stage.code }}
              </td>
              <td
                class="stage-key pl-0 max-w-[3.25rem] min-w-[3rem] overflow-hidden whitespace-nowrap text-ellipsis"
              >
                {{ stage.stage_type }}
              </td>
              <td class="button-wrapper">
                <woot-button
                  v-tooltip.top="$t('STAGES_MGMT.LIST.BUTTONS.EDIT')"
                  variant="smooth"
                  size="tiny"
                  color-scheme="secondary"
                  class-names="grey-btn"
                  icon="edit"
                  @click="openEditPopup(stage)"
                />
                <woot-button
                  v-tooltip.top="$t('STAGES_MGMT.LIST.BUTTONS.DELETE')"
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  icon="dismiss-circle"
                  class-names="grey-btn"
                  @click="openDelete(stage)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    <div class="hidden lg:block w-1/3">
      <span v-dompurify-html="$t('STAGES_MGMT.SIDEBAR_TXT')" />
    </div>
    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <edit-stage
        :selected-stage="selectedStage"
        :is-updating="uiFlags.isUpdating"
        @on-close="hideEditPopup"
      />
    </woot-modal>
    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      :show.sync="showDeletePopup"
      :title="confirmDeleteTitle"
      :message="$t('STAGES_MGMT.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedStage.name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      @on-confirm="confirmDeletion"
      @on-close="closeDelete"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import EditStage from './EditStage.vue';

export default {
  components: {
    EditStage,
  },
  mixins: [alertMixin],
  data() {
    return {
      selectedTabIndex: 0,
      showEditPopup: false,
      showDeletePopup: false,
      selectedStage: {},
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'stages/getUIFlags',
    }),
    stages() {
      const stageType = this.tabs[this.selectedTabIndex].type;
      return this.$store.getters['stages/getStagesByType'](stageType);
    },
    tabs() {
      return [
        {
          key: 0,
          name: this.$t('STAGES_MGMT.TABS.LEADS'),
          type: 'leads',
        },
        {
          key: 1,
          name: this.$t('STAGES_MGMT.TABS.DEALS'),
          type: 'deals',
        },
        {
          key: 2,
          name: this.$t('STAGES_MGMT.TABS.BOTH'),
          type: 'both',
        },
      ];
    },
    deleteConfirmText() {
      return `${this.$t('STAGES_MGMT.DELETE.CONFIRM.YES')} ${
        this.selectedStage.name
      }`;
    },
    deleteRejectText() {
      return this.$t('STAGES_MGMT.DELETE.CONFIRM.NO');
    },
    confirmDeleteTitle() {
      return this.$t('STAGES_MGMT.DELETE.CONFIRM.TITLE', {
        name: this.selectedStage.name,
      });
    },
    confirmPlaceHolderText() {
      return `${this.$t('STAGES_MGMT.DELETE.CONFIRM.PLACE_HOLDER', {
        name: this.selectedStage.name,
      })}`;
    },
  },
  mounted() {
    this.fetchStages(this.selectedTabIndex);
  },
  methods: {
    onClickTabChange(index) {
      this.selectedTabIndex = index;
      this.fetchStages(index);
    },
    fetchStages(index) {
      this.$store.dispatch('stages/get', index);
    },
    async deleteStage({ id }) {
      try {
        await this.$store.dispatch('stages/delete', id);
        this.showAlert(this.$t('STAGES_MGMT.DELETE.API.SUCCESS_MESSAGE'));
      } catch (error) {
        const errorMessage =
          error?.response?.message ||
          this.$t('STAGES_MGMT.DELETE.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
    },
    openEditPopup(response) {
      this.showEditPopup = true;
      this.selectedStage = response;
    },
    hideEditPopup() {
      this.showEditPopup = false;
    },
    confirmDeletion() {
      this.deleteStage(this.selectedStage);
      this.closeDelete();
    },
    openDelete(value) {
      this.showDeletePopup = true;
      this.selectedStage = value;
    },
    closeDelete() {
      this.showDeletePopup = false;
      this.selectedStage = {};
    },
  },
};
</script>

<style lang="scss" scoped>
.stage-key {
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
