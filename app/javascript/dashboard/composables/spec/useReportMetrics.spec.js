import { ref } from 'vue';
import { useReportMetrics } from '../useReportMetrics';
import { useMapGetter } from 'dashboard/composables/store';
import { summary, botSummary } from './fixtures/reportFixtures';

vi.mock('dashboard/composables/store');
vi.mock('@chatwoot/utils', () => ({
  formatTime: vi.fn(time => `formatted_${time}`),
}));

describe('useReportMetrics', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useMapGetter.mockReturnValue(ref(summary));
  });

  it('calculates trend correctly', () => {
    const { calculateTrend } = useReportMetrics();

    expect(calculateTrend('conversations_count')).toBe(124900);
    expect(calculateTrend('incoming_messages_count')).toBe(0);
    expect(calculateTrend('avg_first_response_time')).toBe(123);
  });

  it('returns 0 for trend when previous value is not available', () => {
    const { calculateTrend } = useReportMetrics();

    expect(calculateTrend('non_existent_key')).toBe(0);
  });

  it('identifies average metric types correctly', () => {
    const { isAverageMetricType } = useReportMetrics();

    expect(isAverageMetricType('avg_first_response_time')).toBe(true);
    expect(isAverageMetricType('avg_resolution_time')).toBe(true);
    expect(isAverageMetricType('reply_time')).toBe(true);
    expect(isAverageMetricType('conversations_count')).toBe(false);
  });

  it('displays metrics correctly for account', () => {
    const { displayMetric } = useReportMetrics();

    expect(displayMetric('conversations_count')).toBe('5,000');
    expect(displayMetric('incoming_messages_count')).toBe('5');
  });

  it('displays the metric for bot', () => {
    const customKey = 'getBotSummary';
    useMapGetter.mockReturnValue(ref(botSummary));
    const { displayMetric } = useReportMetrics(customKey);

    expect(displayMetric('bot_resolutions_count')).toBe('10');
    expect(displayMetric('bot_handoffs_count')).toBe('20');
  });

  it('handles non-existent metrics', () => {
    const { displayMetric } = useReportMetrics();

    expect(displayMetric('non_existent_key')).toBe('0');
  });
});
