<template>
  <div v-on-clickaway="onClose" class="labels-container">
    <div class="triangle" :style="cssVars">
      <svg height="12" viewBox="0 0 24 12" width="24">
        <path
          d="M20 12l-8-8-12 12"
          fill="var(--white)"
          fill-rule="evenodd"
          stroke="var(--s-50)"
          stroke-width="1px"
        />
      </svg>
    </div>
    <div class="header flex-between">
      <span>{{ $t('BULK_ACTION.LABELS.ASSIGN_LABELS') }}</span>
      <woot-button
        size="tiny"
        variant="clear"
        color-scheme="secondary"
        icon="dismiss"
        @click="onClose"
      />
    </div>
    <div class="labels-list">
      <header class="labels-list__header">
        <div class="label-list-search flex-between">
          <fluent-icon icon="search" class="search-icon" size="16" />
          <input
            ref="search"
            v-model="query"
            type="search"
            placeholder="Search"
            class="label--search_input"
          />
        </div>
      </header>
      <ul class="labels-list__body">
        <li
          v-for="label in filteredLabels"
          :key="label.id"
          class="label__list-item"
        >
          <label
            class="item"
            :class="{ 'label-selected': isLabelSelected(label.title) }"
          >
            <input
              v-model="selectedLabels"
              type="checkbox"
              :value="label.title"
              class="label-checkbox"
            />
            <span class="label-title text-truncate">{{ label.title }}</span>
            <span
              class="label-pill"
              :style="{ backgroundColor: label.color }"
            />
          </label>
        </li>
      </ul>
      <footer class="labels-list__footer">
        <woot-button
          size="small"
          color-scheme="primary"
          :disabled="!selectedLabels.length"
          @click="$emit('assign', selectedLabels)"
        >
          <span>{{ $t('BULK_ACTION.LABELS.ASSIGN_SELECTED_LABELS') }}</span>
        </woot-button>
      </footer>
    </div>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { mapGetters } from 'vuex';
import bulkActionsMixin from 'dashboard/mixins/bulkActionsMixin.js';

export default {
  mixins: [clickaway, bulkActionsMixin],
  data() {
    return {
      query: '',
      selectedLabels: [],
    };
  },
  computed: {
    ...mapGetters({ labels: 'labels/getLabels' }),
    filteredLabels() {
      return this.labels.filter(label =>
        label.title.toLowerCase().includes(this.query.toLowerCase())
      );
    },
  },
  methods: {
    isLabelSelected(label) {
      return this.selectedLabels.includes(label);
    },
    assignLabels(key) {
      this.$emit('update', key);
    },
    onClose() {
      this.$emit('close');
    },
  },
};
</script>

<style scoped lang="scss">
.labels-list {
  display: flex;
  flex-direction: column;
  max-height: var(--space-giga);
  min-height: auto;

  .labels-list__header {
    background-color: var(--white);
    padding: 0 var(--space-one);
  }

  .labels-list__body {
    flex: 1;
    overflow-y: auto;
    padding: var(--space-one) 0;
  }

  .labels-list__footer {
    padding: var(--space-small);

    button {
      width: 100%;
    }
  }
}

.label-list-search {
  background-color: var(--s-50);
  border-radius: var(--border-radius-medium);
  border: 1px solid var(--s-100);
  padding: 0 var(--space-one);

  .search-icon {
    color: var(--s-400);
  }

  .label--search_input {
    background-color: transparent;
    border: 0;
    font-size: var(--font-size-mini);
    height: unset;
    margin: 0;
  }
}

.labels-container {
  background-color: var(--white);
  border-radius: var(--border-radius-large);
  border: 1px solid var(--s-50);
  box-shadow: var(--shadow-dropdown-pane);
  max-width: var(--space-giga);
  min-width: var(--space-giga);
  position: absolute;
  right: var(--space-small);
  top: var(--space-larger);
  transform-origin: top right;
  width: auto;
  z-index: var(--z-index-twenty);

  .header {
    padding: var(--space-one);

    span {
      font-size: var(--font-size-small);
      font-weight: var(--font-weight-medium);
    }
  }

  .container {
    max-height: var(--space-giga);
    overflow-y: auto;

    .label__list-container {
      height: 100%;
    }
    .label-list-search {
      padding: 0 var(--space-one);
      border: 1px solid var(--s-100);
      border-radius: var(--border-radius-medium);
      background-color: var(--s-50);
      .search-icon {
        color: var(--s-400);
      }

      .label--search_input {
        border: 0;
        font-size: var(--font-size-mini);
        margin: 0;
        background-color: transparent;
        height: unset;
      }
    }
  }

  .triangle {
    display: block;
    position: absolute;
    right: var(--triangle-position);
    text-align: left;
    top: calc(var(--space-slab) * -1);
    z-index: var(--z-index-one);
  }
}

ul {
  margin: 0;
  list-style: none;
}

.labels-placeholder {
  padding: var(--space-small);
}

.label__list-item {
  margin: var(--space-smaller) 0;
  padding: 0 var(--space-one);

  .item {
    align-items: center;
    border-radius: var(--border-radius-medium);
    cursor: pointer;
    display: flex;
    padding: var(--space-smaller) var(--space-one);

    &:hover {
      background-color: var(--s-50);
    }

    &.label-selected {
      background-color: var(--s-50);
    }

    span {
      font-size: var(--font-size-small);
    }

    .label-checkbox {
      margin: 0 var(--space-one) 0 0;
    }

    .label-title {
      flex-grow: 1;
      width: 100%;
    }

    .label-pill {
      background-color: var(--s-50);
      border-radius: var(--border-radius-medium);
      height: var(--space-slab);
      width: var(--space-slab);
      flex-shrink: 0;
      border: 1px solid var(--color-border-light);
    }
  }
}

.search-container {
  background-color: var(--white);
  padding: 0 var(--space-one);
  position: sticky;
  top: 0;
  z-index: var(--z-index-twenty);
}

.actions-container {
  background-color: var(--white);
  bottom: 0;
  padding: var(--space-small);
  position: sticky;
  z-index: var(--z-index-twenty);

  button {
    width: 100%;
  }
}
</style>
