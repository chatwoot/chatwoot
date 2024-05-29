<template>
  <div
    v-on-clickaway="onCloseDropdown"
    class="relative w-full mb-2"
    @keyup.esc="onCloseDropdown"
  >
    <woot-button
      variant="hollow"
      color-scheme="secondary"
      class="w-full border border-solid border-slate-100 dark:border-slate-700 px-2 hover:border-slate-75 dark:hover:border-slate-600"
      @click="toggleDropdown"
    >
      <div class="flex gap-1">
        <Thumbnail
          v-if="hasValue && hasThumbnail"
          :src="selectedItem.thumbnail"
          size="24px"
          :status="selectedItem.availability_status"
          :username="selectedItem.name"
        />
        <div class="flex justify-between w-full min-w-0 items-center">
          <h4
            v-if="!hasValue"
            class="text-ellipsis text-sm text-slate-800 dark:text-slate-100"
          >
            {{ multiselectorPlaceholder }}
          </h4>
          <h4
            v-else
            class="items-center leading-tight overflow-hidden whitespace-nowrap text-ellipsis text-sm text-slate-800 dark:text-slate-100"
            :title="selectedItem.name"
          >
            {{ selectedItem.name }}
          </h4>
          <i
            v-if="showSearchDropdown"
            class="icon ion-chevron-up text-slate-600 mr-1"
          />
          <i v-else class="icon ion-chevron-down text-slate-600 mr-1" />
        </div>
      </div>
    </woot-button>
    <div
      :class="{ 'dropdown-pane--open': showSearchDropdown }"
      class="dropdown-pane"
    >
      <div class="flex justify-between items-center mb-1">
        <h4
          class="text-sm text-slate-800 dark:text-slate-100 m-0 overflow-hidden whitespace-nowrap text-ellipsis"
        >
          {{ multiselectorTitle }}
        </h4>
        <woot-button
          icon="dismiss"
          size="tiny"
          color-scheme="secondary"
          variant="clear"
          @click="onCloseDropdown"
        />
      </div>
      <multiselect-dropdown-items
        v-if="showSearchDropdown"
        :options="options"
        :selected-items="[selectedItem]"
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
import MultiselectDropdownItems from 'shared/components/ui/MultiselectDropdownItems.vue';
export default {
  components: {
    Thumbnail,
    MultiselectDropdownItems,
  },
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
.dropdown-pane {
  @apply box-border top-[2.625rem] w-full;
}
</style>
