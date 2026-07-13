import { describe, expect, it } from 'vitest';
import { SUPPORT_AGENT_PROMPT } from '../src/agent/prompt.js';
import { MOCK_ORDER } from '../src/agent/rpls-mock-tools.js';

describe('support agent configuration', () => {
  it('documents one no-tool, read-tool, and read-write case from the source sheet', () => {
    expect(SUPPORT_AGENT_PROMPT).toContain('2행 "단순 문의 예시"');
    expect(SUPPORT_AGENT_PROMPT).toContain('39행 "배송 일정 및 현황"');
    expect(SUPPORT_AGENT_PROMPT).toContain('60행 "주문 취소 요청"');
    expect(SUPPORT_AGENT_PROMPT).toContain('get_orders_by_customer_phone');
    expect(SUPPORT_AGENT_PROMPT).toContain('create_order_cancel_ticket');
  });

  it('provides a cancellable mock order matching the RPLS read and write contracts', () => {
    expect(MOCK_ORDER.lines[0]).toMatchObject({
      orderState: 'PURCHASED',
      canRequestCancel: true,
      orderQuantity: 1
    });
    expect(MOCK_ORDER.lines[0].orderItemId).toBeTruthy();
  });
});
