<template>
  <div class="dropdown-search-wrap">
    <h4 class="text-block-title">
      {{ $t('CONTACT_PANEL.LABELS.LABEL_SELECT.TITLE') }}
    </h4>
    <div class="search-wrap">
      <input
        ref="searchbar"
        v-model="search"
        type="text"
        class="search-input"
        autofocus="true"
        :placeholder="$t('CONTACT_PANEL.LABELS.LABEL_SELECT.PLACEHOLDER')"
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
                  v-if="selectedLabels.includes(label.title)"
                  class="icon ion-checkmark-round"
                />
              </button>
            </div>
          </woot-dropdown-item>
        </woot-dropdown-menu>
        <div v-if="noResult" class="no-result">
          {{ $t('CONTACT_PANEL.LABELS.LABEL_SELECT.NO_RESULT') }}
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
    selectedLabels: {
      type: Array,
      default: () => [],
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

    updateLabels(label) {
      this.$emit('update', label);
    },

    onAdd(label) {
      this.$emit('add', label);
    },

    onRemove(label) {
      this.$emit('remove', label);
    },

    onAddRemove(label) {
      if (this.selectedLabels.includes(label.title)) {
        this.onRemove(label.title);
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
  max-height: 20rem;

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
      max-height: 16.8rem;

      .name-label-icon-wrap {
        display: flex;

        .button {
          display: flex;
          justify-content: space-between;

          &.active {
            display: flex;
            font-weight: var(--font-weight-bold);
            color: #1a4d8f;
          }

          .name-label-wrap {
            display: flex;
          }

          .label-color--display {
            margin-right: var(--space-small);
          }

          .icon {
            font-size: var(--font-size-small);
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
      color: var(--s-700);
      padding: var(--space-smaller) var(--space-one);
      font-weight: var(--font-weight-medium);
      font-size: var(--font-size-small);
    }
  }
}
</style>
