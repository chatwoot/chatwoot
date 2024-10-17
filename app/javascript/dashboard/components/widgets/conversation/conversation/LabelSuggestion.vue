<script>
// components
import WootButton from '../../../ui/WootButton.vue';
import Avatar from '../../Avatar.vue';

// composables
import { useAI } from 'dashboard/composables/useAI';
import { useTrack } from 'dashboard/composables';

// store & api
import { mapGetters } from 'vuex';

// utils & constants
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { OPEN_AI_EVENTS } from '../../../../helper/AnalyticsHelper/events';

export default {
  name: 'LabelSuggestion',
  components: {
    Avatar,
    WootButton,
  },
  props: {
    suggestedLabels: {
      type: Array,
      required: true,
    },
    chatLabels: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  setup() {
    const { isAIIntegrationEnabled } = useAI();

    return { isAIIntegrationEnabled };
  },
  data() {
    return {
      isDismissed: false,
      isHovered: false,
      selectedLabels: [],
    };
  },
  computed: {
    ...mapGetters({
      allLabels: 'labels/getLabels',
      currentAccountId: 'getCurrentAccountId',
      currentChat: 'getSelectedChat',
    }),
    conversationId() {
      return this.currentChat?.id;
    },
    labelTooltip() {
      if (this.preparedLabels.length > 1) {
        return this.$t('LABEL_MGMT.SUGGESTIONS.TOOLTIP.MULTIPLE_SUGGESTION');
      }

      return this.$t('LABEL_MGMT.SUGGESTIONS.TOOLTIP.SINGLE_SUGGESTION');
    },
    addButtonText() {
      if (this.selectedLabels.length === 1) {
        return this.$t('LABEL_MGMT.SUGGESTIONS.ADD_SELECTED_LABEL');
      }

      if (this.selectedLabels.length > 1) {
        return this.$t('LABEL_MGMT.SUGGESTIONS.ADD_SELECTED_LABELS');
      }

      return this.$t('LABEL_MGMT.SUGGESTIONS.ADD_ALL_LABELS');
    },
    preparedLabels() {
      return this.allLabels.filter(label =>
        this.suggestedLabels.includes(label.title)
      );
    },
    shouldShowSuggestions() {
      if (this.isDismissed) return false;
      if (!this.isAIIntegrationEnabled) return false;

      return this.preparedLabels.length && this.chatLabels.length === 0;
    },
  },
  watch: {
    conversationId: {
      immediate: true,
      handler() {
        this.selectedLabels = [];
        this.isDismissed = this.isConversationDismissed();
      },
    },
  },
  methods: {
    pushOrAddLabel(label) {
      if (this.preparedLabels.length === 1) {
        this.addAllLabels();
        return;
      }

      if (!this.selectedLabels.includes(label)) {
        this.selectedLabels.push(label);
      } else {
        this.selectedLabels = this.selectedLabels.filter(l => l !== label);
      }
    },
    dismissSuggestions() {
      LocalStorage.setFlag(
        LOCAL_STORAGE_KEYS.DISMISSED_LABEL_SUGGESTIONS,
        this.currentAccountId,
        this.conversationId
      );

      // dismiss this once the values are set
      this.isDismissed = true;
      this.trackLabelEvent(OPEN_AI_EVENTS.DISMISS_LABEL_SUGGESTION);
    },
    isConversationDismissed() {
      return LocalStorage.getFlag(
        LOCAL_STORAGE_KEYS.DISMISSED_LABEL_SUGGESTIONS,
        this.currentAccountId,
        this.conversationId
      );
    },
    addAllLabels() {
      let labelsToAdd = this.selectedLabels;
      if (!labelsToAdd.length) {
        labelsToAdd = this.preparedLabels.map(label => label.title);
      }
      this.$store.dispatch('conversationLabels/update', {
        conversationId: this.conversationId,
        labels: labelsToAdd,
      });
      this.trackLabelEvent(OPEN_AI_EVENTS.APPLY_LABEL_SUGGESTION);
    },
    trackLabelEvent(event) {
      const payload = {
        conversationId: this.conversationId,
        account: this.currentAccountId,
        suggestions: this.suggestedLabels,
        labelsApplied: this.selectedLabels.length
          ? this.selectedLabels
          : this.suggestedLabels,
      };

      useTrack(event, payload);
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <li
    v-if="shouldShowSuggestions"
    class="label-suggestion right"
    @mouseover="isHovered = true"
    @mouseleave="isHovered = false"
  >
    <div class="wrap">
      <div class="label-suggestion--container">
        <h6 class="label-suggestion--title">
          {{ $t('LABEL_MGMT.SUGGESTIONS.SUGGESTED_LABELS') }}
        </h6>
        <div class="label-suggestion--options">
          <button
            v-for="label in preparedLabels"
            :key="label.title"
            v-tooltip.top="{
              content: selectedLabels.includes(label.title)
                ? $t('LABEL_MGMT.SUGGESTIONS.TOOLTIP.DESELECT')
                : labelTooltip,
              delay: { show: 600, hide: 0 },
              hideOnClick: true,
            }"
            class="label-suggestion--option !px-0"
            @click="pushOrAddLabel(label.title)"
          >
            <woot-label
              variant="dashed"
              v-bind="label"
              :bg-color="
                selectedLabels.includes(label.title) ? 'var(--w-100)' : ''
              "
            />
          </button>
          <WootButton
            v-if="preparedLabels.length === 1"
            v-tooltip.top="{
              content: $t('LABEL_MGMT.SUGGESTIONS.TOOLTIP.DISMISS'),
              delay: { show: 600, hide: 0 },
              hideOnClick: true,
            }"
            variant="smooth"
            :color-scheme="isHovered ? 'alert' : 'primary'"
            class="label--add"
            icon="dismiss"
            size="tiny"
            @click="dismissSuggestions"
          />
        </div>
        <div v-if="preparedLabels.length > 1">
          <WootButton
            :variant="selectedLabels.length === 0 ? 'smooth' : ''"
            class="label--add"
            icon="add"
            size="tiny"
            @click="addAllLabels"
          >
            {{ addButtonText }}
          </WootButton>
          <WootButton
            v-tooltip.top="{
              content: $t('LABEL_MGMT.SUGGESTIONS.TOOLTIP.DISMISS'),
              delay: { show: 600, hide: 0 },
              hideOnClick: true,
            }"
            :color-scheme="isHovered ? 'alert' : 'primary'"
            variant="smooth"
            class="label--add"
            icon="dismiss"
            size="tiny"
            @click="dismissSuggestions"
          />
        </div>
      </div>
      <div class="sender--info has-tooltip" data-original-title="null">
        <woot-thumbnail
          v-tooltip.top="{
            content: $t('LABEL_MGMT.SUGGESTIONS.POWERED_BY'),
            delay: { show: 600, hide: 0 },
            hideOnClick: true,
          }"
          size="16px"
        >
          <Avatar class="user-thumbnail thumbnail-rounded">
            <fluent-icon class="chatwoot-ai-icon" icon="chatwoot-ai" />
          </Avatar>
        </woot-thumbnail>
      </div>
    </div>
  </li>
</template>

<style scoped lang="scss">
.wrap {
  display: flex;
}

.label-suggestion {
  flex-direction: row;
  justify-content: flex-end;
  margin-top: var(--space-normal);

  .label-suggestion--container {
    max-width: 300px;
  }

  .label-suggestion--options {
    text-align: right;
    display: flex;
    align-items: center;
    gap: var(--space-micro);

    button.label-suggestion--option {
      .label {
        cursor: pointer;
        margin-bottom: 0;
      }
    }
  }

  .chatwoot-ai-icon {
    height: var(--font-size-mini);
    width: var(--font-size-mini);
  }

  .label-suggestion--title {
    color: var(--b-600);
    margin-top: var(--space-micro);
    font-size: var(--font-size-micro);
  }
}
</style>
