<template>
  <div class="contact-conversation--panel sidebar-labels-wrap">
    <div
      v-if="!conversationUiFlags.isFetching"
      class="contact-conversation--list"
    >
      <contact-details-item
        :title="$t('CONTACT_PANEL.LABELS.TITLE')"
        icon="ion-pricetags"
        :show-edit="true"
        @edit="onEdit"
      />
      <woot-label
        v-for="label in activeLabels"
        :key="label.id"
        :title="label.title"
        :description="label.description"
        :bg-color="label.color"
      />
      <div v-if="!activeLabels.length">
        {{ $t('CONTACT_PANEL.LABELS.NO_AVAILABLE_LABELS') }}
      </div>
      <add-label-to-conversation
        v-if="isEditing"
        :conversation-id="conversationId"
        :account-labels="accountLabels"
        :saved-labels="savedLabels"
        :show.sync="isEditing"
        :on-close="closeEditModal"
        :update-labels="onUpdateLabels"
      />
    </div>
    <spinner v-else></spinner>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import AddLabelToConversation from './AddLabelToConversation';
import ContactDetailsItem from '../ContactDetailsItem';
import Spinner from 'shared/components/Spinner';

export default {
  components: {
    AddLabelToConversation,
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
      isEditing: false,
      selectedLabels: [],
    };
  },
  computed: {
    savedLabels() {
      return this.$store.getters['conversationLabels/getConversationLabels'](
        this.conversationId
      );
    },
    ...mapGetters({
      conversationUiFlags: 'contactConversations/getUIFlags',
      labelUiFlags: 'conversationLabels/getUIFlags',
      accountLabels: 'labels/getLabels',
    }),
    activeLabels() {
      return this.accountLabels.filter(({ title }) =>
        this.savedLabels.includes(title)
      );
    },
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
    async onUpdateLabels(selectedLabels) {
      try {
        await this.$store.dispatch('conversationLabels/update', {
          conversationId: this.conversationId,
          labels: selectedLabels,
        });
      } catch (error) {
        // Ignore error
      }
    },
    onEdit() {
      this.isEditing = true;
    },
    closeEditModal() {
      bus.$emit('fetch_conversation_stats');
      this.isEditing = false;
    },
    async fetchLabels(conversationId) {
      if (!conversationId) {
        return;
      }
      this.$store.dispatch('conversationLabels/get', conversationId);
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
