<script>
import LabelDropdownItem from './LabelDropdownItem.vue';
import Hotkey from 'dashboard/components/base/Hotkey.vue';
import AddLabelModal from 'dashboard/routes/dashboard/settings/labels/AddLabel.vue';
import { picoSearch } from '@chatwoot/pico-search';
import { sanitizeLabel } from 'shared/helpers/sanitizeData';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

export default {
  components: {
    LabelDropdownItem,
    AddLabelModal,
    Hotkey,
    NextButton,
    Icon,
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
    suggestedLabels: {
      type: Array,
      default: () => [],
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

      return picoSearch(this.accountLabels, this.search, ['title']);
    },

    shouldShowSuggestions() {
      return !this.search && this.suggestedLabels.length > 0;
    },

    // Suggested labels are listed in their own section, so skip them here
    listedLabels() {
      if (!this.shouldShowSuggestions) return this.filteredActiveLabels;

      const suggestedTitles = this.suggestedLabels.map(({ title }) => title);
      return this.filteredActiveLabels.filter(
        ({ title }) => !suggestedTitles.includes(title)
      );
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
        class="flex-grow m-0 overflow-hidden text-sm text-n-slate-12 whitespace-nowrap text-ellipsis"
      >
        {{ $t('CONTACT_PANEL.LABELS.LABEL_SELECT.TITLE') }}
      </h4>
      <Hotkey
        custom-class="border border-solid text-n-slate-12 bg-n-slate-2 text-xxs border-n-strong flex-shrink-0"
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
      <div class="w-full my-1">
        <template v-if="shouldShowSuggestions">
          <div
            class="flex items-center gap-1.5 px-2.5 pt-1 pb-2 text-xs font-medium leading-4 tracking-[0.2px] text-n-slate-10"
          >
            <Icon icon="i-lucide-sparkles" class="size-3 text-n-iris-10" />
            {{ $t('CONTACT_PANEL.LABELS.LABEL_SELECT.SUGGESTED') }}
          </div>
          <woot-dropdown-menu>
            <LabelDropdownItem
              v-for="label in suggestedLabels"
              :key="label.title"
              :title="label.title"
              :color="label.color"
              @select-label="onAdd(label)"
            />
          </woot-dropdown-menu>
          <div class="mx-2.5 mt-1 mb-2 border-t border-solid border-n-weak" />
        </template>
        <woot-dropdown-menu>
          <LabelDropdownItem
            v-for="label in listedLabels"
            :key="label.title"
            :title="label.title"
            :color="label.color"
            :selected="selectedLabels.includes(label.title)"
            @select-label="onAddRemove(label)"
          />
        </woot-dropdown-menu>
        <div
          v-if="noResult"
          class="flex justify-center py-4 px-2.5 font-medium text-xs text-n-slate-11"
        >
          {{ $t('CONTACT_PANEL.LABELS.LABEL_SELECT.NO_RESULT') }}
        </div>
        <div
          v-if="allowCreation && shouldShowCreate"
          class="flex pt-1 border-t border-solid border-n-weak"
        >
          <NextButton
            icon="i-lucide-plus"
            slate
            sm
            ghost
            :label="`${createLabelPlaceholder} ${parsedSearch}`"
            :disabled="hasExactMatchInResults"
            @click="showCreateModal"
          />

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
