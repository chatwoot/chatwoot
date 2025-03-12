<script>
import LabelDropdownItem from './LabelDropdownItem.vue';
import Hotkey from 'dashboard/components/base/Hotkey.vue';
import AddLabelModal from 'dashboard/routes/dashboard/settings/labels/AddLabel.vue';
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
  emits: ['update', 'add', 'remove'],

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

<template>
  <div class="flex flex-col w-full max-h-[12.5rem]">
    <div class="flex items-center justify-center mb-1">
      <h4
        class="flex-grow m-0 overflow-hidden text-sm text-slate-800 dark:text-slate-100 whitespace-nowrap text-ellipsis"
      >
        {{ $t('CONTACT_PANEL.LABELS.LABEL_SELECT.TITLE') }}
      </h4>
      <Hotkey
        custom-class="border border-solid text-slate-800 dark:text-slate-100 bg-slate-50 dark:bg-slate-600 text-xxs border-slate-75 dark:border-slate-600"
      >
        {{ 'L' }}
      </Hotkey>
    </div>
    <div class="flex-auto flex-grow-0 flex-shrink-0 mb-2 max-h-8">
      <input
        ref="searchbar"
        v-model="search"
        type="text"
        class="search-input"
        autofocus="true"
        :placeholder="$t('CONTACT_PANEL.LABELS.LABEL_SELECT.PLACEHOLDER')"
      />
    </div>
    <div
      class="flex items-start justify-start flex-auto flex-grow flex-shrink overflow-auto"
    >
      <div class="w-full">
        <woot-dropdown-menu>
          <LabelDropdownItem
            v-for="label in filteredActiveLabels"
            :key="label.title"
            :title="label.title"
            :color="label.color"
            :selected="selectedLabels.includes(label.title)"
            @select-label="onAddRemove(label)"
          />
        </woot-dropdown-menu>
        <div
          v-if="noResult"
          class="flex justify-center py-4 px-2.5 font-medium text-xs text-slate-700 dark:text-slate-200"
        >
          {{ $t('CONTACT_PANEL.LABELS.LABEL_SELECT.NO_RESULT') }}
        </div>
        <div
          v-if="allowCreation && shouldShowCreate"
          class="flex pt-1 border-t border-solid border-slate-100 dark:border-slate-900"
        >
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
            v-model:show="createModalVisible"
            :on-close="hideCreateModal"
          >
            <AddLabelModal
              :prefill-title="parsedSearch"
              @close="hideCreateModal"
            />
          </woot-modal>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.hotkey {
  @apply flex-shrink-0;
}

.search-input {
  @apply m-0 w-full border border-solid border-transparent h-8 text-sm text-slate-700 dark:text-slate-100 rounded-md focus:border-woot-500 bg-slate-50 dark:bg-slate-900;
}

.button-new-label {
  @apply whitespace-nowrap text-ellipsis overflow-hidden items-center;

  .icon {
    @apply min-w-0;
  }
}
</style>
