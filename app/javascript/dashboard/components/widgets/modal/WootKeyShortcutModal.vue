<template>
  <woot-modal :show="show" size="medium" :on-close="() => $emit('close')">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS')"
      />
      <div class="shortcut__wrap margin-top-3">
        <div class="title-key__wrap">
          <h5 class="text-block-title">
            {{ $t('KEYBOARD_SHORTCUTS.TOGGLE_MODAL') }}
          </h5>
          <div class="shortcut-key__wrap">
            <p class="shortcut-key">
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.WINDOWS_KEY_AND_COMMAND_KEY') }}
            </p>
            <p class="shortcut-key key">
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.FORWARD_SLASH_KEY') }}
            </p>
          </div>
        </div>
      </div>

      <div class="shortcut__wrap">
        <div class="title-key__wrap">
          <h5 class="text-block-title">
            {{ $t('KEYBOARD_SHORTCUTS.TITLE.OPEN_CONVERSATION') }}
          </h5>
          <div class="shortcut-key__wrap">
            <div class="open-conversation__key">
              <span class="shortcut-key">
                {{ $t('KEYBOARD_SHORTCUTS.KEYS.ALT_OR_OPTION_KEY') }}
              </span>
              <span class="shortcut-key">
                J
              </span>
              <span class="forward-slash text-block-title">
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
          <h5 class="text-block-title">
            {{ $t('KEYBOARD_SHORTCUTS.TITLE.RESOLVE_AND_NEXT') }}
          </h5>
          <div class="shortcut-key__wrap">
            <span class="shortcut-key">
              {{ $t('KEYBOARD_SHORTCUTS.KEYS.WINDOWS_KEY_AND_COMMAND_KEY') }}
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
          <h5 class="text-block-title">
            {{ title(shortcutKey) }}
          </h5>
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
  </woot-modal>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { SHORTCUT_KEYS } from './constants';

export default {
  mixins: [clickaway],
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },
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
.title-shortcut-key__wrap {
  display: flex;
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
  padding: 0 var(--space-large) var(--space-large);
}

.title-key__wrap {
  display: flex;
  justify-content: space-between;
  align-items: center;
  min-width: 40rem;
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
