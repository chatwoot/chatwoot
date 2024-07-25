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
      this.$emit('openPopover');
    },
  },
};
</script>

<template>
  <div
    class="flex items-center justify-between h-16 px-0 py-4 border-b mb-1/4 border-slate-50 dark:border-slate-700"
  >
    <div class="flex items-center">
      <Thumbnail
        size="32px"
        :src="thumbnailSrc"
        :username="headerTitle"
        variant="square"
      />
      <div class="flex flex-col items-start ml-2 rtl:ml-0 rtl:mr-2">
        <h4
          class="h-4 mb-0 overflow-hidden text-sm leading-4 w-28 whitespace-nowrap text-ellipsis text-slate-800 dark:text-slate-100"
        >
          {{ headerTitle }}
        </h4>
        <span class="h-4 text-xs leading-4 text-slate-600 dark:text-slate-200">
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
