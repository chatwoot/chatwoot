<script>
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  components: {
    WootDropdownItem,
    WootDropdownMenu,
    Thumbnail,
  },

  props: {
    options: {
      type: Array,
      default: () => [],
    },
    selectedItems: {
      type: Array,
      default: () => [],
    },
    hasThumbnail: {
      type: Boolean,
      default: true,
    },
    inputPlaceholder: {
      type: String,
      default: 'Search',
    },
    noSearchResult: {
      type: String,
      default: 'No results found',
    },
  },
  emits: ['select'],

  data() {
    return {
      search: '',
    };
  },

  computed: {
    filteredOptions() {
      return this.options.filter(option => {
        return option.name.toLowerCase().includes(this.search.toLowerCase());
      });
    },
    noResult() {
      return this.filteredOptions.length === 0 && this.search !== '';
    },
  },

  mounted() {
    this.focusInput();
  },

  methods: {
    onclick(option) {
      this.$emit('select', option);
    },
    focusInput() {
      this.$refs.searchbar.focus();
    },
    isActive(option) {
      return this.selectedItems.some(item => item && option.id === item.id);
    },
  },
};
</script>

<template>
  <div class="dropdown-wrap">
    <div class="mb-2 flex-shrink-0 flex-grow-0 flex-auto max-h-8">
      <input
        ref="searchbar"
        v-model="search"
        type="text"
        class="search-input"
        autofocus="true"
        :placeholder="inputPlaceholder"
      />
    </div>
    <div class="flex justify-start items-start flex-auto overflow-auto">
      <div class="w-full max-h-[10rem]">
        <WootDropdownMenu>
          <WootDropdownItem v-for="option in filteredOptions" :key="option.id">
            <woot-button
              class="multiselect-dropdown--item"
              :variant="isActive(option) ? 'hollow' : 'clear'"
              color-scheme="secondary"
              :class="{
                active: isActive(option),
              }"
              @click="() => onclick(option)"
            >
              <div class="flex items-center gap-1.5">
                <Thumbnail
                  v-if="hasThumbnail"
                  :src="option.thumbnail"
                  size="24px"
                  :username="option.name"
                  :status="option.availability_status"
                  has-border
                />
                <div
                  class="flex items-center justify-between w-full min-w-0 gap-2"
                >
                  <span
                    class="leading-4 my-0 overflow-hidden whitespace-nowrap text-ellipsis text-sm"
                    :title="option.name"
                  >
                    {{ option.name }}
                  </span>
                  <fluent-icon v-if="isActive(option)" icon="checkmark" />
                </div>
              </div>
            </woot-button>
          </WootDropdownItem>
        </WootDropdownMenu>
        <h4
          v-if="noResult"
          class="w-full justify-center items-center flex text-slate-500 dark:text-slate-300 py-2 px-2.5 overflow-hidden whitespace-nowrap text-ellipsis text-sm"
        >
          {{ noSearchResult }}
        </h4>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.dropdown-wrap {
  @apply w-full flex flex-col max-h-[12.5rem];
}

.search-input {
  @apply m-0 w-full border border-solid border-transparent h-8 text-sm text-slate-700 dark:text-slate-100 rounded-md focus:border-woot-500 bg-slate-50 dark:bg-slate-900;
}

.multiselect-dropdown--item {
  @apply justify-between w-full;

  &.active {
    @apply bg-slate-25 dark:bg-slate-700 border-slate-50 dark:border-slate-900 font-medium;
  }

  &:focus {
    @apply bg-slate-25 dark:bg-slate-700;
  }

  &:hover {
    @apply bg-slate-50 dark:bg-slate-800 text-slate-800 dark:text-slate-100;
  }
}
</style>
