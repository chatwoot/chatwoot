<template>
  <div
    v-on-clickaway="onCloseDropdown"
    class="selector-wrap"
    @keyup.esc="onCloseDropdown"
  >
    <woot-button
      variant="hollow"
      color-scheme="secondary"
      class="selector-button"
      @click="toggleDropdown"
    >
      <div class="selector-user-wrap">
        <div class="selector-name-wrap">
          <h4
            v-if="!hasValue"
            class="not-selected text-ellipsis text-block-title"
          >
            {{ singleSelectorPlaceholder }}
          </h4>
          <h4
            v-else
            class="selector-name text-truncate text-block-title"
            :title="selectedItem"
          >
            {{ selectedItem }}
          </h4>
          <i v-if="showDropdown" class="icon ion-chevron-up" />
          <i v-else class="icon ion-chevron-down" />
        </div>
      </div>
    </woot-button>
    <div
      v-if="showDropdown"
      :class="{ 'dropdown-pane--open': showDropdown }"
      class="dropdown-pane"
    >
      <single-select-dropdown-items
        :list-values="listValues"
        :selected-item="selectedItem"
        @click="onClickSelectItem"
      />
    </div>
  </div>
</template>

<script>
import SingleSelectDropdownItems from './SingleSelectDropdownItems.vue';
import { mixin as clickaway } from 'vue-clickaway';
export default {
  components: {
    SingleSelectDropdownItems,
  },
  mixins: [clickaway],
  props: {
    listValues: {
      type: Array,
      default: () => [],
    },
    selectedItem: {
      type: String,
      default: '',
    },
    singleSelectorPlaceholder: {
      type: String,
      default: 'Select',
    },
  },
  data() {
    return {
      showDropdown: false,
    };
  },
  computed: {
    hasValue() {
      if (this.selectedItem) {
        return true;
      }
      return false;
    },
  },
  methods: {
    toggleDropdown() {
      this.showDropdown = !this.showDropdown;
    },
    onCloseDropdown() {
      this.showDropdown = false;
    },
    onClickSelectItem(listValue) {
      this.$emit('click', listValue);
    },
  },
};
</script>

<style lang="scss" scoped>
.selector-wrap {
  position: relative;
  width: 100%;
  margin: 0;
  top: var(--space-micro);

  .selector-button {
    width: 100%;
    border: 1px solid var(--color-border);

    &:hover {
      border: 1px solid var(--color-border);
    }
  }

  .selector-user-wrap {
    display: flex;
  }

  .selector-name-wrap {
    display: flex;
    justify-content: space-between;
    width: 100%;
    min-width: 0;
    align-items: center;
  }

  .not-selected {
    margin: 0 var(--space-small) 0 0;
  }

  .selector-name {
    align-items: center;
    margin: 0 var(--space-small) 0 0;
  }

  .dropdown-pane {
    box-sizing: border-box;
    top: 4.2rem;
    width: 100%;
  }
}
</style>
