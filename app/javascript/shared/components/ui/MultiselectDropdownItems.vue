<template>
  <div class="dropdown-wrap">
    <div class="search-wrap">
      <input
        ref="searchbar"
        v-model="search"
        type="text"
        class="search-input"
        autofocus="true"
        :placeholder="inputPlaceholder"
      />
    </div>
    <div class="list-scroll-container">
      <div class="dropdown-list">
        <woot-dropdown-menu>
          <woot-dropdown-item
            v-for="option in filteredOptions"
            :key="option.id"
          >
            <woot-button
              class="dropdown-item"
              variant="clear"
              :class="{
                active: option.id === (selectedItem && selectedItem.id),
              }"
              @click="() => onclick(option)"
            >
              <div class="user-wrap">
                <Thumbnail
                  :src="option.thumbnail"
                  size="24px"
                  :username="option.name"
                  :status="option.availability_status"
                />
                <div class="name-wrap">
                  <span
                    class="name text-truncate text-block-title"
                    :title="option.name"
                  >
                    {{ option.name }}
                  </span>
                  <i
                    v-if="option.id === (selectedItem && selectedItem.id)"
                    class="icon ion-checkmark-round"
                  />
                </div>
              </div>
            </woot-button>
          </woot-dropdown-item>
        </woot-dropdown-menu>
        <h4 v-if="noResult" class="no-result text-truncate text-block-title">
          {{ noSearchResult }}
        </h4>
      </div>
    </div>
  </div>
</template>

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
    selectedItem: {
      type: Object,
      default: () => ({}),
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
      this.$emit('click', option);
    },

    focusInput() {
      this.$refs.searchbar.focus();
    },
  },
};
</script>

<style lang="scss" scoped>
.dropdown-wrap {
  width: 100%;
  display: flex;
  flex-direction: column;
  max-height: 16rem;
}

.search-wrap {
  margin-bottom: var(--space-small);
  flex: 0 0 auto;
  max-height: var(--space-large);
}

.search-input {
  margin: 0;
  width: 100%;
  border: 1px solid transparent;
  height: var(--space-large);
  font-size: var(--font-size-small);
  padding: var(--space-small);
  background-color: var(--color-background);

  &:focus {
    border: 1px solid var(--w-500);
  }
}

.list-scroll-container {
  display: flex;
  justify-content: flex-start;
  align-items: flex-start;
  flex: 1 1 auto;
  overflow: auto;
}

.dropdown-list {
  width: 100%;
  max-height: 12rem;
}

.dropdown-item {
  justify-content: space-between;
  width: 100%;

  &.active {
    font-weight: var(--font-weight-bold);
  }
}

.user-wrap {
  display: flex;
  align-items: center;
}

.name-wrap {
  display: flex;
  justify-content: space-between;
  min-width: 0;
  width: 100%;
}

.name {
  line-height: var(--space-normal);
  margin: 0 var(--space-small);
}

.icon {
  margin-left: var(--space-smaller);
}

.no-result {
  display: flex;
  justify-content: center;
  width: 100%;
  padding: var(--space-small) var(--space-one);
}
</style>
