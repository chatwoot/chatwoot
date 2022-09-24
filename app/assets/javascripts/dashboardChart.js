// eslint-disable-next-line
function prepareData(data) {
  const labels = [];
  const dataSet = [];
  data.forEach(item => {
    labels.push(item[0]);
    dataSet.push(item[1]);
  });
  return { labels, dataSet };
}

function getChartOptions() {
  const fontFamily =
    'Inter,-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';
  return {
    responsive: true,
    legend: { labels: { fontFamily } },
    scales: {
      xAxes: [
        {
          barPercentage: 1.26,
          ticks: { fontFamily },
          gridLines: { display: false },
        },
      ],
      yAxes: [
        {
          ticks: { fontFamily },
          gridLines: { display: false },
        },
      ],
    },
  };
}

// eslint-disable-next-line
function drawSuperAdminDashboard(data) {
  const ctx = document.getElementById('dashboard-chart').getContext('2d');
  const chartData = prepareData(data);
  // eslint-disable-next-line
  new Chart(ctx, {
    type: 'bar',
    data: {
      labels: chartData.labels,
      datasets: [
        {
          label: 'Conversations',
          data: chartData.dataSet,
          backgroundColor: '#1f93ff',
        },
      ],
    },
    options: getChartOptions(),
  });
}
