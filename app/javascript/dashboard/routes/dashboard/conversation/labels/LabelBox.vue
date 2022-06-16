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
          :bg-color="label.color"
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
import Spinner from 'shared/components/Spinner';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown';
import AddLabel from 'shared/components/ui/dropdown/AddLabel';
import { mixin as clickaway } from 'vue-clickaway';
import conversationLabelMixin from 'dashboard/mixins/conversation/labelMixin';

export default {
  components: {
    Spinner,
    LabelDropdown,
    AddLabel,
  },

  mixins: [clickaway, conversationLabelMixin],
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
  },
};
</script>

<style lang="scss" scoped>
.sidebar-labels-wrap {
  margin-bottom: var(--space-normal);
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
