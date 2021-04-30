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
        <div>
          <woot-button class="button-wrap button hollow" @click="toggleLabels">
            <i class="ion-plus-round" />
            {{ $t('CONTACT_PANEL.LABELS.MODAL.ADD_BUTTON') }}
          </woot-button>
          <woot-label
            v-for="label in activeLabels"
            :key="label.id"
            :title="label.title"
            :description="label.description"
            :bg-color="label.color"
            :show-icon="true"
            @click="onRemove"
          />
        </div>
        <div class="dropdown-wrap">
          <div
            :class="{ 'dropdown-pane--open': showLabelSelector }"
            class="dropdown-pane"
          >
            <label-dropdown
              v-if="showLabelSelector"
              :selected-labels="savedLabels"
              :conversation-id="conversationId"
              :account-labels="accountLabels"
              @update="onUpdateLabels"
              @add="onAdd"
              @remove="onRemove"
            />
          </div>
        </div>
      </div>
    </div>
    <spinner v-else></spinner>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ContactDetailsItem from '../ContactDetailsItem';
import Spinner from 'shared/components/Spinner';
import LabelDropdown from 'shared/components/ui/LabelDropdown';
import WootButton from 'dashboard/components/ui/WootButton';
import { mixin as clickaway } from 'vue-clickaway';

export default {
  components: {
    ContactDetailsItem,
    Spinner,
    LabelDropdown,
    WootButton,
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
      showLabelSelector: false,
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
      this.showLabelSelector = !this.showLabelSelector;
    },

    closeDropdownLabel() {
      this.showLabelSelector = false;
    },

    async fetchLabels(conversationId) {
      if (!conversationId) {
        return;
      }
      this.$store.dispatch('conversationLabels/get', conversationId);
    },

    onAdd(label) {
      this.onUpdateLabels([...this.savedLabels, label.title]);
    },

    onRemove(label) {
      const activeLabels = this.savedLabels.filter(
        activeLabel => activeLabel !== label
      );
      this.onUpdateLabels(activeLabels);
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

  .label-wrap {
    margin-left: var(--space-medium);
    position: relative;

    .button-wrap {
      display: inline;
      padding: var(--space-smaller) var(--space-small);
      font-weight: var(--font-weight-bold);
      margin: var(--space-small) 0 var(--space-small) 0;
      color: var(--s-500);
      border-color: var(--s-500);
      font-size: var(--font-size-mini);
      line-height: 1.2;
    }
    .dropdown-wrap {
      display: flex;
      position: absolute;
      margin-right: var(--space-medium);
      top: 3.6rem;
      width: 100%;
      left: 0;

      .dropdown-pane {
        width: 100%;
        box-sizing: border-box;
      }
    }
  }
}

.no-label-message {
  color: var(--b-500);
}

.button {
  margin-top: var(--space-small);
  margin-left: auto;
}

.error {
  color: var(--r-500);
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-medium);
}
</style>
