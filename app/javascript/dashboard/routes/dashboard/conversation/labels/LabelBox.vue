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
import Spinner from 'shared/components/Spinner.vue';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown.vue';
import AddLabel from 'shared/components/ui/dropdown/AddLabel.vue';
import { mixin as clickaway } from 'vue-clickaway';
import adminMixin from 'dashboard/mixins/isAdmin';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';
import {
  buildHotKeys,
  isEscape,
  isActiveElementTypeable,
} from 'shared/helpers/KeyboardHelpers';

export default {
  components: {
    Spinner,
    LabelDropdown,
    AddLabel,
  },

  mixins: [clickaway, conversationLabelMixin, adminMixin, eventListenerMixins],
  props: {
    conversationId: {
      type: Number,
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
    handleKeyEvents(e) {
      const keyPattern = buildHotKeys(e);

      if (keyPattern === 'l' && !isActiveElementTypeable(e)) {
        this.toggleLabels();
        e.preventDefault();
      } else if (isEscape(e) && this.showSearchDropdownLabel) {
        this.closeDropdownLabel();
        e.preventDefault();
      }
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
