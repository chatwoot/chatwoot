<script setup>
import { defineAsyncComponent, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';
import Button from 'dashboard/components-next/button/Button.vue';
import EmojiIcon from 'dashboard/components-next/emoji-icon-picker/EmojiIcon.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const EmojiIconPicker = defineAsyncComponent(
  () =>
    import('dashboard/components-next/emoji-icon-picker/EmojiIconPicker.vue')
);

const icon = defineModel('icon', { type: String, required: true });
const color = defineModel('color', { type: String, required: true });

const { t } = useI18n();
const isOpen = ref(false);

const select = selected => {
  icon.value = selected.value;
  color.value = selected.color;
  isOpen.value = false;
};
</script>

<template>
  <div class="absolute bottom-0 start-0">
    <OnClickOutside @trigger="isOpen = false">
      <Button
        v-tooltip.top="t('MONITORS.CHOOSE_ICON')"
        type="button"
        variant="ghost"
        color="slate"
        :aria-label="t('MONITORS.CHOOSE_ICON')"
        :aria-expanded="isOpen"
        class="!size-10 !p-0 ltr:!rounded-r-none rtl:!rounded-l-none"
        @click="isOpen = !isOpen"
      >
        <EmojiIcon
          v-if="icon"
          :value="icon"
          :color="color"
          class="size-5 text-xl !leading-5"
        />
        <Icon v-else icon="i-lucide-monitor" class="size-4" />
      </Button>
      <EmojiIconPicker
        v-if="isOpen"
        mode="icon"
        class="start-0 top-full mt-1"
        :value="icon"
        :color="color"
        @select="select"
        @color-change="value => (color = value)"
      />
    </OnClickOutside>
  </div>
</template>
