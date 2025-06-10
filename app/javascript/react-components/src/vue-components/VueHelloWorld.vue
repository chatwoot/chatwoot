<script setup>
import { ref, computed } from 'vue';

// Props that will become Web Component attributes
const props = defineProps({
  initialCount: {
    type: [Number, String],
    default: 0,
  },
  title: {
    type: String,
    default: 'Hello from Vue!',
  },
  color: {
    type: String,
    default: '#42b883',
  },
});

// Local state
const count = ref(Number(props.initialCount));

// Computed styles based on props
const buttonStyle = computed(() => ({
  backgroundColor: props.color,
  color: 'white',
  border: 'none',
  padding: '10px 20px',
  borderRadius: '4px',
  cursor: 'pointer',
  fontSize: '16px',
  margin: '5px',
}));

// Computed text labels to avoid bare strings
const labels = computed(() => ({
  currentCount: 'Current Count:',
  increment: '+ Increment',
  decrement: '- Decrement',
  reset: 'Reset',
  info: 'This is a Vue component converted to Web Component!',
}));

// Methods
const increment = () => {
  count.value += 1;
  // Emit custom event for parent components
  document.dispatchEvent(
    new CustomEvent('vue-counter-changed', {
      detail: { count: count.value },
    })
  );
};

const decrement = () => {
  count.value -= 1;
  document.dispatchEvent(
    new CustomEvent('vue-counter-changed', {
      detail: { count: count.value },
    })
  );
};

const reset = () => {
  count.value = Number(props.initialCount);
  document.dispatchEvent(
    new CustomEvent('vue-counter-changed', {
      detail: { count: count.value },
    })
  );
};
</script>

<template>
  <div class="vue-hello-world">
    <h3>{{ title }}</h3>
    <p class="count-display">{{ labels.currentCount }} {{ count }}</p>
    <div class="button-group">
      <button :style="buttonStyle" @click="increment">
        {{ labels.increment }}
      </button>
      <button :style="buttonStyle" @click="decrement">
        {{ labels.decrement }}
      </button>
      <button
        :style="{ ...buttonStyle, backgroundColor: '#dc3545' }"
        @click="reset"
      >
        {{ labels.reset }}
      </button>
    </div>
    <p class="info">{{ labels.info }}</p>
  </div>
</template>

<style scoped>
.vue-hello-world {
  padding: 20px;
  border: 2px solid #42b883;
  border-radius: 8px;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  max-width: 400px;
  margin: 20px auto;
  text-align: center;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
}

.count-display {
  font-size: 18px;
  font-weight: bold;
  color: #2c3e50;
  margin: 15px 0;
}

.button-group {
  display: flex;
  justify-content: center;
  gap: 10px;
  flex-wrap: wrap;
  margin: 20px 0;
}

.info {
  font-size: 12px;
  color: #666;
  font-style: italic;
  margin-top: 15px;
}

h3 {
  color: #2c3e50;
  margin-bottom: 15px;
}
</style>
