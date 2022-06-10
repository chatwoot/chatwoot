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
        ></path>
      </svg>
    </div>
    <div class="header flex-between">
      <span>{{ $t('BULK_ACTION.UPDATE.UPDATE_CONVERSATIONS_LABEL') }}</span>
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
              {{ action.label }}
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
          label: 'Resolve Conversations',
          key: 'resolve',
        },
        {
          icon: 'arrow-redo',
          label: 'Reopen Conversations',
          key: 'open',
        },
        {
          icon: 'send-clock',
          label: 'Snooze until next reply',
          key: 'snooze',
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
        resolve: this.showResolve,
        open: this.showReopen,
        snooze: this.showSnooze,
      };
      return actionsMap[key] || false;
    },
  },
};
</script>

<style scoped lang="scss">
.flex-between {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.actions-container {
  transform-origin: top right;
  position: absolute;
  top: 48px;
  right: var(--space-small);
  width: 100%;
  box-shadow: var(--shadow-dropdown-pane);
  border-radius: var(--border-radius-large);
  border: 1px solid var(--s-50);
  background-color: var(--white);
  width: 50%;
  z-index: 20;
  .header {
    padding: var(--space-one);
    span {
      font-size: var(--font-size-default);
      font-weight: var(--font-weight-medium);
    }
  }
  .container {
    padding: var(--space-one);
    padding-top: var(--space-zero);
  }
  .triangle {
    display: block;
    line-height: 11px;
    z-index: 1;
    position: absolute;
    top: -12px;
    right: 28px;
    text-align: left;
  }
}
ul {
  margin: 0;
  list-style: none;
}
</style>
