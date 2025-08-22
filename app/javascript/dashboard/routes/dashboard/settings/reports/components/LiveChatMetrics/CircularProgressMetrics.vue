<template>
  <div class="progress-container">
    <div class="circular-progress">
      <svg class="progress-ring" :width="size" :height="size">
        <circle
          class="progress-ring-background"
          :stroke-width="strokeWidth"
          :r="normalizedRadius"
          :cx="size / 2"
          :cy="size / 2"
          fill="transparent"
        />
        <circle
          class="progress-ring-progress intent-match"
          :stroke-width="strokeWidth"
          :stroke-dasharray="circumference + ' ' + circumference"
          :stroke-dashoffset="intentMatchOffset"
          :r="normalizedRadius"
          :cx="size / 2"
          :cy="size / 2"
          fill="transparent"
          :style="{ stroke: color }"
        />
      </svg>
      <div class="progress-text">
        <span class="percentage">{{ value }}%</span>
        <span class="label">{{ label }}</span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CircularProgressMetrics',
  props: {
    value: {
      type: Number,
      default: 75,
    },
    size: {
      type: Number,
      default: 200,
    },
    label: {
      type: String,
      default: 'Intent Match',
    },
    strokeWidth: {
      type: Number,
      default: 12,
    },
    color: {
      type: String,
      default: '#3b82f6',
    },
  },
  computed: {
    normalizedRadius() {
      return (this.size - this.strokeWidth * 2) / 2;
    },
    circumference() {
      return this.normalizedRadius * 2 * Math.PI;
    },
    intentMatchOffset() {
      return this.circumference - (this.value / 100) * this.circumference;
    },
  },
};
</script>

<style scoped>
.metrics-container {
  display: flex;
  gap: 24px;
  flex-wrap: wrap;
  justify-content: center;
  padding: 20px;
}

.metric-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  border: 1px solid #e5e7eb;
  min-width: 280px;
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;
}

.metric-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
}

.metric-header {
  margin-bottom: 20px;
  text-align: center;
}

.metric-title {
  font-size: 18px;
  font-weight: 600;
  color: #1f2937;
  margin: 0 0 8px 0;
}

.metric-description {
  font-size: 14px;
  color: #6b7280;
  margin: 0;
  line-height: 1.4;
}

.progress-container {
  display: flex;
  justify-content: center;
  align-items: center;
}

.circular-progress {
  position: relative;
  display: inline-block;
}

.progress-ring {
  transform: rotate(-90deg);
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.1));
}

.progress-ring-background {
  stroke: #e5e7eb;
  opacity: 0.2;
}

.progress-ring-progress {
  transition: stroke-dashoffset 1s ease-in-out;
  stroke-linecap: round;
}

.progress-ring-progress.intent-match {
  stroke: #3b82f6;
}

.progress-ring-progress.fall-back {
  stroke: #ef4444;
}

.progress-text {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  text-align: center;
}

.percentage {
  display: block;
  font-size: 24px;
  font-weight: 700;
  color: #1f2937;
  line-height: 1;
}

.label {
  display: block;
  font-size: 12px;
  color: #6b7280;
  font-weight: 500;
  margin-top: 4px;
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .metric-card {
    background: #1f2937;
    border-color: #4c5155;
  }

  .metric-title {
    color: #f9fafb;
  }

  .metric-description {
    color: #9ca3af;
  }

  .percentage {
    color: #f9fafb;
  }

  .label {
    color: #9ca3af;
  }

  .progress-ring-background {
    stroke: #4c5155;
    opacity: 0.3;
  }
}
</style>
