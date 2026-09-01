<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { embeds } from 'dashboard/helper/markdownEmbeds';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  position: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const url = ref('');
const showError = ref(false);

const isSupported = value =>
  embeds.some(({ regex }) => regex.test(value.trim()));

const isValid = computed(() => isSupported(url.value));

const menuStyle = computed(() => {
  if (!props.position) return {};
  const style = { top: `${props.position.top}px` };
  if (props.position.right != null) {
    style.right = `${props.position.right}px`;
  } else {
    style.left = `${props.position.left}px`;
  }
  return style;
});

const onSubmit = () => {
  // Ignore submits on an empty field (e.g. the stray Enter keyup that carries
  // over from selecting "Video" in the slash menu).
  if (!url.value.trim()) return;
  if (!isValid.value) {
    showError.value = true;
    return;
  }
  emit('submit', url.value.trim());
};

const onInput = () => {
  showError.value = false;
};
</script>

<template>
  <div
    class="absolute z-50 flex flex-col p-3 shadow-lg gap-2.5 w-[22rem] bg-n-solid-2 outline outline-1 outline-n-weak rounded-xl"
    :style="menuStyle"
  >
    <Input
      v-model="url"
      type="url"
      autofocus
      custom-input-class="!ps-9"
      :placeholder="t('VIDEO_EMBED.PLACEHOLDER')"
      :message-type="showError ? 'error' : 'info'"
      @input="onInput"
      @enter="onSubmit"
      @keydown.esc.prevent="emit('cancel')"
    >
      <template #prefix>
        <Icon
          icon="i-lucide-video"
          class="absolute z-10 -translate-y-1/2 pointer-events-none start-3 top-5 size-4"
          :class="showError ? 'text-n-ruby-9' : 'text-n-slate-11'"
        />
      </template>
    </Input>
    <p
      class="px-1 text-xs leading-snug"
      :class="showError ? 'text-n-ruby-11' : 'text-n-slate-10'"
    >
      {{ showError ? t('VIDEO_EMBED.ERROR') : t('VIDEO_EMBED.HINT') }}
    </p>
    <div class="flex items-center justify-end gap-2">
      <Button
        ghost
        slate
        sm
        type="button"
        :label="t('VIDEO_EMBED.CANCEL')"
        @click="emit('cancel')"
      />
      <Button
        solid
        sm
        type="button"
        :label="t('VIDEO_EMBED.ADD')"
        :disabled="!isValid"
        @click="onSubmit"
      />
    </div>
  </div>
</template>
