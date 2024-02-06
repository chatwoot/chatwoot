<template>
  <div v-on-clickaway="closeDropdownLabel" class="label-wrap">
    <add-label @add="toggleLabels" />
    <woot-label
      v-for="label in savedLabels"
      :key="label.id"
      :title="label.title"
      :description="label.description"
      :show-close="true"
      :color="label.color"
      variant="smooth"
      @click="removeItem"
    />
    <div class="dropdown-wrap">
      <div
        :class="{ 'dropdown-pane--open': showSearchDropdownLabel }"
        class="dropdown-pane"
      >
        <label-dropdown
          v-if="showSearchDropdownLabel"
          :account-labels="allLabels"
          :selected-labels="selectedLabels"
          :allow-creation="isAdmin"
          @add="addItem"
          @remove="removeItem"
        />
      </div>
    </div>
  </div>
</template>

<script>
import AddLabel from 'shared/components/ui/dropdown/AddLabel.vue';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown.vue';
import { mixin as clickaway } from 'vue-clickaway';
import adminMixin from 'dashboard/mixins/isAdmin';
import {
  buildHotKeys,
  isEscape,
  isActiveElementTypeable,
} from 'shared/helpers/KeyboardHelpers';

export default {
  components: {
    AddLabel,
    LabelDropdown,
  },

  mixins: [clickaway, adminMixin, eventListenerMixins],

  props: {
    allLabels: {
      type: Array,
      default: () => [],
    },
    savedLabels: {
      type: Array,
      default: () => [],
    },
  },

  data() {
    return {
      showSearchDropdownLabel: false,
    };
  },

  computed: {
    selectedLabels() {
      return this.savedLabels.map(label => label.title);
    },
  },

  methods: {
    addItem(label) {
      this.$emit('add', label);
    },

    removeItem(label) {
      this.$emit('remove', label);
    },

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
.title-icon {
  margin-right: var(--space-smaller);
}

.label-wrap {
  position: relative;
  line-height: var(--space-medium);

  .dropdown-wrap {
    display: flex;
    position: absolute;
    margin-right: var(--space-medium);
    top: var(--space-medium);
    width: 100%;
    left: -1px;

    .dropdown-pane {
      width: 100%;
      box-sizing: border-box;
    }
  }
}
</style>
