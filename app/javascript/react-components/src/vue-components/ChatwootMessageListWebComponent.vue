<script setup>
import MessageList from '../../../ui/MessageList.vue';
</script>

<template>
  <div id="cw-app-root">
    <MessageList />
  </div>
  <div id="cw-modal-root" />
</template>

<style>
/* Bubble theme overrides are in src/styles/bubble-overrides.css */

.file-uploads {
  overflow: hidden;
  position: relative;
  text-align: center;
  display: inline-block;
}

.file-uploads.file-uploads-html4 input,
.file-uploads.file-uploads-html5 label {
  /* background fix ie  click */
  background: #fff;
  opacity: 0;
  font-size: 20em;
  z-index: 1;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  position: absolute;
  width: 100%;
  height: 100%;
}

.file-uploads.file-uploads-html5 input,
.file-uploads.file-uploads-html4 label {
  /* background fix ie  click */
  position: absolute;
  background: rgba(255, 255, 255, 0);
  overflow: hidden;
  position: fixed;
  width: 1px;
  height: 1px;
  z-index: -1;
  opacity: 0;
}
</style>
