<template>
  <div class="sidebar-labels-wrap">
    <div
      v-if="!conversationUiFlags.isFetching"
      class="contact-conversation--list"
    >
      <div
        v-on-clickaway="closeDropdownLabel"
        class="label-wrap"
        @keyup.esc="closeDropdownLabel"
      >
        <add-label @add="toggleLabels" />
        <woot-label
          v-for="label in activeLabels"
          :key="label.id"
          :title="label.title"
          :description="label.description"
          :show-close="true"
          :color="label.color"
          variant="smooth"
          class="max-w-[calc(100%-0.5rem)]"
          @click="removeLabelFromConversation"
        />

        <div class="dropdown-wrap">
          <div
            :class="{ 'dropdown-pane--open': showSearchDropdownLabel }"
            class="dropdown-pane"
          >
            <label-dropdown
              v-if="showSearchDropdownLabel"
              :account-labels="accountLabels"
              :selected-labels="savedLabels"
              :allow-creation="isAdmin"
              @add="addLabelToConversation"
              @remove="removeLabelFromConversation"
            />
          </div>
        </div>
      </div>
    </div>
    <spinner v-else />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { useAdmin } from 'dashboard/composables/useAdmin';
import Spinner from 'shared/components/Spinner.vue';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown.vue';
import AddLabel from 'shared/components/ui/dropdown/AddLabel.vue';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';

export default {
  components: {
    Spinner,
    LabelDropdown,
    AddLabel,
  },

  mixins: [conversationLabelMixin, keyboardEventListenerMixins],
  props: {
    conversationId: {
      type: Number,
      required: true,
    },
  },
  setup() {
    const { isAdmin } = useAdmin();
    return {
      isAdmin,
    };
  },
  data() {
    return {
      selectedLabels: [],
      showSearchDropdownLabel: false,
    };
  },

  computed: {
    ...mapGetters({
      conversationUiFlags: 'conversationLabels/getUIFlags',
      labelUiFlags: 'conversationLabels/getUIFlags',
    }),
  },
  methods: {
    toggleLabels() {
      this.showSearchDropdownLabel = !this.showSearchDropdownLabel;
    },
    closeDropdownLabel() {
      this.showSearchDropdownLabel = false;
    },
    getKeyboardEvents() {
      return {
        KeyL: {
          action: e => {
            e.preventDefault();
            this.toggleLabels();
          },
        },
        Escape: {
          action: () => {
            if (this.showSearchDropdownLabel) {
              this.toggleLabels();
            }
          },
          allowOnFocusedInput: true,
        },
      };
    },
  },
};
</script>

<style lang="scss" scoped>
.sidebar-labels-wrap {
  margin-bottom: 0;
}
.contact-conversation--list {
  width: 100%;

  .label-wrap {
    line-height: var(--space-medium);
    position: relative;

    .dropdown-wrap {
      display: flex;
      left: -1px;
      margin-right: var(--space-medium);
      position: absolute;
      top: var(--space-medium);
      width: 100%;

      .dropdown-pane {
        width: 100%;
        box-sizing: border-box;
      }
    }
  }
}

.error {
  color: var(--r-500);
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-medium);
}
</style>
