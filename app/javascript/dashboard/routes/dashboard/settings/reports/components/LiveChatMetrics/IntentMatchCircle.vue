<template>
  <div class="flex flex-col w-full relative">
    <div v-if="tooltip.visible" class="tooltip" :style="tooltipStyle">
      <div class="tooltip-content">
        <div class="tooltip-header">
          <span
            class="tooltip-dot"
            :style="{ backgroundColor: tooltip.data.color }"
          />
          <span class="tooltip-label">{{ tooltip.data.label }}</span>
        </div>
        <div class="tooltip-percentage">{{ tooltip.data.percentage }}%</div>
      </div>
    </div>
    <div class="progress-container">
      <div class="circular-progress">
        <svg class="progress-ring" :width="size" :height="size">
          <!-- Background circle -->
          <circle
            class="progress-ring-background"
            :stroke-width="strokeWidth"
            :r="normalizedRadius"
            :cx="size / 2"
            :cy="size / 2"
            fill="transparent"
          />
          <!-- Dynamic segments -->
          <circle
            v-for="(segment, index) in segments"
            :key="index"
            class="progress-ring-segment"
            :stroke-width="strokeWidth"
            :stroke-dasharray="segment.dashArray"
            :stroke-dashoffset="segment.dashOffset"
            :r="normalizedRadius"
            :cx="size / 2"
            :cy="size / 2"
            fill="transparent"
            :style="{ stroke: segment.color }"
            @mouseenter="showTooltip($event, data[index], index)"
            @mousemove="updateTooltipPosition($event)"
            @mouseleave="hideTooltip"
          />
        </svg>
      </div>
    </div>

    <div class="breakdown">
      <h4 class="breakdown-title">Breakdown</h4>
      <div class="breakdown-list">
        <div v-for="(item, index) in data" :key="index" class="breakdown-item">
          <div class="item-info">
            <span class="color-dot" :style="{ backgroundColor: item.color }" />
            <span class="item-label">{{ item.label }}</span>
          </div>
          <span class="item-percentage">{{ item.percentage }}%</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'IntentMatchProgress',
  props: {
    matchPercentage: {
      type: Number,
      default: 94,
    },
    size: {
      type: Number,
      default: 200,
    },
    strokeWidth: {
      type: Number,
      default: 16,
    },
    data: {
      type: Array,
      default: () => [
        {
          label: 'Intent Match',
          percentage: 0,
          color: '#4F46E5',
        },
        { label: 'Order Tracking', percentage: 0, color: '#3B82F6' },
        { label: 'Agent Assignment', percentage: 0, color: '#06B6D4' },
        { label: 'Product Query', percentage: 0, color: '#8B5CF6' },
        { label: 'Unrelated Query', percentage: 0, color: '#06D6A0' },
        { label: 'Discount Query', percentage: 0, color: '#A855F7' },
        { label: 'General Message', percentage: 0, color: '#EC4899' },
        { label: 'Product Search', percentage: 0, color: '#F59E0B' },
      ],
    },
  },
  data() {
    return {
      tooltip: {
        visible: false,
        data: {},
        x: 0,
        y: 0,
      },
      hoveredSegment: null,
    };
  },
  computed: {
    normalizedRadius() {
      return (this.size - this.strokeWidth * 2) / 2;
    },
    circumference() {
      return this.normalizedRadius * 2 * Math.PI;
    },
    segments() {
      let cumulativePercentage = 0;
      const gapPercentage = 0.5; // Small gap between segments

      return this.data.map(item => {
        const segmentLength = (item.percentage / 100) * this.circumference;

        const dashArray = `${segmentLength} ${
          this.circumference - segmentLength
        }`;
        const dashOffset =
          this.circumference -
          (cumulativePercentage / 100) * this.circumference;

        cumulativePercentage += item.percentage + gapPercentage;

        return {
          dashArray,
          dashOffset,
          color: item.color,
        };
      });
    },
    tooltipStyle() {
      return {
        left: `${this.tooltip.x}px`,
        top: `${this.tooltip.y}px`,
        transform: 'translate(-50%, -100%)',
      };
    },
  },
  methods: {
    showTooltip(event, data, index) {
      this.hoveredSegment = index;
      this.tooltip.visible = true;
      this.tooltip.data = data;
      this.updateTooltipPosition(event);
    },
    updateTooltipPosition(event) {
      const rect = this.$el.getBoundingClientRect();
      this.tooltip.x = event.clientX - rect.left;
      this.tooltip.y = event.clientY - rect.top - 10;
    },
    hideTooltip() {
      this.tooltip.visible = false;
      this.hoveredSegment = null;
    },
  },
};
</script>

<style scoped>
.progress-container {
  display: flex;
  justify-content: center;
  margin-bottom: 32px;
}

.circular-progress {
  position: relative;
  display: inline-block;
}

.progress-ring {
  transform: rotate(-90deg);
  filter: drop-shadow(0 2px 8px rgba(0, 0, 0, 0.1));
}

.progress-ring-background {
  stroke: #e2e8f0;
  opacity: 0.3;
}

.progress-ring-segment {
  transition: stroke-dashoffset 1.5s ease-in-out;
  stroke-linecap: round;
}

/* Tooltip styles */
.tooltip {
  position: absolute;
  z-index: 1000;
  pointer-events: none;
  transition: opacity 0.2s ease-in-out;
}

.tooltip-content {
  background: white;
  border-radius: 8px;
  padding: 12px 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  border: 1px solid #e2e8f0;
  min-width: 160px;
}

.tooltip-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.tooltip-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.tooltip-label {
  font-size: 13px;
  color: #64748b;
  font-weight: 500;
  line-height: 1.2;
}

.tooltip-percentage {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
  text-align: right;
}

.breakdown {
  text-align: left;
}

.breakdown-title {
  font-size: 18px;
  font-weight: 600;
  margin: 0 0 16px 0;
}

.breakdown-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.breakdown-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 4px 0;
}

.item-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.color-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  flex-shrink: 0;
}

.item-label {
  font-size: 14px;
  font-weight: 500;
}

.item-percentage {
  font-size: 14px;
  font-weight: 600;
}

/* Hover effects */
.breakdown-item:hover {
  background-color: #f8fafc;
  border-radius: 6px;
  margin: 0 -8px;
  padding: 4px 8px;
  color: #0f172a;
}
</style>
