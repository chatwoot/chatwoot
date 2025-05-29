<script setup>
import { onMounted, ref, watch } from 'vue';

const props = defineProps({
  modelValue: String,
  previewPosition: {
    type: Object,
    default: () => ({
      right: 90,
      top: 130,
    }),
  },
});

const emailFrame = ref(null);

const writeToIframe = () => {
  if (emailFrame.value?.contentWindow?.document) {
    const doc = emailFrame.value.contentWindow.document;
    doc.open();
    doc.write(props.modelValue);
    doc.close();
  }
};

onMounted(writeToIframe);
watch(() => props.modelValue, writeToIframe);
</script>

<template>
  <div
    class="template-preview-wrapper"
    :style="{
      right: `${props.previewPosition.right}px`,
      top: `${props.previewPosition.top}px`,
    }"
  >
    <iframe
      ref="emailFrame"
      class="email-preview"
      title="Email Preview"
    ></iframe>
  </div>
</template>

<style scoped>
.template-preview-wrapper {
  position: fixed;
  width: 441.17px;
  height: 850px;
  transform: scale(0.88);
  transform-origin: top left;
  background: white;
  border-radius: 20px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 10px;
  margin: 10px;
  /* overflow: hidden; */
  /* 💡 These two are key */
  overflow-x: auto;
  overflow-y: auto;
  /* overflow-y: auto; */
}

.email-preview {
  width: 100%;
  /* width: 1080px; */
  height: 1920px;
  background: white;
}
</style>
