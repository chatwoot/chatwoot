<script>
export default {
  data() {
    return {
      enabledFeatures: {},
    };
  },
  methods: {
    showUploader(type) {
      this.$emit('uploadTypeSelected', type);
    },
  },
};
</script>

<template>
  <div class="overflow-auto w-1/3 max-w-1/3 flex flex-row flex-nowrap h-full">
    <div class="sidebar">
      <woot-button
        class="icon"
        variant="clear"
        @click="showUploader('website')"
      >
        <fluent-icon icon="globe" />
        <span>{{ $t('CHATBOTS.UPLOAD.WEBSITE') }}</span>
      </woot-button>
      <woot-button class="icon" variant="clear" @click="showUploader('file')">
        <fluent-icon icon="document" />
        <span>{{ $t('CHATBOTS.UPLOAD.FILE') }}</span>
      </woot-button>
      <woot-button class="icon" variant="clear" @click="showUploader('text')">
        <fluent-icon icon="text-align-left" />
        <span>{{ $t('CHATBOTS.UPLOAD.TEXT') }}</span>
      </woot-button>
    </div>
    <router-view />
  </div>
</template>

<style>
.sidebar {
  display: flex;
  flex-direction: column;
}

.icon {
  display: flex;
  justify-content: left;
  align-items: center;
  gap: 20px;
}

.icon.active {
  background-color: #ffffff;
}
</style>
