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
            v-for="label in filteredActiveLabels"
            :key="label.title"
          >
            <div class="name-label-icon-wrap">
              <button class="button clear" @click="() => onAddRemove(label)">
                <div class="name-label-wrap">
                  <div
                    v-if="label.color"
                    class="label-color--display"
                    :style="{ backgroundColor: label.color }"
                  />
                  <span>{{ label.title }}</span>
                </div>
                <i
                  v-if="selectLabels.includes(label.title)"
                  class="icon ion-checkmark-round"
                />
              </button>
            </div>
          </woot-dropdown-item>
        </woot-dropdown-menu>
        <div v-if="noResult" class="button clear no-result">
          {{ 'No labels found' }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
export default {
  components: {
    WootDropdownItem,
    WootDropdownMenu,
  },

  props: {
    conversationId: {
      type: [String, Number],
      required: true,
    },
    accountLabels: {
      type: Array,
      default: () => [],
    },
    selectLabels: {
      type: Array,
      default: () => [],
    },
    updateLabels: {
      type: Function,
      default: () => {},
    },
  },

  data() {
    return {
      search: '',
    };
  },

  computed: {
    filteredActiveLabels() {
      return this.accountLabels.filter(label => {
        return label.title.toLowerCase().includes(this.search.toLowerCase());
      });
    },

    noResult() {
      return this.filteredActiveLabels.length === 0 && this.search !== '';
    },
  },

  mounted() {
    this.focusInput();
  },

  methods: {
    onclick(label) {
      this.$emit('click', label);
    },

    focusInput() {
      this.$refs.searchbar.focus();
    },

    onAdd(label) {
      this.updateLabels([...this.selectLabels, label.title]);
    },

    onRemove(label) {
      const activeLabels = this.selectLabels.filter(
        activeLabel => activeLabel !== label.title
      );
      this.updateLabels(activeLabels);
    },

    onAddRemove(label) {
      if (this.selectLabels.includes(label.title)) {
        this.onRemove(label);
      } else {
        this.onAdd(label);
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.dropdown-search-wrap {
  display: flex;
  flex-direction: column;
  width: 100%;
  max-height: 18rem;

  .search-wrap {
    margin-bottom: var(--space-small);
    flex: 0 0 auto;
    max-height: var(--space-large);

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
    flex: 1 1 auto;
    overflow: auto;

    .list {
      width: 100%;
      max-height: 14.8rem;

      .name-label-icon-wrap {
        display: flex;

        .button {
          display: flex;
          justify-content: space-between;

          &.active {
            display: flex;
            font-weight: 600;
            color: #1a4d8f;
          }

          .name-label-wrap {
            display: flex;
          }

          .label-color--display {
            margin-right: var(--space-small);
          }

          .icon {
            font-size: 1.4rem;
          }
        }

        .label-color--display {
          border-radius: var(--border-radius-normal);
          height: var(--space-slab);
          margin-right: var(--space-smaller);
          margin-top: var(--space-micro);
          min-width: var(--space-slab);
          width: var(--space-slab);
        }
      }
    }

    .no-result {
      display: flex;
      justify-content: center;
    }
  }
}
</style>
