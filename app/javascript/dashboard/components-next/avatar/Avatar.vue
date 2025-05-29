<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { removeEmoji } from 'shared/helpers/emoji';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import wootConstants from 'dashboard/constants/globals';

const props = defineProps({
  src: {
    type: String,
    default: '',
  },
  name: {
    type: String,
    required: true,
  },
  size: {
    type: Number,
    default: 32,
  },
  allowUpload: {
    type: Boolean,
    default: false,
  },
  roundedFull: {
    type: Boolean,
    default: false,
  },
  status: {
    type: String,
    default: null,
    validator: value =>
      !value || wootConstants.AVAILABILITY_STATUS_KEYS.includes(value),
  },
  iconName: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['upload', 'delete']);

const { t } = useI18n();

const isImageValid = ref(true);
const fileInput = ref(null);

const AVATAR_COLORS = {
  dark: [
    ['#4B143D', '#FF8DCC'],
    ['#3F220D', '#FFA366'],
    ['#2A2A2A', '#ADB1B8'],
    ['#023B37', '#0BD8B6'],
    ['#27264D', '#A19EFF'],
    ['#1D2E62', '#9EB1FF'],
  ],
  light: [
    ['#FBDCEF', '#C2298A'],
    ['#FFE0BB', '#99543A'],
    ['#E8E8E8', '#60646C'],
    ['#CCF3EA', '#008573'],
    ['#EBEBFE', '#4747C2'],
    ['#E1E9FF', '#3A5BC7'],
  ],
  default: { bg: '#E8E8E8', text: '#60646C' },
};

const STATUS_CLASSES = {
  online: 'bg-n-teal-10',
  busy: 'bg-n-amber-10',
  offline: 'bg-n-slate-10',
};

const showDefaultAvatar = computed(() => !props.src && !props.name);

const initials = computed(() => {
  if (!props.name) return '';
  const words = removeEmoji(props.name).split(/\s+/);
  return words.length === 1
    ? words[0].charAt(0).toUpperCase()
    : words
        .slice(0, 2)
        .map(word => word.charAt(0))
        .join('')
        .toUpperCase();
});

const getColorsByNameLength = computed(() => {
  if (!props.name) return AVATAR_COLORS.default;

  const index = props.name.length % AVATAR_COLORS.light.length;
  return {
    bg: AVATAR_COLORS.light[index][0],
    darkBg: AVATAR_COLORS.dark[index][0],
    text: AVATAR_COLORS.light[index][1],
    darkText: AVATAR_COLORS.dark[index][1],
  };
});

const containerStyles = computed(() => ({
  width: `${props.size}px`,
  height: `${props.size}px`,
}));

const avatarStyles = computed(() => ({
  ...containerStyles.value,
  backgroundColor:
    !showDefaultAvatar.value && (!props.src || !isImageValid.value)
      ? getColorsByNameLength.value.bg
      : undefined,
  color:
    !showDefaultAvatar.value && (!props.src || !isImageValid.value)
      ? getColorsByNameLength.value.text
      : undefined,
  '--dark-bg': getColorsByNameLength.value.darkBg,
  '--dark-text': getColorsByNameLength.value.darkText,
}));

const badgeStyles = computed(() => {
  const badgeSize = Math.max(props.size * 0.35, 8); // 35% of avatar size, minimum 8px
  return {
    width: `${badgeSize}px`,
    height: `${badgeSize}px`,
    top: `${props.size - badgeSize / 1.1}px`,
    left: `${props.size - badgeSize / 1.1}px`,
  };
});

const iconStyles = computed(() => ({
  fontSize: `${props.size / 1.6}px`,
}));

const initialsStyles = computed(() => ({
  fontSize: `${Math.min(props.size / 2.5, 24)}px`,
}));

const invalidateCurrentImage = () => {
  isImageValid.value = false;
};

const handleUploadAvatar = () => {
  fileInput.value.click();
};

const handleImageUpload = event => {
  const [file] = event.target.files;
  if (file) {
    emit('upload', {
      file,
      url: file ? URL.createObjectURL(file) : null,
    });
  }
};

const handleDeleteAvatar = () => {
  if (fileInput.value) {
    fileInput.value.value = null;
  }
  emit('delete');
};

const handleDismiss = event => {
  event.stopPropagation();
  handleDeleteAvatar();
};

watch(
  () => props.src,
  () => {
    isImageValid.value = true;
  }
);
</script>

<template>
  <span class="relative inline-flex group/avatar z-0" :style="containerStyles">
    <!-- Status Badge -->
    <slot name="badge" :size="size">
      <div
        v-if="status"
        class="absolute z-20 border rounded-full border-n-slate-3"
        :style="badgeStyles"
        :class="STATUS_CLASSES[status]"
      />
    </slot>

    <!-- Delete Avatar Button -->
    <div
      v-if="src && allowUpload"
      class="absolute z-20 flex items-center justify-center invisible w-6 h-6 transition-all duration-300 ease-in-out opacity-0 cursor-pointer outline outline-1 outline-n-container -top-2 -right-2 rounded-xl bg-n-solid-3 group-hover/avatar:visible group-hover/avatar:opacity-100"
      @click="handleDismiss"
    >
      <Icon icon="i-lucide-x" class="text-n-slate-11 size-4" />
    </div>

    <!-- Avatar Container -->
    <span
      role="img"
      class="relative inline-flex items-center justify-center object-cover overflow-hidden font-medium"
      :class="[
        roundedFull ? 'rounded-full' : 'rounded-xl',
        {
          'dark:!bg-[var(--dark-bg)] dark:!text-[var(--dark-text)]':
            !showDefaultAvatar && (!src || !isImageValid),
          'bg-n-slate-3 dark:bg-n-slate-4': showDefaultAvatar,
        },
      ]"
      :style="avatarStyles"
    >
      <!-- Avatar Content -->
      <img
        v-if="src && isImageValid"
        :src="src"
        :alt="name"
        @error="invalidateCurrentImage"
      />

      <template v-else>
        <!-- Custom Icon -->
        <Icon v-if="iconName" :icon="iconName" :style="iconStyles" />

        <!-- Initials -->
        <span
          v-else-if="!showDefaultAvatar"
          :style="initialsStyles"
          class="select-none"
        >
          {{ initials }}
        </span>

        <!-- Fallback Icon if no name or image -->
        <Icon
          v-else
          v-tooltip.top-start="t('THUMBNAIL.AUTHOR.NOT_AVAILABLE')"
          icon="i-lucide-user"
          :style="iconStyles"
        />
      </template>

      <!-- Upload Overlay and Input -->
      <div
        v-if="allowUpload"
        class="absolute inset-0 z-10 flex items-center justify-center invisible w-full h-full transition-all duration-300 ease-in-out opacity-0 rounded-xl bg-n-alpha-black1 group-hover/avatar:visible group-hover/avatar:opacity-100"
        @click="handleUploadAvatar"
      >
        <Icon
          icon="i-lucide-upload"
          class="text-white"
          :style="{ width: `${size / 2}px`, height: `${size / 2}px` }"
        />
        <input
          ref="fileInput"
          type="file"
          accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
          class="hidden"
          @change="handleImageUpload"
        />
      </div>
    </span>
  </span>
</template>
