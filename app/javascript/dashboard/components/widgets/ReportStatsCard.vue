<template>
  <div
    class="small-2 report-card"
    :class="{ active: selected }"
    @click="onClick(index)"
  >
    <h3 class="heading">
      {{ heading }}
    </h3>
    <h4 class="metric">
      {{ point }}
    </h4>
    <p class="desc">
      {{ desc }}
    </p>
  </div>
</template>
<script>
export default {
  props: {
    heading: String,
    point: [Number, String],
    index: Number,
    desc: String,
    selected: Boolean,
    onClick: Function,
  },
};
</script>
