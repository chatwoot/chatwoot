<template>
  <div class="date--separator">
    {{ date }}
  </div>
</template>

<script>
export default {
  props: {
    date: {
      type: String,
      required: true,
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~widget/assets/scss/variables';

.date--separator {
  font-size: $font-size-default;
  color: $color-body;
  height: 50px;
  line-height: 50px;
  position: relative;
  text-align: center;
  width: 100%;
}

.date--separator::before,
.date--separator::after {
  background-color: $color-border;
  content: '';
  height: 1px;
  position: absolute;
  top: 24px;
  width: calc((100% - 120px) / 2);
}

.date--separator::before {
  left: 0;
}

.date--separator::after {
  right: 0;
}
</style>
