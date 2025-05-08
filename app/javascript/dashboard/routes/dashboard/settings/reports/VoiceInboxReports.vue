<script setup>
import { useRoute } from 'vue-router';
import { useFunctionGetter } from 'dashboard/composables/store';
import { ref, onMounted, computed } from 'vue';
import { format } from 'date-fns';
import { formatTime } from '@chatwoot/utils';
import ReportHeader from './components/ReportHeader.vue';
import ReportFilters from './components/ReportFilters.vue';
import V4Button from 'dashboard/components-next/button/Button.vue';
import BarChart from 'shared/components/charts/BarChart.vue';
import { GROUP_BY_FILTER, GROUP_BY_OPTIONS } from './constants';

const route = useRoute();
const inbox = useFunctionGetter('inboxes/getInboxById', route.params.id);

// For this dummy implementation, we'll show dummy data
// In a real implementation, this would fetch actual call data from the API
console.log('VoiceInboxReports: Using dummy data for demonstration');

// Dummy data for voice metrics
const voiceMetrics = ref({
  total_calls: { value: 145, trend: 12 },
  incoming_calls: { value: 98, trend: 8 },
  outgoing_calls: { value: 47, trend: 15 },
  average_duration: { value: 248, trend: -5 }, // in seconds
  average_waiting_time: { value: 32, trend: -10 }, // in seconds
  missed_calls: { value: 12, trend: -20 },
  call_success_rate: { value: 92, trend: 5 }, // percentage
});

// Chart data
const from = ref(Math.floor(Date.now() / 1000) - 30 * 24 * 60 * 60); // 30 days ago
const to = ref(Math.floor(Date.now() / 1000));
const groupBy = ref(GROUP_BY_FILTER[1]); // Day
const groupByfilterItemsList = ref([
  { id: 1, groupBy: 'Day' },
  { id: 2, groupBy: 'Week' },
  { id: 3, groupBy: 'Month' },
]);
const selectedGroupByFilter = ref(groupByfilterItemsList.value[0]);
const businessHours = ref(false);

// Generate random chart data
const generateRandomData = (min, max, count) => {
  return Array.from({ length: count }, () => 
    Math.floor(Math.random() * (max - min + 1) + min)
  );
};

// Generate dates for the last 7 days (default selection)
const generateDateLabels = (days = 7) => {
  const dates = [];
  const today = new Date();
  
  for (let i = days - 1; i >= 0; i--) {
    const date = new Date();
    date.setDate(today.getDate() - i);
    dates.push(format(date, 'dd-MMM'));
  }
  
  return dates;
};

// Chart data for calls by type
const callsByTypeChart = computed(() => {
  return {
    labels: generateDateLabels(),
    datasets: [
      {
        label: 'Incoming Calls',
        data: generateRandomData(2, 8, 7),
        backgroundColor: '#3B82F6', // blue
        barPercentage: 0.6,
      },
      {
        label: 'Outgoing Calls',
        data: generateRandomData(1, 5, 7),
        backgroundColor: '#6366F1', // indigo
        barPercentage: 0.6,
      },
      {
        label: 'Missed Calls',
        data: generateRandomData(0, 2, 7),
        backgroundColor: '#F97316', // orange
        barPercentage: 0.6,
      },
    ]
  };
});

// Chart data for call duration
const callDurationChart = computed(() => {
  return {
    labels: generateDateLabels(),
    datasets: [
      {
        label: 'Average Call Duration (seconds)',
        data: generateRandomData(180, 320, 7),
        backgroundColor: '#3B82F6', // blue (chatwoot standard)
        barPercentage: 0.6,
      }
    ]
  };
});

// Chart data for waiting time
const waitingTimeChart = computed(() => {
  return {
    labels: generateDateLabels(),
    datasets: [
      {
        label: 'Average Waiting Time (seconds)',
        data: generateRandomData(15, 60, 7),
        backgroundColor: '#3B82F6', // blue (chatwoot standard)
        barPercentage: 0.6,
      }
    ]
  };
});

// Chart data for call success rate
const successRateChart = computed(() => {
  return {
    labels: generateDateLabels(),
    datasets: [
      {
        label: 'Call Success Rate (%)',
        data: generateRandomData(75, 100, 7),
        backgroundColor: '#3B82F6', // blue (chatwoot standard)
        barPercentage: 0.6,
      }
    ]
  };
});

// Chart options
const chartOptions = {
  scales: {
    y: {
      beginAtZero: true,
    },
  },
  responsive: true,
  maintainAspectRatio: false,
};

