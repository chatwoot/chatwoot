<template>
  <li v-if="shouldShowSuggestions" class="label-suggestion right">
    <div class="wrap">
      <div class="label-suggestion--container">
        <h6 class="label-suggestion--title">Suggested labels</h6>
        <div v-if="!fetchingSuggestions" class="label-suggestion--options">
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
            class="label-suggestion--option"
            @click="pushOrAddLabel(label.title)"
          >
            <woot-label
              variant="smooth"
              :dashed="true"
              v-bind="label"
              :bg-color="
                selectedLabels.includes(label.title) ? 'var(--w-100)' : ''
              "
            />
          </button>
        </div>
        <div>
          <woot-button
            v-if="preparedLabels.length > 1"
            variant="smooth"
            class="label--add"
            icon="add"
            size="tiny"
            @click="addAllLabels"
          >
            {{ addButtonText }}
          </woot-button>
          <woot-button
            v-tooltip.top="{
              content: $t('LABEL_MGMT.SUGGESTIONS.TOOLTIP.DISMISS'),
              delay: { show: 600, hide: 0 },
              hideOnClick: true,
            }"
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
          <avatar class="user-thumbnail thumbnail-rounded">
            <fluent-icon class="chatwoot-ai-icon" icon="chatwoot-ai" />
          </avatar>
        </woot-thumbnail>
      </div>
    </div>
  </li>
</template>

<script>
import WootButton from '../../../ui/WootButton.vue';
import Avatar from '../../Avatar.vue';
import OpenAPI from 'dashboard/api/integrations/openapi';
import { mapGetters } from 'vuex';
import aiMixin from 'dashboard/mixins/aiMixin';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';

export default {
  name: 'LabelSuggestion',
  components: {
    Avatar,
    WootButton,
  },
  mixins: [aiMixin],
  props: {
    chatLabels: {
      type: Array,
      required: false,
      default: () => [],
    },
    conversationId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      isDismissed: false,
      fetchingSuggestions: false,
      suggestedLabels: [],
      selectedLabels: [],
    };
  },
  computed: {
    ...mapGetters({
      allLabels: 'labels/getLabels',
      currentAccountId: 'getCurrentAccountId',
    }),
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

      return (
        !this.fetchingSuggestions &&
        this.preparedLabels.length &&
        this.chatLabels.length === 0
      );
    },
  },
  watch: {
    conversationId() {
      this.selectedLabels = [];
      this.suggestedLabels = [];
      this.isDismissed = this.isConversationDismissed();
      this.fetchIfRequired();
    },
  },
  mounted() {
    this.selectedLabels = [];
    this.suggestedLabels = [];
    this.isDismissed = this.isConversationDismissed();
    this.fetchIfRequired();
  },
  methods: {
    async fetchIfRequired() {
      if (this.chatLabels.length !== 0) {
        return;
      }

      this.fetchIntegrationsIfRequired().then(() => {
        if (this.isAIIntegrationEnabled) {
          this.fetchLabelSuggestion().then(labels => {
            this.suggestedLabels = labels;
          });
        }
      });
    },
    async fetchLabelSuggestion() {
      try {
        this.fetchingSuggestions = true;
        const result = await OpenAPI.processEvent({
          type: 'label_suggestion',
          hookId: this.hookId,
          conversationId: this.conversationId,
        });

        const {
          data: { message: labels },
        } = result;

        return this.cleanLabels(labels);
      } catch (error) {
        return [];
      } finally {
        this.fetchingSuggestions = false;
      }
    },
    cleanLabels(labels) {
      return labels
        .toLowerCase() // Set it to lowercase
        .split(',') // split the string into an array
        .filter(label => label.trim()) // remove any empty strings
        .filter((label, index, self) => self.indexOf(label) === index) // remove any duplicates
        .map(label => label.trim()); // trim the words
    },
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
      const dismissed = this.getDismissedConversations();
      dismissed[this.currentAccountId].push(this.conversationId);

      LocalStorage.set(
        LOCAL_STORAGE_KEYS.DISMISSED_LABEL_SUGGESTIONS,
        dismissed
      );

      // dismiss this once the values are set
      this.isDismissed = true;
    },
    isConversationDismissed() {
      const dismissed = this.getDismissedConversations();
      return dismissed[this.currentAccountId].includes(this.conversationId);
    },
    getDismissedConversations() {
      const suggestionKey = LOCAL_STORAGE_KEYS.DISMISSED_LABEL_SUGGESTIONS;

      // fetch the value from Storage
      const valueFromStorage = LocalStorage.get(suggestionKey);

      // Case 1: the key is not initialized
      if (!valueFromStorage) {
        LocalStorage.set(suggestionKey, {
          [this.currentAccountId]: [],
        });
        return LocalStorage.get(suggestionKey);
      }

      // Case 2: the key is initialized, but account ID is not present
      if (!valueFromStorage[this.currentAccountId]) {
        valueFromStorage[this.currentAccountId] = [];
        LocalStorage.set(suggestionKey, valueFromStorage);
        return LocalStorage.get(suggestionKey);
      }

      return valueFromStorage;
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
    },
  },
};
</script>

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
    font-size: var(--font-size-micro);
    line-height: var(--font-size-big);
  }
}
</style>
