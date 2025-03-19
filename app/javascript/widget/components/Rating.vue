<template>
  <div class="rating">
    <span
      v-for="n in maxRating"
      :key="n"
      class="star"
      :class="{ filled: n <= value }"
      @click="rate(n)"
      @mouseover="hover(n)"
      @mouseleave="hover(0)"
    >
      ★
    </span>
  </div>
</template>

<script>
export default {
  name: 'Rating',
  props: {
    value: {
      type: Number,
      required: true,
    },
    maxRating: {
      type: Number,
      default: 5,
    },
  },
  emits: ['update:value'],
  data() {
    return {
      hoverValue: 0,
    };
  },
  computed: {
    displayValue() {
      return this.hoverValue || this.value;
    },
  },
  methods: {
    rate(n) {
      this.$emit('update:value', n);
    },
    hover(n) {
      this.hoverValue = n;
    },
  },
};
</script>

<style scoped>
.rating {
  display: flex;
  gap: 4px;
  cursor: pointer;
}

.star {
  font-size: 32px;
  color: #ccc;
  transition: color 0.2s;
}

.star.filled {
  color: gold;
}
</style>
