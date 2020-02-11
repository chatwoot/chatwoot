<template>
  <div
    class="contact-conversation--panel sidebar-labels-wrap"
    :class="hasEditedClass"
  >
    <div v-if="!conversationUiFlags.isFetching" class="wrap">
      <div class="contact-conversation--list">
        <label class="select-tags">
          {{ $t('CONTACT_PANEL.LABELS.TITLE') }}
          <p v-if="!savedLabels.length && !showLabelInput" class="no-results">
            {{ $t('CONTACT_PANEL.LABELS.NO_RECORDS_FOUND') }}
            <button
              type="button success"
              class="button nice tiny"
              @click="showLabelBox"
            >
              {{ $t('CONTACT_PANEL.LABELS.ADD_BUTTON') }}
            </button>
          </p>
          <multiselect
            v-if="showLabelInput || savedLabels.length"
            v-model="selectedLabels"
            :options="savedLabels"
            tag-placeholder="Add this as new tag"
            placeholder="Search or add a tag"
            :multiple="true"
            :taggable="true"
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
    </div>
    <spinner v-else></spinner>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner';
import ConversationAPI from '../../../api/conversations';

export default {
  components: {
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
      showLabelInput: false,
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
        this.$store
          .dispatch('conversationLabels/get', newConversationId)
          .then(() => {
            this.selectedLabels = [...this.savedLabels];
          });
      }
    },
  },
  mounted() {
    this.$store
      .dispatch('conversationLabels/get', this.conversationId)
      .then(() => {
        this.selectedLabels = [...this.savedLabels];
      });
  },
  methods: {
    addLabel(label) {
      this.selectedLabels = [...this.selectedLabels, label];
    },
    asyncSearchLabels(query) {
      this.isSearching = true;
      ConversationAPI(query).then(response => {
        this.countries = response;
        this.isLoading = false;
      });
    },
    onUpdateLabels() {
      this.$store.dispatch('conversationLabels/update', {
        conversationId: this.conversationId,
        labels: this.selectedLabels,
      });
    },
    showLabelBox() {
      this.showLabelInput = true;
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
.wrap {
  margin-top: $space-slab;
}

.select-tags {
  margin-top: $space-small;
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

.no-results {
  margin: $space-normal 0 0 0;
  color: $color-gray;
  padding: 0 $space-small;
  font-weight: $font-weight-normal;
}

.error {
  color: $alert-color;
  font-size: $font-size-mini;
  font-weight: $font-weight-medium;
}
</style>
