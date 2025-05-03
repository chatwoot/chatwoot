<script setup>
import { computed } from 'vue';
import { Line, Bar } from 'vue-chartjs';
import {
  Chart as ChartJS,
  Title,
  Tooltip,
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
  data1: {
    type: Array,
  },
  data2: {
    type: Array,
  },
});

ChartJS.register(
  Title,
  Tooltip,
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
  legend: {
    display: false,
    labels: {
      fontFamily,
    },
  },
  plugins: {
    legend: {
      display: false,
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
  if (!props.data1 || !props.data2) {
    return undefined;
  }
  return {
    labels:
      props.data1?.data?.map(e => {
        const date = new Date(e.timestamp * 1000);
        return `${date.getDate().toString().padStart(2, '0')}/${(date.getMonth() + 1).toString().padStart(2, '0')}`;
      }) || [],
    datasets: [
      {
        label: t(props.data2.label),
        backgroundColor: 'rgb(144, 196, 245)',
        borderColor: 'rgb(144, 196, 245)',
        data: props.data2.data?.map(e => e.value) || [],
        tension: tension,
      },
      {
        label: t(props.data1.label),
        backgroundColor: 'rgb(31, 147, 255)',
        borderColor: 'rgb(31, 147, 255)',
        data: props.data1.data?.map(e => e.value) || [],
        tension: tension,
      },
    ],
  };
});
</script>

<template>
  <Bar v-if="data" :data="data" :options="options" />
</template>
