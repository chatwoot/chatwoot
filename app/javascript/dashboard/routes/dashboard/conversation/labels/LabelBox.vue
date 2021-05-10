<template>
  <div class="contact-conversation--panel sidebar-labels-wrap">
    <div
      v-if="!conversationUiFlags.isFetching"
      v-on-clickaway="closeDropdownLabel"
      class="contact-conversation--list"
    >
      <contact-details-item
        :title="$t('CONTACT_PANEL.LABELS.TITLE')"
        icon="ion-pricetags"
        emoji="🏷️"
      />
      <div class="label-wrap">
        <add-label @add="toggleLabels"></add-label>
        <woot-label
          v-for="label in activeLabels"
          :key="label.id"
          :title="label.title"
          :description="label.description"
          :bg-color="label.color"
        />
      </div>
      <div
        :class="{ 'dropdown-pane--open': showSearchDropdownLabel }"
        class="dropdown-pane"
      >
        <label-dropdown
          v-if="showSearchDropdownLabel"
          :account-labels="accountLabels"
          :selected-labels="savedLabels"
          :conversation-id="conversationId"
          @add="addItem"
          @remove="removeItem"
        />
      </div>
    </div>
    <spinner v-else></spinner>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ContactDetailsItem from '../ContactDetailsItem';
import Spinner from 'shared/components/Spinner';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown';
import AddLabel from 'shared/components/ui/dropdown/AddLabel';
import { mixin as clickaway } from 'vue-clickaway';

export default {
  components: {
    ContactDetailsItem,
    Spinner,
    LabelDropdown,
    AddLabel,
  },

  mixins: [clickaway],
  props: {
    conversationId: {
      type: [String, Number],
      required: true,
    },
  },

  data() {
    return {
      selectedLabels: [],
      showSearchDropdownLabel: false,
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

    toggleLabels() {
      this.showSearchDropdownLabel = !this.showSearchDropdownLabel;
    },

    addItem(value) {
      const result = this.activeLabels;
      result.push(value.title);
      this.onUpdateLabels(result);
    },

    removeItem(value) {
      const result = this.activeLabels.filter(label => label.title === value);
      this.onUpdateLabels(result);
    },

    closeDropdownLabel() {
      this.showSearchDropdownLabel = false;
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
  padding: var(--space-small) var(--space-slab) var(--space-normal)
    var(--space-slab);
}

.contact-conversation--list {
  width: 100%;
}

.error {
  color: var(--r-500);
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-medium);
}
</style>
