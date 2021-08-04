<template>
  <transition name="slide-up">
    <div class="modal-mask">
      <div class="page-top-bar modal-container">
        <div class="title-wrap">
          <div class="title">
            <h2 class="page-title">
              {{ $t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS') }}
            </h2>
            <div class="shortcut-key__wrap">
              <span class="shortcut-key">
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.COMMAND_KEY') }}
              </span>
              <span class="shortcut-key key">
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.FORWARD_SLASH_KEY') }}
              </span>
            </div>
          </div>
          <i class="ion-android-close modal--close" @click="$emit('close')"></i>
        </div>

        <div class="shortcut__wrap">
          <div class="title-key__wrap">
            <h6 class="sub-block-title">
              {{ $t('KEYBOARD_SHORTCUTS.TITLE.OPEN_CONVERSATION') }}
            </h6>
            <div class="shortcut-key__wrap">
              <div class="open-conversation__key">
                <span class="shortcut-key">
                  {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
                </span>
                <span class="shortcut-key key">
                  {{ $t('KEYBOARD_SHORTCUTS.LETTER.J') }}
                </span>
              </div>
              <span class="shortcut-key">
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
              </span>
              <span class="shortcut-key key">
                {{ $t('KEYBOARD_SHORTCUTS.LETTER.K') }}
              </span>
            </div>
          </div>

          <div class="title-key__wrap">
            <h6 class="sub-block-title">
              {{ $t('KEYBOARD_SHORTCUTS.TITLE.RESOLVE_AND_NEXT') }}
            </h6>
            <div class="shortcut-key__wrap">
              <span class="shortcut-key">
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.COMMAND_KEY') }}
              </span>
              <span class="shortcut-key">
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
              </span>
              <span class="shortcut-key key">
                {{ $t('KEYBOARD_SHORTCUTS.LETTER.E') }}
              </span>
            </div>
          </div>
          <div
            v-for="shortcutKey in shortcutKeys"
            :key="shortcutKey.id"
            class="title-key__wrap"
          >
            <h6 class="sub-block-title">
              {{ title(shortcutKey) }}
            </h6>
            <div class="shortcut-key__wrap">
              <span class="shortcut-key">
                {{ shortcutKey.key }}
              </span>
              <span class="shortcut-key key">
                {{ shortcutKey.shortcutKey }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script>
const SHORTCUT_KEYS = [
  {
    id: 1,
    title: 'Navigate dropdown items',
    key: 'Up',
    shortcutKey: 'Down',
    label: 'NAVIGATE_DROPDOWN',
  },
  {
    id: 2,
    title: 'Resolve Conversation',
    key: 'Alt / ⌥',
    shortcutKey: 'E',
    label: 'RESOLVE_AND_NEXT',
  },
  {
    id: 3,
    title: 'Go to Conversation Dashboard',
    key: 'Alt / ⌥',
    shortcutKey: 'C',
    label: 'GO_TO_CONVERSATION_DASHBOARD',
  },
  {
    id: 4,
    title: 'Add Attachment',
    key: 'Alt / ⌥',
    shortcutKey: 'A',
    label: 'ADD_ATTACHMENT',
  },
  {
    id: 5,
    title: 'Go to Contacts Dashboard',
    key: 'Alt / ⌥',
    shortcutKey: 'V',
    label: 'GO_TO_CONTACTS_DASHBOARD',
  },
  {
    id: 6,
    title: 'Toggle Sidebar',
    key: 'Alt / ⌥',
    shortcutKey: 'O',
  },
  {
    id: 7,
    title: 'Go to Reports sidebar',
    key: 'Alt / ⌥',
    shortcutKey: 'R',
  },
  {
    id: 8,
    title: 'Move to next tab in conversation list',
    key: 'Alt / ⌥',
    shortcutKey: 'N',
  },
  {
    id: 9,
    title: 'Go to Settings',
    key: 'Alt / ⌥',
    shortcutKey: 'S',
  },
  {
    id: 10,
    title: 'Switch Conversation status',
    key: 'Alt / ⌥',
    shortcutKey: 'B',
  },
  {
    id: 11,
    title: 'Switch to Private Note',
    key: 'Alt / ⌥',
    shortcutKey: 'P',
  },
  {
    id: 12,
    title: 'Toggle Rich Content editor',
    key: 'Alt / ⌥',
    shortcutKey: 'W',
  },
  {
    id: 13,
    title: 'Switch to Reply',
    key: 'Alt / ⌥',
    shortcutKey: 'L',
  },
  {
    id: 14,
    title: 'Toggle snooze dropdown',
    key: 'Alt / ⌥',
    shortcutKey: 'M',
  },
];
export default {
  data() {
    return {
      shortcutKeys: SHORTCUT_KEYS,
    };
  },
  methods: {
    title(item) {
      return this.$t(`KEYBOARD_SHORTCUTS.${item.label}`) || item.title;
    },
  },
};
</script>

<style lang="scss" scoped>
.modal-container {
  width: fit-content;
}

.page-top-bar {
  padding: var(--space-medium) var(--space-large) var(--space-large)
    var(--space-large);
}

.title-wrap {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.title {
  display: flex;
}

.page-title {
  display: flex;
  font-size: var(--font-size-big);
  font-weight: var(--font-weight-bold);
}

.shortcut-key__wrap {
  display: flex;
  align-items: center;
  margin-bottom: var(--space-smaller);
  margin-left: var(--space-small);
}

.shortcut__wrap {
  display: grid;
  grid-template-columns: repeat(2, 0.5fr);
  gap: 0.4rem 4rem;
  margin-top: var(--space-two);
}

.title-key__wrap {
  display: flex;
  justify-content: space-between;
  align-items: center;
  min-width: 40rem;
}

.shortcut-key {
  background: var(--color-background);
  padding: var(--space-small) var(--space-one);
  font-weight: var(--font-weight-bold);
  font-size: var(--font-size-mini);
  align-items: center;
  border-radius: var(--border-radius-normal);
  margin-right: var(--space-small);
}

.key {
  display: flex;
  justify-content: center;
  min-width: var(--space-large);
  margin-right: 0;
}

.open-conversation__key {
  display: flex;
  margin-right: var(--space-small);
}
</style>