// Dummy handlers
const onDateRangeChange = (payload) => {
  // In a real implementation, this would fetch new data based on date range
  console.log('Date range changed', payload);
};

const onGroupByFilterChange = (payload) => {
  selectedGroupByFilter.value = payload;
  groupBy.value = GROUP_BY_FILTER[payload.id];
  // In a real implementation, this would fetch new data based on grouping
  console.log('Group by filter changed', groupBy.value);
};

const onBusinessHoursToggle = (value) => {
  businessHours.value = value;
  // In a real implementation, this would fetch new data with business hours filter
  console.log('Business hours toggle', value);
};

// Format time helper (converts seconds to MM:SS format)
const formatSecondsToTime = (seconds) => {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
};

const downloadReports = () => {
  alert('This would download voice reports in a real implementation.');
};
</script>

<template>
  <div>
    <ReportHeader 
      :header-title="$t('INBOX_REPORTS.VOICE_HEADER')" 
      has-back-button
    >
      <V4Button
        :label="$t('INBOX_REPORTS.DOWNLOAD_VOICE_REPORTS')"
        icon="i-ph-download-simple"
        size="sm"
        @click="downloadReports"
      />
    </ReportHeader>
    
    <ReportFilters
      type="inbox"
      :filter-items-list="[inbox]"
      :group-by-filter-items-list="groupByfilterItemsList"
      :selected-group-by-filter="selectedGroupByFilter"
      :current-filter="inbox"
      @date-range-change="onDateRangeChange"
      @group-by-filter-change="onGroupByFilterChange"
      @business-hours-toggle="onBusinessHoursToggle"
    />
    
    <!-- Main container -->
    <div class="py-4">
      <!-- Metrics Cards -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <!-- Total Calls -->
        <div class="bg-n-solid-2 p-4 rounded-lg shadow border border-n-container">
          <div class="text-n-slate-11 text-sm mb-1">{{ $t('INBOX_REPORTS.VOICE_METRICS.TOTAL_CALLS') }}</div>
          <div class="flex items-end">
            <span class="text-2xl font-semibold mr-2">{{ voiceMetrics.total_calls.value }}</span>
            <span class="text-xs" :class="voiceMetrics.total_calls.trend > 0 ? 'text-n-emerald-6' : 'text-n-ruby-6'">
              {{ voiceMetrics.total_calls.trend > 0 ? '↑' : '↓' }} {{ Math.abs(voiceMetrics.total_calls.trend) }}%
            </span>
          </div>
        </div>
        
        <!-- Incoming Calls -->
        <div class="bg-n-solid-2 p-4 rounded-lg shadow border border-n-container">
          <div class="text-n-slate-11 text-sm mb-1">{{ $t('INBOX_REPORTS.VOICE_METRICS.INCOMING_CALLS') }}</div>
          <div class="flex items-end">
            <span class="text-2xl font-semibold mr-2">{{ voiceMetrics.incoming_calls.value }}</span>
            <span class="text-xs" :class="voiceMetrics.incoming_calls.trend > 0 ? 'text-n-emerald-6' : 'text-n-ruby-6'">
              {{ voiceMetrics.incoming_calls.trend > 0 ? '↑' : '↓' }} {{ Math.abs(voiceMetrics.incoming_calls.trend) }}%
            </span>
          </div>
        </div>
        
        <!-- Outgoing Calls -->
        <div class="bg-n-solid-2 p-4 rounded-lg shadow border border-n-container">
          <div class="text-n-slate-11 text-sm mb-1">{{ $t('INBOX_REPORTS.VOICE_METRICS.OUTGOING_CALLS') }}</div>
          <div class="flex items-end">
            <span class="text-2xl font-semibold mr-2">{{ voiceMetrics.outgoing_calls.value }}</span>
            <span class="text-xs" :class="voiceMetrics.outgoing_calls.trend > 0 ? 'text-n-emerald-6' : 'text-n-ruby-6'">
              {{ voiceMetrics.outgoing_calls.trend > 0 ? '↑' : '↓' }} {{ Math.abs(voiceMetrics.outgoing_calls.trend) }}%
            </span>
          </div>
        </div>
        
        <!-- Missed Calls -->
        <div class="bg-n-solid-2 p-4 rounded-lg shadow border border-n-container">
          <div class="text-n-slate-11 text-sm mb-1">{{ $t('INBOX_REPORTS.VOICE_METRICS.MISSED_CALLS') }}</div>
          <div class="flex items-end">
            <span class="text-2xl font-semibold mr-2">{{ voiceMetrics.missed_calls.value }}</span>
            <span class="text-xs" :class="voiceMetrics.missed_calls.trend < 0 ? 'text-n-emerald-6' : 'text-n-ruby-6'">
              {{ voiceMetrics.missed_calls.trend > 0 ? '↑' : '↓' }} {{ Math.abs(voiceMetrics.missed_calls.trend) }}%
            </span>
          </div>
        </div>
      </div>

      <!-- More Metrics -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <!-- Average Call Duration -->
        <div class="bg-n-solid-2 p-4 rounded-lg shadow border border-n-container">
          <div class="text-n-slate-11 text-sm mb-1">{{ $t('INBOX_REPORTS.VOICE_METRICS.AVG_DURATION') }}</div>
          <div class="flex items-end">
            <span class="text-2xl font-semibold mr-2">{{ formatSecondsToTime(voiceMetrics.average_duration.value) }}</span>
            <span class="text-xs" :class="voiceMetrics.average_duration.trend > 0 ? 'text-n-emerald-6' : 'text-n-ruby-6'">
              {{ voiceMetrics.average_duration.trend > 0 ? '↑' : '↓' }} {{ Math.abs(voiceMetrics.average_duration.trend) }}%
            </span>
          </div>
        </div>
        
        <!-- Average Waiting Time -->
        <div class="bg-n-solid-2 p-4 rounded-lg shadow border border-n-container">
          <div class="text-n-slate-11 text-sm mb-1">{{ $t('INBOX_REPORTS.VOICE_METRICS.AVG_WAITING_TIME') }}</div>
          <div class="flex items-end">
            <span class="text-2xl font-semibold mr-2">{{ formatSecondsToTime(voiceMetrics.average_waiting_time.value) }}</span>
            <span class="text-xs" :class="voiceMetrics.average_waiting_time.trend < 0 ? 'text-n-emerald-6' : 'text-n-ruby-6'">
              {{ voiceMetrics.average_waiting_time.trend > 0 ? '↑' : '↓' }} {{ Math.abs(voiceMetrics.average_waiting_time.trend) }}%
            </span>
          </div>
        </div>
        
        <!-- Call Success Rate -->
        <div class="bg-n-solid-2 p-4 rounded-lg shadow border border-n-container">
          <div class="text-n-slate-11 text-sm mb-1">{{ $t('INBOX_REPORTS.VOICE_METRICS.SUCCESS_RATE') }}</div>
          <div class="flex items-end">
            <span class="text-2xl font-semibold mr-2">{{ voiceMetrics.call_success_rate.value }}%</span>
            <span class="text-xs" :class="voiceMetrics.call_success_rate.trend > 0 ? 'text-n-emerald-6' : 'text-n-ruby-6'">
              {{ voiceMetrics.call_success_rate.trend > 0 ? '↑' : '↓' }} {{ Math.abs(voiceMetrics.call_success_rate.trend) }}%
            </span>
          </div>
        </div>
      </div>
      
      <!-- Charts -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <!-- Calls by Type -->
        <div class="p-4 bg-n-solid-2 rounded-lg shadow border border-n-container">
          <h3 class="text-md font-semibold mb-3">{{ $t('INBOX_REPORTS.VOICE_CHARTS.CALLS_BY_TYPE') }}</h3>
          <div class="h-72">
            <BarChart 
              :collection="callsByTypeChart" 
              :chart-options="chartOptions"
            />
          </div>
        </div>
        
        <!-- Average Call Duration -->
        <div class="p-4 bg-n-solid-2 rounded-lg shadow border border-n-container">
          <h3 class="text-md font-semibold mb-3">{{ $t('INBOX_REPORTS.VOICE_CHARTS.CALL_DURATION') }}</h3>
          <div class="h-72">
            <BarChart 
              :collection="callDurationChart" 
              :chart-options="chartOptions"
            />
          </div>
        </div>
        
        <!-- Waiting Time -->
        <div class="p-4 bg-n-solid-2 rounded-lg shadow border border-n-container">
          <h3 class="text-md font-semibold mb-3">{{ $t('INBOX_REPORTS.VOICE_CHARTS.WAITING_TIME') }}</h3>
          <div class="h-72">
            <BarChart 
              :collection="waitingTimeChart" 
              :chart-options="chartOptions"
            />
          </div>
        </div>
        
        <!-- Call Success Rate -->
        <div class="p-4 bg-n-solid-2 rounded-lg shadow border border-n-container">
          <h3 class="text-md font-semibold mb-3">{{ $t('INBOX_REPORTS.VOICE_CHARTS.SUCCESS_RATE') }}</h3>
          <div class="h-72">
            <BarChart 
              :collection="successRateChart" 
              :chart-options="chartOptions"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>