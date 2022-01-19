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
    heading: { type: String, default: '' },
    point: { type: [Number, String], default: '' },
    index: { type: Number, default: null },
    desc: { type: String, default: '' },
    selected: Boolean,
    onClick: { type: Function, default: () => {} },
  },
};
</script>
