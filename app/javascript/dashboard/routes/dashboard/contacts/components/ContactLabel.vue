<template>
  <div>
    <h6 class="text-block-title">
      Contact Label
    </h6>
    <div class="label-wrap">
      <add-label @add="toggleLabels" />
      <woot-label
        v-for="label in savedLabels"
        :key="label.id"
        :title="label.title"
        :description="label.description"
        :show-close="true"
        :bg-color="label.color"
        @click="removeItem"
      />
      <div class="dropdown-wrap">
        <div :class="{ 'dropdown-pane--open': showSearchDropdownLabel }">
          <label-dropdown
            v-if="showSearchDropdownLabel"
            :v-for="label in selectedLabels"
            :account-labels="allLabels"
            :selected-labels="selectedLabels"
            :conversation-id="conversationId"
            @add="addItem"
            @remove="removeItem"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import AddLabel from 'shared/components/ui/dropdown/AddLabel';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown';
export default {
  components: {
    AddLabel,
    LabelDropdown,
  },

  props: {
    conversationId: {
      type: [String, Number],
      required: true,
    },
    allLabels: {
      type: Array,
      default: () => [],
    },
    selectedLabels: {
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
  },
};
</script>

<style lang="scss" scoped>
.label-wrap {
  position: relative;

  .dropdown-wrap {
    display: flex;
    position: absolute;
    width: 100%;
  }
}
</style>
