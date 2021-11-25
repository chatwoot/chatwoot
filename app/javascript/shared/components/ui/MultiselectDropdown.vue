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
        <Thumbnail
          v-if="hasValue && hasThumbnail"
          :src="selectedItem.thumbnail"
          size="24px"
          :status="selectedItem.availability_status"
          :username="selectedItem.name"
        />
        <div class="selector-name-wrap">
          <h4
            v-if="!hasValue"
            class="not-selected text-ellipsis text-block-title"
          >
            {{ multiselectorPlaceholder }}
          </h4>
          <h4
            v-else
            class="selector-name text-truncate text-block-title"
            :title="selectedItem.name"
          >
            {{ selectedItem.name }}
          </h4>
          <i v-if="showSearchDropdown" class="icon ion-chevron-up" />
          <i v-else class="icon ion-chevron-down" />
        </div>
      </div>
    </woot-button>
    <div
      :class="{ 'dropdown-pane--open': showSearchDropdown }"
      class="dropdown-pane"
    >
      <h4 class="text-block-title text-truncate">
        {{ multiselectorTitle }}
      </h4>
      <multiselect-dropdown-items
        v-if="showSearchDropdown"
        :options="options"
        :selected-item="selectedItem"
        :has-thumbnail="hasThumbnail"
        :input-placeholder="inputPlaceholder"
        :no-search-result="noSearchResult"
        @click="onClickSelectItem"
      />
    </div>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import MultiselectDropdownItems from 'shared/components/ui/MultiselectDropdownItems';
import { mixin as clickaway } from 'vue-clickaway';
export default {
  components: {
    Thumbnail,
    MultiselectDropdownItems,
  },
  mixins: [clickaway],
  props: {
    options: {
      type: Array,
      default: () => [],
    },
    selectedItem: {
      type: Object,
      default: () => ({}),
    },
    hasThumbnail: {
      type: Boolean,
      default: true,
    },
    multiselectorTitle: {
      type: String,
      default: '',
    },
    multiselectorPlaceholder: {
      type: String,
      default: 'None',
    },
    noSearchResult: {
      type: String,
      default: 'No results found',
    },
    inputPlaceholder: {
      type: String,
      default: 'Search',
    },
  },
  data() {
    return {
      showSearchDropdown: false,
    };
  },
  computed: {
    hasValue() {
      if (this.selectedItem && this.selectedItem.id) {
        return true;
      }
      return false;
    },
  },
  methods: {
    toggleDropdown() {
      this.showSearchDropdown = !this.showSearchDropdown;
    },

    onCloseDropdown() {
      this.showSearchDropdown = false;
    },

    onClickSelectItem(value) {
      this.$emit('click', value);
      this.onCloseDropdown();
    },
  },
};
</script>

<style lang="scss" scoped>
.selector-wrap {
  position: relative;
  width: 100%;
  margin-right: var(--space-one);
  margin-bottom: var(--space-small);

  .selector-button {
    width: 100%;
    border: 1px solid var(--color-border);
    padding-left: var(--space-one);
    padding-right: var(--space-one);

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
    margin: 0 var(--space-small);
  }

  .dropdown-pane {
    box-sizing: border-box;
    top: 4.2rem;
    width: 100%;
  }
}
</style>
