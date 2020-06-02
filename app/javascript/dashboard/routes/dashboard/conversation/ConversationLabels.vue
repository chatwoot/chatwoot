<template>
  <div
    class="contact-conversation--panel sidebar-labels-wrap"
    :class="hasEditedClass"
  >
    <div
      v-if="!conversationUiFlags.isFetching"
      class="contact-conversation--list"
    >
      <label class="select-tags">
        <contact-details-item
          :title="$t('CONTACT_PANEL.LABELS.TITLE')"
          icon="ion-pricetags"
        />
        <multiselect
          v-model="selectedLabels"
          :options="savedLabels"
          :tag-placeholder="$t('CONTACT_PANEL.LABELS.TAG_PLACEHOLDER')"
          :placeholder="$t('CONTACT_PANEL.LABELS.PLACEHOLDER')"
          :multiple="true"
          :taggable="true"
          hide-selected
          :show-labels="false"
          @tag="addLabel"
        />
      </label>
      <div class="row align-middle align-justify">
        <span v-if="labelUiFlags.isError" class="error">{{
          $t('CONTACT_PANEL.LABELS.UPDATE_ERROR')
        }}</span>
        <button
          v-if="hasEdited"
          type="button"
          class="button nice tiny"
          @click="onUpdateLabels"
        >
          <spinner v-if="labelUiFlags.isUpdating" size="tiny" />
          {{
            labelUiFlags.isUpdating
              ? 'saving...'
              : $t('CONTACT_PANEL.LABELS.UPDATE_BUTTON')
          }}
        </button>
      </div>
    </div>
    <spinner v-else></spinner>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ContactDetailsItem from './ContactDetailsItem';
import Spinner from 'shared/components/Spinner';

export default {
  components: {
    ContactDetailsItem,
    Spinner,
  },
  props: {
    conversationId: {
      type: [String, Number],
      required: true,
    },
  },
  data() {
    return {
      isSearching: false,
      selectedLabels: [],
    };
  },
  computed: {
    hasEdited() {
      if (this.selectedLabels.length !== this.savedLabels.length) {
        return true;
      }
      const isSame = this.selectedLabels.every(label =>
        this.savedLabels.includes(label)
      );
      return !isSame;
    },
    savedLabels() {
      const saved = this.$store.getters[
        'conversationLabels/getConversationLabels'
      ](this.conversationId);
      return saved;
    },
    hasEditedClass() {
      return this.hasEdited ? 'has-edited' : '';
    },
    ...mapGetters({
      conversationUiFlags: 'contactConversations/getUIFlags',
      labelUiFlags: 'conversationLabels/getUIFlags',
    }),
  },
  watch: {
    conversationId(newConversationId, prevConversationId) {
      if (newConversationId && newConversationId !== prevConversationId) {
        this.fetchLabels(newConversationId);
      }
    },
  },
  mounted() {
    const { conversationId } = this;
    this.fetchLabels(conversationId);
  },
  methods: {
    addLabel(label) {
      this.selectedLabels = [...this.selectedLabels, label];
    },
    onUpdateLabels() {
      this.$store.dispatch('conversationLabels/update', {
        conversationId: this.conversationId,
        labels: this.selectedLabels,
      });
    },
    async fetchLabels(conversationId) {
      try {
        await this.$store.dispatch('conversationLabels/get', conversationId);
        this.selectedLabels = [...this.savedLabels];
        // eslint-disable-next-line no-empty
      } catch (error) {}
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.contact-conversation--panel {
  padding: $space-normal;
}

.conversation--label {
  color: $color-white;
  margin-right: $space-small;
  font-size: $font-size-small;
  padding: $space-smaller;
}

.select-tags {
  .multiselect {
    &:hover {
      cursor: pointer;
    }
    transition: $transition-ease-in;
    margin-bottom: 0;
  }
}

.button {
  margin-top: $space-small;
  margin-left: auto;
}

.no-results-wrap {
  padding: 0 $space-small;
}

.no-results {
  margin: $space-normal 0 0 0;
  color: $color-gray;
  font-weight: $font-weight-normal;
}

.error {
  color: $alert-color;
  font-size: $font-size-mini;
  font-weight: $font-weight-medium;
}
</style>
