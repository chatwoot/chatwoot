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
          @add="addItem"
          @remove="removeItem"
        />
      </div>
    </div>
  </div>
</template>

<script>
import AddLabel from 'shared/components/ui/dropdown/AddLabel';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown';
import { mixin as clickaway } from 'vue-clickaway';

export default {
  components: {
    AddLabel,
    LabelDropdown,
  },

  mixins: [clickaway],

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
