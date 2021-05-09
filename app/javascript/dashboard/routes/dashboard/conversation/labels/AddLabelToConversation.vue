<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header
        :header-title="
          $t('CONTACT_PANEL.LABELS.MODAL.TITLE') + ' #' + conversationId
        "
      />
      <div class="content">
        <div class="label-content--block">
          <div class="label-content--title">
            {{ $t('CONTACT_PANEL.LABELS.MODAL.ACTIVE_LABELS') }}
            <span v-tooltip.bottom="$t('CONTACT_PANEL.LABELS.MODAL.REMOVE')">
              <i class="ion-ios-help-outline" />
            </span>
          </div>
          <div v-if="activeList.length">
            <woot-label
              v-for="label in activeList"
              :key="label.id"
              :title="label.title"
              :description="label.description"
              :bg-color="label.color"
              :show-close="true"
              @click="onRemove"
            />
          </div>
          <p v-else>
            {{ $t('CONTACT_PANEL.LABELS.NO_AVAILABLE_LABELS') }}
          </p>
        </div>

        <div class="label-content--block">
          <div class="label-content--title">
            {{ $t('CONTACT_PANEL.LABELS.MODAL.INACTIVE_LABELS') }}
            <span v-tooltip.bottom="$t('CONTACT_PANEL.LABELS.MODAL.ADD')">
              <i class="ion-ios-help-outline" />
            </span>
          </div>
          <div v-if="inactiveList.length">
            <woot-label
              v-for="label in inactiveList"
              :key="label.id"
              :title="label.title"
              :description="label.description"
              :bg-color="label.color"
              icon="ion-plus"
              @click="onAdd"
            />
          </div>
          <p v-else>
            {{ $t('CONTACT_PANEL.LABELS.NO_LABELS_TO_ADD') }}
          </p>
        </div>
      </div>
    </div>
  </woot-modal>
</template>
<script>
export default {
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    conversationId: {
      type: [String, Number],
      default: '',
    },
    accountLabels: {
      type: Array,
      default: () => [],
    },
    savedLabels: {
      type: Array,
      default: () => [],
    },
    onClose: {
      type: Function,
      default: () => [],
    },
    updateLabels: {
      type: Function,
      default: () => {},
    },
  },
  computed: {
    activeList() {
      return this.accountLabels
        .filter(accountLabel => this.savedLabels.includes(accountLabel.title))
        .sort((a, b) => {
          return a.title.localeCompare(b.title);
        });
    },
    inactiveList() {
      return this.accountLabels
        .filter(accountLabel => !this.savedLabels.includes(accountLabel.title))
        .sort((a, b) => {
          return a.title.localeCompare(b.title);
        });
    },
  },
  methods: {
    onAdd(label) {
      const activeLabels = this.activeList.map(
        activeLabel => activeLabel.title
      );
      this.updateLabels([...activeLabels, label]);
    },

    onRemove(label) {
      const activeLabels = this.activeList
        .filter(activeLabel => activeLabel.title !== label)
        .map(activeLabel => activeLabel.title);
      this.updateLabels(activeLabels);
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';

.label-content--block {
  margin-bottom: $space-normal;
}

.label-content--title {
  font-weight: $font-weight-bold;
  margin-bottom: $space-small;
}

.content {
  padding-top: $space-normal;
}
</style>
