<template>
  <div
    :style="{ height: size, width: size }"
    class="rounded-full flex items-center justify-center bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-100"
    :title="username"
  >
    <slot>
      <img
        v-if="shouldShowImage"
        :src="src"
        draggable="false"
        @load="onImgLoad"
        @error="onImgError"
      />
      <div
        v-else
        :style="{ height: size, width: size }"
        class="flex justify-center items-center rounded-full"
        aria-hidden="true"
      >
        <span :style="{ fontSize: fontSize }" class="font-semibold">{{
          userInitial
        }}</span>
      </div>
    </slot>
  </div>
</template>
<script>
import { removeEmoji } from 'shared/helpers/emoji';

export default {
  props: {
    src: {
      type: String,
      default: '',
    },
    size: {
      type: String,
      default: '24px',
    },
    userName: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      hasImageLoaded: false,
      imgError: false,
    };
  },
  computed: {
    userNameWithoutEmoji() {
      return removeEmoji(this.userName);
    },
    showStatusIndicator() {
      if (this.shouldShowStatusAlways) return true;
      return this.status === 'online' || this.status === 'busy';
    },
    avatarSize() {
      return Number(this.size.replace(/\D+/g, ''));
    },
    shouldShowImage() {
      if (!this.src) {
        return false;
      }
      if (this.hasImageLoaded) {
        return !this.imgError;
      }
      return false;
    },
    userInitial() {
      return this.userName.charAt(0).toUpperCase();
    },
    fontSize() {
      return `${Math.floor(this.avatarSize / 2.5)}px`;
    },
  },
  watch: {
    src(value, oldValue) {
      if (value !== oldValue && this.imgError) {
        this.imgError = false;
      }
    },
  },
  methods: {
    onImgError() {
      this.imgError = true;
    },
    onImgLoad() {
      this.hasImageLoaded = true;
    },
  },
};
</script>
