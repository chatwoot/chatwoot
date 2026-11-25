<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { embeds } from 'dashboard/helper/markdownEmbeds';
import { DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE } from 'shared/helpers/FileHelper';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';

const props = defineProps({
  position: {
    type: Object,
    default: null,
  },
  maxUploadSize: {
    type: Number,
    default: DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE,
  },
});

const emit = defineEmits(['submit', 'upload', 'cancel']);

const { t } = useI18n();

const url = ref('');
const showError = ref(false);
const showUploadError = ref(false);
const fileInput = ref(null);

const tabs = computed(() => [
  { id: 'embed', label: t('VIDEO_EMBED.TAB_EMBED') },
  { id: 'upload', label: t('VIDEO_EMBED.TAB_UPLOAD') },
]);
const activeTabIndex = ref(0);
const mode = computed(() => tabs.value[activeTabIndex.value].id);

const onTabChange = tab => {
  activeTabIndex.value = tabs.value.findIndex(item => item.id === tab.id);
};

// Arrow keys swap tabs from anywhere in the popover except the link field,
// where they must keep moving the caret.
const moveTab = (event, step) => {
  if (event.target.tagName === 'INPUT') return;
  event.preventDefault();
  const count = tabs.value.length;
  activeTabIndex.value = (activeTabIndex.value + step + count) % count;
};

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

const openFilePicker = () => fileInput.value?.click();

const emitFile = file => {
  if (!file) return;
  // The accept attr doesn't constrain drag-and-drop; mirrors bucketFor in
  // FullEditor so a dropped image can't slip through as an image insert.
  showUploadError.value = file.type !== 'video/mp4';
  if (!showUploadError.value) emit('upload', file);
};

const onFileChange = event => {
  emitFile(event.target.files[0]);
  event.target.value = '';
};

const onDrop = event => emitFile(event.dataTransfer?.files[0]);
</script>

<template>
  <div
    class="absolute z-50 flex flex-col p-3 shadow-lg gap-2.5 w-[22rem] bg-n-solid-2 outline outline-1 outline-n-weak rounded-xl"
    :style="menuStyle"
    @keydown.esc.prevent="emit('cancel')"
    @keydown.left="moveTab($event, -1)"
    @keydown.right="moveTab($event, 1)"
  >
    <TabBar
      :tabs="tabs"
      :initial-active-tab="activeTabIndex"
      @tab-changed="onTabChange"
    />
    <template v-if="mode === 'embed'">
      <Input
        v-model="url"
        type="url"
        autofocus
        custom-input-class="!ps-9"
        :placeholder="t('VIDEO_EMBED.PLACEHOLDER')"
        :message-type="showError ? 'error' : 'info'"
        @input="onInput"
        @enter="onSubmit"
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
    </template>
    <template v-else>
      <button
        type="button"
        class="flex flex-col items-center justify-center w-full gap-1.5 px-3 py-6 border border-dashed rounded-lg outline-none border-n-strong hover:border-n-slate-8 hover:bg-n-alpha-1 focus-visible:outline-n-blue-9"
        @click="openFilePicker"
        @dragover.prevent
        @drop.prevent="onDrop"
      >
        <Icon icon="i-lucide-upload" class="size-5 text-n-slate-11" />
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('VIDEO_EMBED.UPLOAD_LABEL') }}
        </span>
        <span
          class="text-xs"
          :class="showUploadError ? 'text-n-ruby-11' : 'text-n-slate-10'"
        >
          {{
            showUploadError
              ? t('VIDEO_EMBED.UPLOAD_ERROR')
              : t('VIDEO_EMBED.UPLOAD_HINT', {
                  size: props.maxUploadSize,
                })
          }}
        </span>
      </button>
      <input
        ref="fileInput"
        type="file"
        accept="video/mp4"
        hidden
        @change="onFileChange"
      />
    </template>
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
        v-if="mode === 'embed'"
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
