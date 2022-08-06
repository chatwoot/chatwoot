<template>
  <div v-on-clickaway="onClose" class="actions-container">
    <div class="triangle">
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
      <span>{{ $t('BULK_ACTION.UPDATE.CHANGE_STATUS') }}</span>
      <woot-button
        size="tiny"
        variant="clear"
        color-scheme="secondary"
        icon="dismiss"
        @click="onClose"
      />
    </div>
    <div class="container">
      <woot-dropdown-menu>
        <template v-for="action in actions">
          <woot-dropdown-item v-if="showAction(action.key)" :key="action.key">
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="small"
              :icon="action.icon"
              @click="updateConversations(action.key)"
            >
              {{ actionLabel(action.key) }}
            </woot-button>
          </woot-dropdown-item>
        </template>
      </woot-dropdown-menu>
    </div>
  </div>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
export default {
  components: {
    WootDropdownItem,
    WootDropdownMenu,
  },
  mixins: [clickaway],
  props: {
    selectedInboxes: {
      type: Array,
      default: () => [],
    },
    conversationCount: {
      type: Number,
      default: 0,
    },
    showResolve: {
      type: Boolean,
      default: true,
    },
    showReopen: {
      type: Boolean,
      default: true,
    },
    showSnooze: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      query: '',
      selectedAction: null,
      actions: [
        {
          icon: 'checkmark',
          key: 'resolved',
        },
        {
          icon: 'arrow-redo',
          key: 'open',
        },
        {
          icon: 'send-clock',
          key: 'snoozed',
        },
      ],
    };
  },
  methods: {
    updateConversations(key) {
      this.$emit('update', key);
    },
    goBack() {
      this.selectedAgent = null;
    },
    onClose() {
      this.$emit('close');
    },
    showAction(key) {
      const actionsMap = {
        resolved: this.showResolve,
        open: this.showReopen,
        snoozed: this.showSnooze,
      };
      return actionsMap[key] || false;
    },
    actionLabel(key) {
      const labelsMap = {
        resolved: this.$t('CONVERSATION.HEADER.RESOLVE_ACTION'),
        open: this.$t('CONVERSATION.HEADER.REOPEN_ACTION'),
        snoozed: this.$t('BULK_ACTION.UPDATE.SNOOZE_UNTIL_NEXT_REPLY'),
      };
      return labelsMap[key] || '';
    },
  },
};
</script>

<style scoped lang="scss">
.actions-container {
  background-color: var(--white);
  border-radius: var(--border-radius-large);
  border: 1px solid var(--s-50);
  box-shadow: var(--shadow-dropdown-pane);
  position: absolute;
  right: var(--space-small);
  top: 48px;
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
    padding: var(--space-one);
    padding-top: var(--space-zero);
  }

  .triangle {
    display: block;
    position: absolute;
    right: 2.8rem;
    text-align: left;
    top: calc(var(--space-slab) * -1);
    z-index: var(--z-index-one);
  }
}

ul {
  margin: 0;
  list-style: none;
}
</style>
