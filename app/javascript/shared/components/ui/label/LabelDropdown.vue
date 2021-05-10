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
          <label-dropdown-item
            v-for="label in filteredActiveLabels"
            :key="label.title"
            :title="label.title"
            :color="label.color"
            :selected="selectedLabels.includes(label.title)"
            @click="onAddRemove(label)"
          />
        </woot-dropdown-menu>
        <div v-if="noResult" class="no-result">
          {{ $t('CONTACT_PANEL.LABELS.LABEL_SELECT.NO_RESULT') }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import LabelDropdownItem from './LabelDropdownItem';
export default {
  components: {
    LabelDropdownItem,
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
      border: 1px solid transparent;
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
