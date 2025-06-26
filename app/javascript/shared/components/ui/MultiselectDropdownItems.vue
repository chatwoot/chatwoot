<script>
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    WootDropdownItem,
    WootDropdownMenu,
    Thumbnail,
    NextButton,
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
    <div class="flex-auto flex-grow-0 flex-shrink-0 mb-2 max-h-8">
      <input
        ref="searchbar"
        v-model="search"
        type="text"
        class="search-input"
        autofocus="true"
        :placeholder="inputPlaceholder"
      />
    </div>
    <div class="flex items-start justify-start flex-auto overflow-auto mt-2">
      <div class="w-full max-h-[10rem]">
        <WootDropdownMenu>
          <WootDropdownItem v-for="option in filteredOptions" :key="option.id">
            <NextButton
              slate
              :variant="isActive(option) ? 'faded' : 'ghost'"
              trailing-icon
              :icon="isActive(option) ? 'i-lucide-check' : ''"
              class="w-full !px-2.5"
              @click="() => onclick(option)"
            >
              <div
                class="flex items-center justify-between w-full min-w-0 gap-2"
              >
                <span
                  class="my-0 overflow-hidden text-sm leading-4 whitespace-nowrap text-ellipsis"
                  :title="option.name"
                >
                  {{ option.name }}
                </span>
              </div>
              <Thumbnail
                v-if="hasThumbnail"
                :src="option.thumbnail"
                size="24px"
                :username="option.name"
                :status="option.availability_status"
                has-border
              />
            </NextButton>
          </WootDropdownItem>
        </WootDropdownMenu>
        <h4
          v-if="noResult"
          class="w-full justify-center items-center flex text-n-slate-10 py-2 px-2.5 overflow-hidden whitespace-nowrap text-ellipsis text-sm"
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
    @apply bg-n-slate-2 dark:bg-n-solid-3 border-n-weak/50 dark:border-n-weak font-medium;
  }

  &:hover {
    @apply bg-n-slate-2 dark:bg-n-solid-3 text-slate-800 dark:text-slate-100;
  }
}
</style>
