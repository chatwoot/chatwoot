<template>
  <div class="overflow-auto p-4 max-w-full flex flex-row flex-nowrap h-full">
    <div class="sidebar">
      <!-- <woot-button class="icon" variant="clear" @click="showUploader('file')">
        <fluent-icon icon="document" />
        <span>{{ $t('CHATBOTS.UPLOAD.FILE') }}</span>
      </woot-button>
      <woot-button class="icon" variant="clear" @click="showUploader('text')">
        <fluent-icon icon="text-align-left" />
        <span>{{ $t('CHATBOTS.UPLOAD.TEXT') }}</span>
      </woot-button> -->
      <woot-button
        class="icon"
        variant="clear"
        @click="showUploader('website')"
      >
        <fluent-icon icon="globe" />
        <span>{{ $t('CHATBOTS.UPLOAD.WEBSITE') }}</span>
      </woot-button>
    </div>
    <router-view />
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import accountMixin from '../../../../mixins/account';
// import UploadArea from './UploadArea.vue';

export default {
  comments: {
    // UploadArea,
  },
  mixins: [alertMixin, accountMixin],
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
