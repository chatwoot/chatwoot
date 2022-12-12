<template>
  <div v-if="!useIframe" :class="[className]" v-html="sanitizedHtml" />
  <div v-else-if="useIframe" :class="[className]">
    <iframe :src="iframeSrc" :title="iframeTitle" />
  </div>
</template>

<script lang="ts" src="./Letter.ts"></script>
