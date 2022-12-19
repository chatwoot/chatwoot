<template>
  <div
    v-show="activeLabels.length"
    ref="labelContainer"
    class="label-container"
  >
    <div class="labels-wrap" :class="{ expand: showAllLabels }">
      <woot-label
        v-for="(label, index) in activeLabels"
        :key="label.id"
        :title="label.title"
        :description="label.description"
        :color="label.color"
        variant="smooth"
        small
        :class="{ hidden: !showAllLabels && index > labelPosition }"
      />
      <woot-button
        v-if="showExpandLabelButton"
        :title="
          showAllLabels
            ? $t('CONVERSATION.CARD.HIDE_LABELS')
            : $t('CONVERSATION.CARD.SHOW_LABELS')
        "
        class="show-more--button"
        color-scheme="secondary"
        variant="hollow"
        :icon="showAllLabels ? 'chevron-left' : 'chevron-right'"
        size="tiny"
        @click="onShowLabels"
      />
    </div>
  </div>
</template>
<script>
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';
export default {
  mixins: [conversationLabelMixin],
  props: {
    conversationId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      showAllLabels: false,
      showExpandLabelButton: false,
      labelPosition: -1,
    };
  },
  watch: {
    activeLabels() {
      this.$nextTick(() => this.computeVisibleLabelPosition());
    },
  },
  mounted() {
    this.computeVisibleLabelPosition();
  },
  methods: {
    onShowLabels(e) {
      e.stopPropagation();
      this.showAllLabels = !this.showAllLabels;
    },
    computeVisibleLabelPosition() {
      const labelContainer = this.$refs.labelContainer;
      const labels = this.$refs.labelContainer.querySelectorAll('.label');
      let labelOffset = 0;
      Array.from(labels).forEach((label, index) => {
        labelOffset += label.offsetWidth + 8;

        if (labelOffset < labelContainer.clientWidth - 16) {
          this.labelPosition = index;
        } else {
          this.showExpandLabelButton = true;
        }
      });
    },
  },
};
</script>

<style lang="scss" scoped>
.show-more--button {
  height: var(--space-medium);
  position: sticky;
  flex-shrink: 0;
  margin-right: var(--space-medium);

  &.secondary:focus {
    color: var(--s-700);
    border-color: var(--s-300);
  }
}

.label-container {
  margin-top: var(--space-micro);
}

.labels-wrap {
  display: flex;
  align-items: center;
  min-width: 0;
  flex-shrink: 1;

  &.expand {
    height: auto;
    overflow: visible;
    flex-flow: row wrap;

    .label {
      margin-bottom: var(--space-smaller);
    }

    .show-more--button {
      margin-bottom: var(--space-smaller);
    }
  }

  .secondary {
    border: 1px solid var(--s-100);
  }

  .label {
    margin-bottom: 0;
  }
}

.hidden {
  visibility: hidden;
  position: absolute;
}
</style>
