<template>
  <transition name="slide-up">
    <div class="modal-mask">
      <div v-on-clickaway="() => $emit('clickaway')" class="modal-container">
        <div class="header-wrap">
          <div class="title-shortcut-key__wrap">
            <h2 class="page-title">
              {{ $t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS') }}
            </h2>
            <div class="shortcut-key__wrap">
              <p class="shortcut-key">
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.COMMAND_KEY') }}
              </p>
              <p class="shortcut-key key">
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.FORWARD_SLASH_KEY') }}
              </p>
            </div>
          </div>
          <i class="ion-android-close modal--close" @click="$emit('close')"></i>
        </div>

        <div class="shortcut__wrap">
          <div class="title-key__wrap">
            <span class="sub-block-title">
              {{ $t('KEYBOARD_SHORTCUTS.TITLE.OPEN_CONVERSATION') }}
            </span>
            <div class="shortcut-key__wrap">
              <div class="open-conversation__key">
                <span class="shortcut-key">
                  {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
                </span>
                <span class="shortcut-key">
                  J
                </span>
                <span class="forward-slash sub-block-title">
                  {{ $t('KEYBOARD_SHORTCUTS.KEYS.FORWARD_SLASH_KEY') }}
                </span>
              </div>
              <span class="shortcut-key">
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
              </span>
              <span class="shortcut-key key">
                K
              </span>
            </div>
          </div>

          <div class="title-key__wrap">
            <span class="sub-block-title">
              {{ $t('KEYBOARD_SHORTCUTS.TITLE.RESOLVE_AND_NEXT') }}
            </span>
            <div class="shortcut-key__wrap">
              <span class="shortcut-key">
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.COMMAND_KEY') }}
              </span>
              <span class="shortcut-key">
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
              </span>
              <span class="shortcut-key key">
                E
              </span>
            </div>
          </div>
          <div
            v-for="shortcutKey in shortcutKeys"
            :key="shortcutKey.id"
            class="title-key__wrap"
          >
            <span class="sub-block-title">
              {{ title(shortcutKey) }}
            </span>
            <div class="shortcut-key__wrap">
              <span class="shortcut-key">
                {{ shortcutKey.firstkey }}
              </span>
              <span class="shortcut-key key">
                {{ shortcutKey.secondKey }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { SHORTCUT_KEYS } from './constants';

export default {
  mixins: [clickaway],
  data() {
    return {
      shortcutKeys: SHORTCUT_KEYS,
    };
  },
  methods: {
    title(item) {
      return this.$t(`KEYBOARD_SHORTCUTS.TITLE.${item.label}`);
    },
  },
};
</script>

<style lang="scss" scoped>
.modal-container {
  padding: var(--space-medium) var(--space-large) var(--space-large)
    var(--space-large);
  width: fit-content;
}

.header-wrap {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.title-shortcut-key__wrap {
  display: flex;
  margin-bottom: var(--space-small);
}

.page-title {
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
  gap: var(--space-smaller) var(--space-large);
  margin-top: var(--space-small);
}

.title-key__wrap {
  display: flex;
  justify-content: space-between;
  align-items: center;
  min-width: 40rem;
}

.sub-block-title {
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
}

.forward-slash {
  display: flex;
  align-items: center;
  font-weight: var(--font-weight-bold);
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
