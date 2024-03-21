<script setup></script>
<template>
  <div class="flex flex-col w-full h-full gap-10 settings-page">
    <slot name="header" />
    <slot name="body" />
  </div>
</template>
<style lang="scss" scoped>
// To be removed once we have a Inter as a global font
@import 'shared/assets/fonts/inter';
.settings-page {
  font-family:
    Inter,
    -apple-system,
    system-ui,
    BlinkMacSystemFont,
    'Segoe UI',
    Roboto,
    'Helvetica Neue',
    Arial,
    sans-serif !important;
}
</style>
