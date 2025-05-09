<template>
  <div class="rating">
    <div
      v-for="n in maxRating"
      :key="n"
      class="emoji-wrapper"
      @click="rate(n)"
      @mouseover="hover(n)"
      @mouseleave="hover(0)"
    >
      <span
        class="emoji"
        :class="{
          'emoji-active': n === displayValue,
          'emoji-hover': n <= hoverValue && n > value,
        }"
      >
        {{ emojiList[n - 1] }}
      </span>
    </div>
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
      emojiSets: {
        default: ['😡', '😕', '😐', '🙂', '🤩'],
        faces: ['😠', '🙁', '😐', '🙂', '🤩'],
      },
      neutralEmoji: '😐',
    };
  },
  computed: {
    displayValue() {
      return this.hoverValue || this.value;
    },
    emojiList() {
      return this.emojiSets.default;
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
  gap: 12px;
  justify-content: center;
  padding: 10px 0;
}

.emoji-wrapper {
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  position: relative;
}

.emoji {
  font-size: 36px;
  transition: all 0.2s ease;
  transform-origin: center;
  display: flex;
  justify-content: center;
  align-items: center;
  opacity: 0.7;
}

.emoji-active {
  transform: scale(1.1);
  opacity: 1;
}

.emoji-hover {
  transform: scale(1.05);
  opacity: 0.9;
}

.emoji-wrapper:hover .emoji {
  transform: scale(1.2);
}

@media (max-width: 768px) {
  .emoji {
    font-size: 32px;
  }
  .rating {
    gap: 8px;
  }
}
</style>
