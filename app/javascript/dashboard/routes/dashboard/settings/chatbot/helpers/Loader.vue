<script>
export default {
  props: {
    progress: {
      type: Number,
      default: 0,
    },
  },
};
</script>

<template>
  <div class="loader">
    <div class="shell">
      <div class="bar" :style="{ width: progress + '%' }" />
    </div>
  </div>
</template>

<style scoped>
.loader {
  height: 6px;
  display: flex;
  justify-content: center;
  align-items: center;
  font-family: sans-serif;
}

.shell {
  height: 6px;
  width: 100%;
  border: 1px solid #d6d4d4;
  border-radius: 9px;
}

.bar {
  background: linear-gradient(to right, #b993d6, #70baff, #47a6ff);
  height: 6px;
  width: 100%;
  border-radius: 9px;
  position: relative;
  overflow: hidden;
}
</style>
