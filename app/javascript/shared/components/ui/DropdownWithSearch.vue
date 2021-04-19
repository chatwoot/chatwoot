<template>
  <div class="dropdown-search-wrap">
    <div class="search-wrap">
      <input
        ref="searchbar"
        v-model="search"
        type="text"
        class="search-input"
        autofocus="true"
        placeholder="Filter"
      />
    </div>
    <div class="list-wrap">
      <div class="list">
        <woot-dropdown-menu>
          <woot-dropdown-item
            v-for="option in filteredOptions"
            :key="option.id"
          >
            <button
              class="button clear"
              :class="{ active: option.id === (value && value.id) }"
              @click="() => onclick(option)"
            >
              <Thumbnail
                :src="option.thumbnail"
                size="25px"
                :username="option.name"
              />
              <div class="name-icon-wrap">
                <div class="name">
                  {{ option.name }}
                </div>
                <i
                  v-if="option.id === (value && value.id)"
                  class="icon ion-checkmark-round"
                />
              </div>
            </button>
          </woot-dropdown-item>
        </woot-dropdown-menu>
        <div v-if="noResult" class="button clear no-result">
          {{ $t('AGENT_MGMT.SEARCH.NO_RESULTS') }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import Thumbnail from 'components/widgets/Thumbnail.vue';
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
    value: {
      type: Object,
      default: () => ({}),
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
.dropdown-search-wrap {
  width: 100%;

  .search-wrap {
    margin-bottom: var(--space-small);

    .search-input {
      margin: 0;
      width: 100%;
      border: none;
      height: var(--space-large);
      font-size: var(--font-size-small);
      padding: var(--space-small);
      background-color: var(--color-background);
    }

    input:focus {
      border: 1px solid var(--w-500);
    }
  }

  .list-wrap {
    display: flex;
    justify-content: flex-start;
    align-items: flex-start;

    .list {
      width: 100%;

      .button {
        display: flex;
        justify-content: flex-start;

        &.active {
          display: flex;
          font-weight: 600;
          color: #1a4d8f;
        }

        .name-icon-wrap {
          display: flex;
          justify-content: space-between;
          padding: 0.5rem;
        }

        .name {
          padding: 0 var(--space-smaller);
          line-height: var(--space-normal);
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }

        .icon {
          margin-left: var(--space-smaller);
        }
      }
      .no-result {
        display: flex;
        justify-content: center;
      }
    }
  }
}
</style>
