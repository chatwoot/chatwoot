<script setup>
import { computed } from 'vue';
import { Bar } from 'vue-chartjs';
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale,
} from 'chart.js';
import { useI18n } from 'vue-i18n';
const props = defineProps({
  chartOptions: {
    type: Object,
    default: () => ({}),
  },
  chartData: {
    type: Object,
    required: true,
  },
});
ChartJS.register(
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale
);
const fontFamily =
  'Inter,-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';
const defaultChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: true,
      position: 'top',
      labels: {
        fontFamily,
        usePointStyle: true,
        padding: 20,
      },
    },
    tooltip: {
      mode: 'index',
      intersect: false,
    },
  },
  animation: {
    duration: 300,
  },
  scales: {
    x: {
      ticks: {
        fontFamily: fontFamily,
      },
      grid: {
        display: false,
      },
    },
    y: {
      beginAtZero: true,
      ticks: {
        fontFamily: fontFamily,
      },
      grid: {
        drawOnChartArea: true,
        color: 'rgba(0, 0, 0, 0.1)',
      },
    },
  },
};
const options = computed(() => {
  return { ...defaultChartOptions, ...props.chartOptions };
});
const { t } = useI18n();
const data = computed(() => {
  if (!props.chartData) {
    return undefined;
  }
  
  return {
    labels: props.chartData.labels || [],
    datasets: [
      {
        label: t(props.chartData.data1?.label || ''),
        backgroundColor: 'rgba(59, 130, 246, 0.8)', // Blue
        borderColor: 'rgb(59, 130, 246)',
        borderWidth: 1,
        data: props.chartData.data1?.data || [],
      },
      {
        label: t(props.chartData.data2?.label || ''),
        backgroundColor: 'rgba(34, 197, 94, 0.8)', // Green
        borderColor: 'rgb(34, 197, 94)',
        borderWidth: 1,
        data: props.chartData.data2?.data || [],
      },
    ],
  };
});
</script>
<template>
  <Bar v-if="data" :data="data" :options="options" />
</template>