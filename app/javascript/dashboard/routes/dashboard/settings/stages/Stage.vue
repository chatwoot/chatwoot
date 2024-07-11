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
          class="woot-table mt-2"
        >
          <thead>
            <th
              v-for="tableHeader in $t('STAGES_MGMT.LIST.TABLE_HEADER')"
              :key="tableHeader"
            >
              {{ tableHeader }}
            </th>
          </thead>
          <tbody>
            <tr v-for="stage in stages" :key="stage.code">
              <td>
                <span
                  :class="{ strikethrough: stage.disabled }"
                  style="display: block"
                >
                  {{ stage.name }}
                </span>
                <span v-if="stage.disabled" class="text-xs italic">
                  {{ $t('STAGES_MGMT.LIST.EMPTY_RESULT.DISABLED_STATE') }}
                </span>
              </td>
              <td>
                {{ stage.description }}
              </td>
              <td>
                {{ stage.code }}
              </td>
              <td>
                <woot-button
                  v-if="!stage.disabled"
                  v-tooltip.top="$t('STAGES_MGMT.LIST.BUTTONS.EDIT')"
                  variant="smooth"
                  size="tiny"
                  color-scheme="secondary"
                  class-names="grey-btn"
                  icon="edit"
                  @click="openEditPopup(stage)"
                />
                <woot-button
                  v-if="stage.disabled"
                  v-tooltip.top="$t('STAGES_MGMT.LIST.BUTTONS.ENABLE')"
                  variant="smooth"
                  color-scheme="primary"
                  size="tiny"
                  icon="checkmark-circle"
                  class-names="grey-btn"
                  @click="openEnable(stage)"
                />
                <woot-button
                  v-else-if="stage.allow_disabled"
                  v-tooltip.top="$t('STAGES_MGMT.LIST.BUTTONS.DISABLE')"
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  icon="dismiss-circle"
                  class-names="grey-btn"
                  @click="openDisable(stage)"
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
      v-if="showDisablePopup"
      :show.sync="showDisablePopup"
      :title="confirmDeleteTitle"
      :message="$t('STAGES_MGMT.DISABLE.CONFIRM.MESSAGE')"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedStage.name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      @on-confirm="confirmStageToggle"
      @on-close="closeDisable"
    />
    <woot-confirm-delete-modal
      v-if="showEnablePopup"
      :show.sync="showEnablePopup"
      :title="confirmDeleteTitle"
      :message="$t('STAGES_MGMT.ENABLE.CONFIRM.MESSAGE')"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedStage.name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      @on-confirm="confirmStageToggle"
      @on-close="closeEnable"
    />
    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <edit-stage
        :selected-stage="selectedStage"
        :is-updating="uiFlags.isUpdating"
        @on-close="hideEditPopup"
      />
    </woot-modal>
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
      showDisablePopup: false,
      showEnablePopup: false,
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
          name: this.$t('STAGES_MGMT.TABS.BOTH'),
          type: 'both',
        },
        {
          key: 1,
          name: this.$t('STAGES_MGMT.TABS.DEALS'),
          type: 'deals',
        },
        {
          key: 2,
          name: this.$t('STAGES_MGMT.TABS.RETENTION'),
          type: 'retention',
        },
      ];
    },
    deleteConfirmText() {
      return `${this.$t(
        'STAGES_MGMT.' +
          (this.selectedStage.disabled ? 'ENABLE' : 'DISABLE') +
          '.CONFIRM.YES'
      )} ${this.selectedStage.name}`;
    },
    deleteRejectText() {
      return this.$t(
        'STAGES_MGMT.' +
          (this.selectedStage.disabled ? 'ENABLE' : 'DISABLE') +
          '.CONFIRM.NO'
      );
    },
    confirmDeleteTitle() {
      return this.$t(
        'STAGES_MGMT.' +
          (this.selectedStage.disabled ? 'ENABLE' : 'DISABLE') +
          '.CONFIRM.TITLE',
        {
          name: this.selectedStage.name,
        }
      );
    },
    confirmPlaceHolderText() {
      return `${this.$t(
        'STAGES_MGMT.' +
          (this.selectedStage.disabled ? 'ENABLE' : 'DISABLE') +
          '.CONFIRM.PLACE_HOLDER'
      )}`;
    },
  },
  mounted() {
    this.$store.dispatch('stages/get');
  },
  methods: {
    onClickTabChange(index) {
      this.selectedTabIndex = index;
    },
    async toggleStage(selectedStage) {
      const previousState = selectedStage.disabled;
      try {
        const stage = {
          id: selectedStage.id,
          disabled: !selectedStage.disabled,
        };
        await this.$store.dispatch('stages/update', stage);
        this.showAlert(
          this.$t(
            'STAGES_MGMT.' +
              (previousState ? 'ENABLE' : 'DISABLE') +
              '.API.SUCCESS_MESSAGE'
          )
        );
      } catch (error) {
        const errorMessage =
          error?.response?.message ||
          this.$t(
            'STAGES_MGMT.' +
              (previousState ? 'ENABLE' : 'DISABLE') +
              '.API.ERROR_MESSAGE'
          );
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
    confirmStageToggle() {
      this.toggleStage(this.selectedStage);
      this.closeDisable();
      this.closeEnable();
    },
    openDisable(value) {
      this.showDisablePopup = true;
      this.selectedStage = value;
    },
    closeDisable() {
      this.showDisablePopup = false;
      this.selectedStage = {};
    },
    openEnable(value) {
      this.showEnablePopup = true;
      this.selectedStage = value;
    },
    closeEnable() {
      this.showEnablePopup = false;
      this.selectedStage = {};
    },
  },
};
</script>

<style lang="scss" scoped>
.stage-key {
  font-family: monospace;
}
.strikethrough {
  text-decoration: line-through;
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
