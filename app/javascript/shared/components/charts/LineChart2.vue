<script setup>
import { computed } from 'vue';
import { Line } from 'vue-chartjs';
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
} from 'chart.js';
import { useI18n } from 'vue-i18n';
const props = defineProps({
  chartOptions: {
    type: Object,
    default: () => ({}),
  },
  datasets: {
    type: Array,
    default: () => [],
  },
  data1: {
    type: Object,
  },
  data2: {
    type: Object,
  },
  data3: {
    type: Object,
  },
});
ChartJS.register(
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement
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
  },
  animation: {
    duration: 0,
  },
  datasets: {
    bar: {
      barPercentage: 1.0,
    },
  },
  scales: {
    x: {
      ticks: {
        fontFamily: fontFamily,
      },
      grid: {
        drawOnChartArea: false,
      },
    },
    y: {
      type: 'linear',
      position: 'left',
      beginAtZero: true,
      ticks: {
        fontFamily: fontFamily,
        beginAtZero: true,
        stepSize: 1,
      },
      grid: {
        drawOnChartArea: false,
      },
    },
  },
};
const options = computed(() => {
  return { ...defaultChartOptions, ...props.chartOptions };
});
const { t } = useI18n();
const tension = 0.35;
const data = computed(() => {
  const colors = [
    'rgb(59, 130, 246)',   
    'rgb(34, 197, 94)',    
    'rgb(249, 115, 22)',   
    'rgb(239, 68, 68)',    
    'rgb(139, 92, 246)',   
    'rgb(6, 182, 212)',    
    'rgb(132, 204, 22)',   
    'rgb(245, 158, 11)',   
    'rgb(236, 72, 153)',   
    'rgb(107, 114, 128)',  
  ];
  let chartDatasets = [];
  let chartLabels = [];
  if (props.datasets && props.datasets.length > 0) {
    chartDatasets = props.datasets.map((dataset, index) => ({
      label: t(dataset.label),
      backgroundColor: colors[index % colors.length],
      borderColor: colors[index % colors.length],
      data: dataset.data?.map(e => e.value) || [],
      tension: tension,
    }));
    chartLabels = props.datasets[0]?.data?.map(e => {
      const date = new Date(e.timestamp * 1000);
      return `${date.getDate().toString().padStart(2, '0')}/${(date.getMonth() + 1).toString().padStart(2, '0')}`;
    }) || [];
  } else {
    if (!props.data1) {
      return undefined;
    }
    
    // Add data1 (Total Chats) - Blue
    if (props.data1?.data?.length) {
      chartDatasets.push({
        label: t(props.data1.label),
        backgroundColor: colors[0],
        borderColor: colors[0],
        data: props.data1.data?.map(e => e.value) || [],
        tension: tension,
      });
    }
    
    // Add data2 (Bot Chats) - Green
    if (props.data2?.data?.length) {
      chartDatasets.push({
        label: t(props.data2.label),
        backgroundColor: colors[1],
        borderColor: colors[1],
        data: props.data2.data?.map(e => e.value) || [],
        tension: tension,
      });
    }
    
    // Add data3 (Agent Chats) - Orange
    if (props.data3?.data?.length) {
      chartDatasets.push({
        label: t(props.data3.label),
        backgroundColor: colors[2],
        borderColor: colors[2],
        data: props.data3.data?.map(e => e.value) || [],
        tension: tension,
      });
    }
    chartLabels = props.data1?.data?.map(e => {
      const date = new Date(e.timestamp * 1000);
      return `${date.getDate().toString().padStart(2, '0')}/${(date.getMonth() + 1).toString().padStart(2, '0')}`;
    }) || [];
  }
  
  return {
    labels: chartLabels,
    datasets: chartDatasets,
  };
});
</script>
<template>
  <Line v-if="data" :data="data" :options="options" />
</template>