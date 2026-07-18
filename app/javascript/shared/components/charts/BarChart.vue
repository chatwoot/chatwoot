<script setup>
import { computed } from 'vue';
import { Bar } from 'vue-chartjs';
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  BarElement,
  CategoryScale,
  LinearScale,
} from 'chart.js';

const props = defineProps({
  collection: {
    type: Object,
    default: () => ({}),
  },
  chartOptions: {
    type: Object,
    default: () => ({}),
  },
  clickable: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['elementClick']);

ChartJS.register(Title, Tooltip, BarElement, CategoryScale, LinearScale);

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

const handleClick = (event, elements, chart) => {
  props.chartOptions.onClick?.(event, elements, chart);

  if (!props.clickable || !elements.length) return;

  const { datasetIndex, index } = elements[0];
  const dataset = props.collection.datasets?.[datasetIndex] || {};

  emit('elementClick', {
    datasetIndex,
    dataIndex: index,
    dataset,
    label: props.collection.labels?.[index],
    value: dataset.data?.[index],
  });
};

const handleHover = (event, elements, chart) => {
  props.chartOptions.onHover?.(event, elements, chart);

  if (!event?.native?.target) return;

  event.native.target.style.cursor =
    props.clickable && elements.length ? 'pointer' : 'default';
};

const options = computed(() => {
  return {
    ...defaultChartOptions,
    ...props.chartOptions,
    onClick: handleClick,
    onHover: handleHover,
  };
});
</script>

<template>
  <Bar :data="collection" :options="options" />
</template>
