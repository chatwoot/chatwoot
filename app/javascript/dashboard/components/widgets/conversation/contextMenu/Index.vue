<template>
  <div class="conversation-menu">
    <!-- // Status Menu  -->
    <template v-for="item in menuItems">
      <div
        v-if="show(item.key)"
        :key="item.key"
        class="menu-item flex-align-center"
        @click="$emit('update-conversation', item.key)"
      >
        <fluent-icon :icon="item.icon" size="14" class="icon" />
        <p>{{ item.label }}</p>
      </div>
    </template>
    <!-- // Status Menu  -->
    <!-- // Snooze Menu  -->
    <div class="menu-item has-submenu">
      <div class="flex-align-center">
        <fluent-icon icon="snooze" size="14" class="icon" />
        <p>{{ $t('CONVERSATION.CARD_CONTEXT_MENU.SNOOZE.TITLE') }}</p>
      </div>
      <fluent-icon icon="chevron-right" size="12" />
      <div class="conversation-submenu">
        <div class="menu-item" @click="$emit('update-conversation', 'snooze')">
          <p>
            {{ this.$t('CONVERSATION.CARD_CONTEXT_MENU.SNOOZE.NEXT_REPLY') }}
          </p>
        </div>
        <div
          class="menu-item"
          @click="$emit('update-conversation', 'snooze-until-tomorrow')"
        >
          <p>{{ this.$t('CONVERSATION.CARD_CONTEXT_MENU.SNOOZE.TOMORROW') }}</p>
        </div>
        <div
          class="menu-item"
          @click="$emit('update-conversation', 'snooze_until_next_week')"
        >
          <p>
            {{ this.$t('CONVERSATION.CARD_CONTEXT_MENU.SNOOZE.NEXT_WEEK') }}
          </p>
        </div>
      </div>
    </div>
    <!-- // Snooze Menu  -->
    <!-- // Agent Menu  -->
    <div class="menu-item has-submenu">
      <div class="flex-align-center">
        <fluent-icon icon="person-add" size="14" class="icon" />
        <p>{{ this.$t('CONVERSATION.CARD_CONTEXT_MENU.ASSIGN_AGENT') }}</p>
      </div>
      <fluent-icon icon="chevron-right" size="12" />
      <div class="conversation-submenu">
        <div
          v-for="agent in agents"
          :key="agent.id"
          class="menu-item"
          @click="$emit('assign-agent', agent)"
        >
          <div class="flex-align-center">
            <thumbnail
              :username="agent.name"
              :src="agent.thumbnail"
              size="20px"
              class="agent-thumbnail"
            />
            <p>{{ agent.name }}</p>
          </div>
        </div>
      </div>
    </div>
    <!-- // Agent Menu  -->
    <!-- // Label Menu  -->
    <div class="menu-item has-submenu">
      <div class="flex-align-center">
        <fluent-icon icon="tag" size="14" class="icon" />
        <p>{{ this.$t('CONVERSATION.CARD_CONTEXT_MENU.ASSIGN_LABEL') }}</p>
      </div>
      <fluent-icon icon="chevron-right" size="12" />
      <div class="conversation-submenu">
        <div v-for="label in labels" :key="label.id" class="menu-item">
          <div class="flex-align-center" @click="$emit('assign-label', label)">
            <span
              class="label-pill"
              :style="{ backgroundColor: label.color }"
            />
            <p>{{ label.title }}</p>
          </div>
        </div>
      </div>
    </div>
    <!-- // Label Menu  -->
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import { mapGetters } from 'vuex';

export default {
  components: {
    Thumbnail,
  },
  props: {
    showPending: {
      type: Boolean,
      default: false,
    },
    showResolved: {
      type: Boolean,
      default: false,
    },
    showReopen: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      menuItems: [
        {
          key: 'resolved',
          label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.RESOLVED'),
          icon: 'checkmark',
        },
        {
          key: 'pending',
          label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.PENDING'),
          icon: 'book-clock',
        },
        {
          key: 'open',
          label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.REOPEN'),
          icon: 'arrow-redo',
        },
      ],
    };
  },
  computed: {
    ...mapGetters({
      agents: 'agents/getAgents',
      labels: 'labels/getLabels',
    }),
  },
  mounted() {
    this.$store.dispatch('agents/get');
    this.$store.dispatch('labels/get');
  },
  methods: {
    show(key) {
      const options = {
        resolved: this.showResolved,
        open: this.showReopen,
        pending: this.showPending,
      };
      return options[key] || false;
    },
  },
};
</script>

<style lang="scss" scoped>
.flex-align-center {
  display: flex;
  align-items: center;
}

.conversation-menu {
  min-width: calc(var(--space-mega) * 2);
  position: relative;
  border-radius: var(--border-radius-medium);
  padding: var(--space-half);
  p {
    margin: 0;
    font-size: var(--font-size-mini);
  }
}

.menu-item {
  padding: var(--space-half);
  border-radius: var(--border-radius-small);

  .icon {
    margin-right: var(--space-small);
  }

  &:hover:not(.has-submenu) {
    background-color: var(--w-500);
    color: var(--white);
  }

  &.has-submenu {
    display: flex;
    align-items: center;
    justify-content: space-between;
    position: relative;

    &:hover {
      background-color: var(--w-50);
      .conversation-submenu {
        display: block;
      }
      // Handles the submenu diagonal issue.
      &:before {
        content: '';
        position: absolute;
        z-index: var(--z-index-highest);
        bottom: -65%;
        height: 75%;
        right: 0%;
        width: 50%;
        clip-path: polygon(100% 0, 0% 0%, 100% 100%);
      }
    }

    .conversation-submenu {
      border: 1px solid var(--s-25);
      min-width: calc(var(--space-mega) * 2);
      border-radius: var(--border-radius-medium);
      padding: var(--space-half);
      background-color: var(--white);
      position: absolute;
      left: 100%;
      top: 0;
      box-shadow: var(--shadow-context-menu);
      display: none;
    }
  }
}

.agent-thumbnail {
  margin-top: 0 !important;
  margin-right: var(--space-one);
}

.label-pill {
  width: var(--space-normal);
  height: var(--space-normal);
  border-radius: var(--border-radius-rounded);
  border: 1px solid var(--s-50);
  flex-shrink: 0;
  margin-right: var(--space-one);
}
</style>
