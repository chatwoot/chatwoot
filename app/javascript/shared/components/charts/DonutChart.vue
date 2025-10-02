<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue';
import { Doughnut } from 'vue-chartjs';
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  ArcElement,
} from 'chart.js';
const props = defineProps({
  data: {
    type: Array,
    default: () => [],
  },
  labels: {
    type: Array,
    default: () => [],
  },
  chartOptions: {
    type: Object,
    default: () => ({}),
  },
});
ChartJS.register(Title, Tooltip, Legend, ArcElement);
const fontFamily =
  'Inter,-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';
const defaultChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: true,
      position: 'right',
      labels: {
        fontFamily: fontFamily,
        fontSize:30,
        padding: 20,
        usePointStyle: true,
        pointStyle: 'circle',
      },
    },
    tooltip: {
      backgroundColor: 'rgba(0, 0, 0, 0.8)',
      titleColor: '#fff',
      bodyColor: '#fff',
      borderColor: 'rgba(255, 255, 255, 0.1)',
      borderWidth: 1,
      cornerRadius: 6,
      displayColors: true,
      callbacks: {
        label: function(context) {
          const label = context.label || '';
          const value = context.parsed;
          const total = context.dataset.data.reduce((a, b) => a + b, 0);
          const percentage = ((value / total) * 100).toFixed(1);
          return `${label}: ${value} (${percentage}%)`;
        }
      }
    },
  },
  animation: {
    duration: 1000,
    easing: 'easeOutQuart',
  },
  cutout: '60%',
  borderWidth: 2,
  borderColor: '#fff',
};
const chartData = computed(() => {
  return {
    labels: props.labels,
    datasets: [
      {
        data: props.data,
        backgroundColor: [
          '#10B981', 
          '#F59E0B',
          '#3B82F6',
          '#EF4444',
          '#8B5CF6',
          '#EC4899',
        ],
        borderColor: [
          '#059669',
          '#D97706',
          '#2563EB',
          '#DC2626',
          '#7C3AED',
          '#DB2777',
        ],
        borderWidth: 2,
        hoverBackgroundColor: [
          '#047857',
          '#B45309',
          '#1D4ED8',
          '#B91C1C',
          '#6D28D9',
          '#BE185D',
        ],
        hoverBorderColor: '#fff',
        hoverBorderWidth: 3,
      },
    ],
  };
});
// Reactive dark mode detection
const isDarkMode = ref(false);
const updateDarkMode = () => {
  if (typeof window !== 'undefined') {
    isDarkMode.value = document.documentElement.classList.contains('dark') || 
                      window.matchMedia('(prefers-color-scheme: dark)').matches;
  }
};
// MutationObserver to watch for class changes on documentElement
let observer = null;
onMounted(() => {
  updateDarkMode();
  
  // Watch for changes to the documentElement class
  if (typeof window !== 'undefined') {
    observer = new MutationObserver(() => {
      updateDarkMode();
    });
    
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['class']
    });
    
    // Also listen for media query changes
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    mediaQuery.addEventListener('change', updateDarkMode);
  }
});
onUnmounted(() => {
  if (observer) {
    observer.disconnect();
  }
  if (typeof window !== 'undefined') {
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    mediaQuery.removeEventListener('change', updateDarkMode);
  }
});
const options = computed(() => {
  const legendColor = isDarkMode.value ? '#fff' : '#374151'; // Using a darker gray for better contrast in light mode
  const merged = { ...defaultChartOptions, ...props.chartOptions };
  if (!merged.plugins) merged.plugins = {};
  if (!merged.plugins.legend) merged.plugins.legend = {};
  if (!merged.plugins.legend.labels) merged.plugins.legend.labels = {};
  if (!merged.plugins.legend.labels.font) merged.plugins.legend.labels.font = {};
  merged.plugins.legend.labels.font.color = legendColor;
  return merged;
});
</script>

<template>
  <Doughnut :data="chartData" :options="options" />
</template>