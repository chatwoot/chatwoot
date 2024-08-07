<template>
  <div class="label-selector-container">
    <div class="flex items-center justify-between mb-2">
      <h4 class="text-sm text-slate-800 dark:text-slate-100">
        {{ $t('CONTACT_PANEL.LABELS.LABEL_SELECT.TITLE') }}
      </h4>
      <hotkey
        custom-class="text-slate-800 dark:text-slate-100 bg-slate-50 dark:bg-slate-600 text-xxs border border-solid border-slate-75 dark:border-slate-600"
      >
        L
      </hotkey>
    </div>
    <input
      ref="searchbar"
      v-model="search"
      type="text"
      class="search-input"
      :placeholder="$t('CONTACT_PANEL.LABELS.LABEL_SELECT.PLACEHOLDER')"
    />
    <div class="label-list">
      <label-dropdown-item
        v-for="label in filteredActiveLabels"
        :key="label.title"
        :title="label.title"
        :color="label.color"
        :selected="selectedLabels.includes(label)"
        @click="onAddRemove(label)"
      />
    </div>
    <div v-if="noResult" class="no-result">
      {{ $t('CONTACT_PANEL.LABELS.LABEL_SELECT.NO_RESULT') }}
    </div>
  </div>
</template>
<script>
import LabelDropdownItem from './LabelDropdownItem.vue';
import Hotkey from 'dashboard/components/base/Hotkey.vue';
import { picoSearch } from '@scmmishra/pico-search';

export default {
  components: {
    LabelDropdownItem,
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
  },
  data() {
    return {
      search: '',
    };
  },
  computed: {
    filteredActiveLabels() {
      if (!this.search) return this.accountLabels;
      return picoSearch(this.accountLabels, this.search, ['title'], {
        threshold: 0.9,
      });
    },
    noResult() {
      return this.filteredActiveLabels.length === 0;
    },
  },
  methods: {
    onAddRemove(label) {
      if (this.selectedLabels.includes(label)) {
        this.$emit('remove', label);
      } else {
        this.$emit('add', label);
      }
    },
  },
};
</script>
<style scoped>
.label-selector-container {
  display: flex;
  flex-direction: column;
  width: 100%;
}

.search-input {
  margin-bottom: 10px;
}

.label-list {
  max-height: 200px;
  overflow-y: auto;
}

.no-result {
  padding: 10px;
  text-align: center;
}
</style>
