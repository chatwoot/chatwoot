<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { Virtualizer } from 'virtua/vue';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ColorPalette from './ColorPalette.vue';
import { CURATED_ICONS } from './icons';
import {
  DEFAULT_ICON_COLOR,
  ICON_STYLE,
  PICKER_MODE,
  PICKER_TAB,
  isIconValue,
} from './constants';
import {
  buildEmojiSections,
  getEmojiTint,
  getRecentEmojis,
  addRecentEmoji,
} from 'shared/components/emoji/pickerHelper';

const props = defineProps({
  // 'both' shows Icons + Emojis tabs; 'emoji' shows only the emoji panel.
  mode: {
    type: String,
    default: PICKER_MODE.BOTH,
    validator: value => Object.values(PICKER_MODE).includes(value),
  },
  // Saved value: an emoji char or an icon name (e.g. "rocket-line").
  value: {
    type: String,
    default: '',
  },
  // Current stored icon color (hex), used to preselect a swatch.
  color: {
    type: String,
    default: '',
  },
  showRemoveButton: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select', 'remove', 'colorChange']);

const { t } = useI18n();

const showTabs = computed(() => props.mode === PICKER_MODE.BOTH);
const showHeader = computed(
  () => showTabs.value || (props.showRemoveButton && props.value)
);

const activeTab = ref(
  props.value && !isIconValue(props.value)
    ? PICKER_TAB.EMOJIS
    : PICKER_TAB.ICONS
);

const tabs = computed(() => [
  {
    id: PICKER_TAB.ICONS,
    label: t('EMOJI_ICON_PICKER.TABS.ICONS'),
    icon: 'i-lucide-shapes',
  },
  {
    id: PICKER_TAB.EMOJIS,
    label: t('EMOJI_ICON_PICKER.TABS.EMOJIS'),
    icon: 'i-lucide-smile',
  },
]);

// Icons
const iconSearch = ref('');
const selectedColor = ref(props.color || DEFAULT_ICON_COLOR);
// Preselect the outline/filled toggle from the saved icon's style suffix.
const iconStyle = ref(
  props.value.endsWith(`-${ICON_STYLE.FILL}`)
    ? ICON_STYLE.FILL
    : ICON_STYLE.LINE
);

const filteredIcons = computed(() => {
  const term = iconSearch.value.trim().toLowerCase();
  if (!term) return CURATED_ICONS;
  return CURATED_ICONS.filter(
    icon => icon.name.includes(term) || icon.keywords.includes(term)
  );
});

const toggleIconStyle = () => {
  iconStyle.value =
    iconStyle.value === ICON_STYLE.LINE ? ICON_STYLE.FILL : ICON_STYLE.LINE;
};

// Each icon button tints its hover with the selected color (low opacity).
const iconHoverStyle = computed(() => ({
  '--ep-tint': `${selectedColor.value}24`,
}));

const selectIcon = icon => {
  // Store the name with its style suffix, e.g. "rocket-fill".
  const value = `${icon.name}-${iconStyle.value}`;
  emit('select', {
    type: 'icon',
    value,
    icon: value,
    color: selectedColor.value,
  });
};

watch(selectedColor, color => {
  if (isIconValue(props.value)) emit('colorChange', color);
});

// Emojis
const emojiSearch = ref('');
const recentEmojis = ref([]);

onMounted(() => {
  recentEmojis.value = getRecentEmojis();
});

const emojiSections = computed(() =>
  buildEmojiSections(
    emojiSearch.value,
    recentEmojis.value,
    t('EMOJI_ICON_PICKER.FREQUENTLY_USED')
  )
);

// Tints an emoji button with a light shade of the emoji's own color on hover.
const applyEmojiTint = (event, emoji) => {
  event.currentTarget.style.setProperty('--ep-tint', getEmojiTint(emoji));
};

const selectEmoji = emoji => {
  recentEmojis.value = addRecentEmoji(emoji);
  emit('select', { type: 'emoji', value: emoji.emoji, emoji: emoji.emoji });
};
</script>

<template>
  <div
    role="dialog"
    class="absolute z-20 flex flex-col overflow-hidden shadow-xl w-[22rem] bg-n-surface-2 backdrop-blur-[100px] rounded-2xl outline outline-1 outline-n-weak dark:outline-n-strong/50"
  >
    <div v-if="showHeader" class="flex items-center justify-between gap-2 p-2">
      <div v-if="showTabs" class="flex gap-0.5 p-0.5 rounded-lg bg-n-alpha-1">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          v-tooltip.top="tab.label"
          type="button"
          class="flex items-center justify-center !p-0 transition-all rounded-md size-7 active:scale-[0.92]"
          :class="
            activeTab === tab.id
              ? 'bg-n-surface-1 shadow-sm text-n-slate-12'
              : 'text-n-slate-10 hover:text-n-slate-12'
          "
          @click="activeTab = tab.id"
        >
          <span :class="tab.icon" class="size-4" />
        </button>
      </div>
      <Button
        v-if="showRemoveButton && value"
        v-tooltip.top="t('EMOJI_ICON_PICKER.REMOVE')"
        type="button"
        variant="ghost"
        color="slate"
        size="sm"
        icon="i-lucide-eraser"
        class="flex-shrink-0"
        @click="emit('remove')"
      />
    </div>

    <!-- Icons panel -->
    <div
      v-if="showTabs && activeTab === PICKER_TAB.ICONS"
      class="flex flex-col gap-1.5"
      :style="iconHoverStyle"
    >
      <ColorPalette v-model="selectedColor" />
      <div class="flex items-center gap-1 px-2">
        <Input
          v-model="iconSearch"
          size="md"
          class="flex-1"
          :placeholder="t('EMOJI_ICON_PICKER.SEARCH_ICON')"
          custom-input-class="!ps-9 !bg-transparent"
          autofocus
        >
          <template #prefix>
            <span
              class="absolute z-10 -translate-y-1/2 i-lucide-search size-4 text-n-slate-10 top-1/2 start-3"
            />
          </template>
        </Input>
        <button
          v-tooltip.top="
            iconStyle === ICON_STYLE.FILL
              ? t('EMOJI_ICON_PICKER.STYLE.FILLED')
              : t('EMOJI_ICON_PICKER.STYLE.OUTLINE')
          "
          type="button"
          class="flex items-center justify-center flex-shrink-0 transition-all rounded-lg !p-2 size-9 text-n-slate-11 hover:bg-[var(--ep-tint)] active:scale-[0.92]"
          @click="toggleIconStyle"
        >
          <span
            :class="
              iconStyle === ICON_STYLE.FILL
                ? 'i-ri-contrast-2-fill'
                : 'i-ri-contrast-2-line'
            "
            class="size-[1.2rem]"
            :style="{ color: selectedColor }"
          />
        </button>
      </div>
      <div
        v-if="filteredIcons.length"
        class="grid grid-cols-10 h-52 gap-0.5 overflow-y-auto no-scrollbar content-start px-2 pb-2"
      >
        <button
          v-for="icon in filteredIcons"
          :key="icon.name"
          type="button"
          :title="icon.name"
          class="flex items-center justify-center !p-0 size-8 transition-colors rounded-lg aspect-square hover:bg-[var(--ep-tint)] active:enabled:scale-[0.97]"
          @click="selectIcon(icon)"
        >
          <span
            :class="icon[iconStyle]"
            class="size-[1.125rem]"
            :style="{ color: selectedColor }"
          />
        </button>
      </div>
      <div
        v-else
        class="flex flex-col items-center justify-center gap-2 h-52 text-n-slate-10"
      >
        <span class="i-lucide-search-x size-7" />
        <span class="text-sm font-medium">
          {{ t('EMOJI_ICON_PICKER.NO_ICON') }}
        </span>
      </div>
    </div>

    <!-- Emojis panel -->
    <div
      v-if="!showTabs || activeTab === PICKER_TAB.EMOJIS"
      class="flex flex-col gap-1.5"
      :class="{ 'pt-2': !showHeader }"
    >
      <div class="px-2">
        <Input
          v-model="emojiSearch"
          size="md"
          :placeholder="t('EMOJI_ICON_PICKER.SEARCH_EMOJI')"
          custom-input-class="!ps-9 !bg-transparent"
          autofocus
        >
          <template #prefix>
            <span
              class="absolute z-10 -translate-y-1/2 i-lucide-search size-4 text-n-slate-10 top-1/2 start-3"
            />
          </template>
        </Input>
      </div>
      <div
        v-if="emojiSections.length"
        class="h-60 overflow-y-auto px-2 no-scrollbar pb-2"
      >
        <Virtualizer v-slot="{ item: section }" :data="emojiSections">
          <h5
            class="px-1 pt-2 pb-1 m-0 text-xs font-medium tracking-wide uppercase text-n-slate-10"
          >
            {{ section.name }}
          </h5>
          <div class="grid grid-cols-10 gap-0.5">
            <button
              v-for="emoji in section.emojis"
              :key="`${section.name}-${emoji.slug}`"
              type="button"
              :title="emoji.name"
              class="flex items-center justify-center !p-0 size-8 w-full max-w-[2rem] text-xl transition-colors rounded-lg aspect-square hover:bg-[var(--ep-tint)] active:enabled:scale-[0.97]"
              @mouseenter="applyEmojiTint($event, emoji.emoji)"
              @click="selectEmoji(emoji)"
            >
              {{ emoji.emoji }}
            </button>
          </div>
        </Virtualizer>
      </div>
      <div
        v-else
        class="flex flex-col items-center justify-center gap-2 h-60 text-n-slate-10"
      >
        <span class="i-lucide-smile-plus size-7" />
        <span class="text-sm font-medium">
          {{ t('EMOJI_ICON_PICKER.NO_EMOJI') }}
        </span>
      </div>
    </div>
  </div>
</template>
