<template>
  <div
    class="flex h-16 items-center justify-between py-4 px-0 mb-1/4 border-b border-slate-50 dark:border-slate-700"
  >
    <div class="flex items-center">
      <thumbnail
        size="32px"
        :src="thumbnailSrc"
        :username="headerTitle"
        variant="square"
      />
      <div class="flex items-start flex-col ml-2 rtl:ml-0 rtl:mr-2">
        <h4
          class="text-sm w-28 h-4 mb-0 leading-4 overflow-hidden whitespace-nowrap text-ellipsis text-slate-800 dark:text-slate-100"
        >
          {{ headerTitle }}
        </h4>
        <span class="h-4 leading-4 text-slate-600 dark:text-slate-200 text-xs">
          {{ subTitle }}
        </span>
      </div>
    </div>
    <div class="flex items-end">
      <woot-button
        variant="clear"
        color-scheme="secondary"
        size="small"
        icon="arrow-up-right"
        @click="popoutHelpCenter"
      />
      <woot-button
        variant="clear"
        size="small"
        color-scheme="secondary"
        icon="arrow-swap"
        @click="openPortalPopover"
      />
    </div>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
export default {
  components: {
    Thumbnail,
  },
  props: {
    thumbnailSrc: {
      type: String,
      default: '',
    },
    headerTitle: {
      type: String,
      default: '',
    },
    subTitle: {
      type: String,
      default: '',
    },
    portalLink: {
      type: String,
      default: '',
    },
  },
  methods: {
    popoutHelpCenter() {
      window.open(this.portalLink, '_blank');
    },
    openPortalPopover() {
      this.$emit('open-popover');
    },
  },
};
</script>
