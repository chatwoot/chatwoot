<template>
  <div class="dropdown-search-wrap">
    <div class="dropdown-title-container">
      <h4 class="text-block-title">
        {{ $t('CONTACT_PANEL.LABELS.LABEL_SELECT.TITLE') }}
      </h4>
      <hotkey>L</hotkey>
    </div>
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
        <div v-if="allowCreation && shouldShowCreate" class="new-label">
          <woot-button
            size="small"
            variant="clear"
            color-scheme="secondary"
            icon="add"
            is-expanded
            class="button-new-label"
            :is-disabled="hasExactMatchInResults"
            @click="showCreateModal"
          >
            {{ createLabelPlaceholder }}
            {{ parsedSearch }}
          </woot-button>

          <woot-modal
            :show.sync="createModalVisible"
            :on-close="hideCreateModal"
          >
            <add-label-modal
              :prefill-title="parsedSearch"
              @close="hideCreateModal"
            />
          </woot-modal>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import LabelDropdownItem from './LabelDropdownItem';
import Hotkey from 'dashboard/components/base/Hotkey';
import AddLabelModal from 'dashboard/routes/dashboard/settings/labels/AddLabel';
import { picoSearch } from '@scmmishra/pico-search';
import { sanitizeLabel } from 'shared/helpers/sanitizeData';

export default {
  components: {
    LabelDropdownItem,
    AddLabelModal,
    Hotkey,
  },

  props: {
    accountLabels: {
      type: Array,
      default: () => [],
    },
    selectedLabels: {
      type: Array,
      default: () => [],
    },
    allowCreation: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      search: '',
      createModalVisible: false,
    };
  },

  computed: {
    createLabelPlaceholder() {
      const label = this.$t('CONTACT_PANEL.LABELS.LABEL_SELECT.CREATE_LABEL');
      return this.search ? `${label}:` : label;
    },

    filteredActiveLabels() {
      if (!this.search) return this.accountLabels;

      return picoSearch(this.accountLabels, this.search, ['title'], {
        threshold: 0.9,
      });
    },

    noResult() {
      return this.filteredActiveLabels.length === 0;
    },

    hasExactMatchInResults() {
      return this.filteredActiveLabels.some(
        label => label.title === this.search
      );
    },

    shouldShowCreate() {
      return this.allowCreation && this.filteredActiveLabels.length < 3;
    },

    parsedSearch() {
      return sanitizeLabel(this.search);
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

    showCreateModal() {
      this.createModalVisible = true;
    },

    hideCreateModal() {
      this.createModalVisible = false;
    },
  },
};
</script>

<style lang="scss" scoped>
.dropdown-title-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--space-smaller);

  .text-block-title {
    flex-grow: 1;
    margin: 0;
  }

  .hotkey {
    flex-shrink: 0;
  }
}

.dropdown-search-wrap {
  display: flex;
  flex-direction: column;
  width: 100%;
  max-height: 12.5rem;

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
      outline: 1px solid var(--color-border-dark);
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
      padding: var(--space-normal) var(--space-one);
      font-weight: var(--font-weight-medium);
      font-size: var(--font-size-mini);
    }

    .new-label {
      display: flex;
      padding-top: var(--space-smaller);
      border-top: 1px solid var(--s-100);

      .button-new-label {
        white-space: nowrap;
        text-overflow: ellipsis;
        overflow: hidden;
        align-items: center;

        .icon {
          min-width: 0;
        }
      }

      .search-term {
        color: var(--s-700);
      }
    }
  }
}
</style>
