import { tool, type FunctionTool, type RunContext } from '@openai/agents';
import type { FastifyBaseLogger } from 'fastify';
import { z } from 'zod';

export type SupportAgentContext = {
  conversationId: number;
  customerPhone: string;
  logger: FastifyBaseLogger;
  ordersRead: boolean;
};

const MOCK_ORDER = {
  orderId: 'ORDER-MOCK-1001',
  createdAtMillis: Date.parse('2026-07-10T03:00:00Z'),
  confirmedAtMillis: Date.parse('2026-07-10T03:01:00Z'),
  paymentMethodName: '카드 결제',
  lines: [
    {
      orderLineGroupId: 'OLG-MOCK-1001',
      orderLineId: 'OL-MOCK-1001',
      orderItemId: 'OI-MOCK-1001',
      productItemId: 'PI-MOCK-1001',
      productTitle: '여성 진주 포인트 블랙 헤어핀',
      productItemTitle: '블랙 / FREE',
      orderQuantity: 1,
      orderState: 'PURCHASED',
      orderStateName: '결제 완료',
      deliveryStateName: '배송 준비 중',
      estimateShipmentAt: '2026-07-15',
      deliveryVendorName: 'CJ대한통운',
      deliveryVendorNumber: '599200954313',
      canRequestCancel: true,
      canRequestReturn: false,
      canRequestExchange: false
    }
  ]
} as const;

const getContext = (context?: RunContext<SupportAgentContext>): SupportAgentContext => {
  if (!context?.context) throw new Error('Support agent context is missing');
  return context.context;
};

const getOrdersParameters = z.object({});
const cancelTicketParameters = z.object({
  orderId: z.string().describe('조회 결과의 orderId'),
  orderItemId: z.string().describe('조회 결과의 orderItemId'),
  quantity: z.number().int().positive().describe('취소 수량'),
  reason: z.string().min(1).describe('고객 취소 사유')
});

type RplsMockTool =
  | FunctionTool<SupportAgentContext, typeof getOrdersParameters, unknown>
  | FunctionTool<SupportAgentContext, typeof cancelTicketParameters, unknown>;

export const createRplsMockTools = (): RplsMockTool[] => {
  const getOrders = tool<typeof getOrdersParameters, SupportAgentContext>({
    name: 'get_orders_by_customer_phone',
    description:
      'RPLS GET /generativelab/orders-by-phone 기반 mock. Widget에서 검증된 고객 전화번호로 주문과 배송·취소 가능 상태를 조회한다.',
    parameters: getOrdersParameters,
    execute: async (_input, runContext) => {
      const context = getContext(runContext);
      context.ordersRead = true;
      context.logger.info({
        event: 'agent_tool_call',
        tool: 'get_orders_by_customer_phone',
        mode: 'mock',
        status: 'success',
        conversationId: context.conversationId,
        customerPhonePresent: Boolean(context.customerPhone)
      });
      return {
        list: [MOCK_ORDER],
        totalPageCount: 1,
        totalElementCount: 1
      };
    }
  });

  const createCancelTicket = tool<typeof cancelTicketParameters, SupportAgentContext>({
    name: 'create_order_cancel_ticket',
    description:
      'RPLS PUT /generativelab/orders/lines/cancel-tickets 기반 mock. 조회한 취소 가능 주문 라인에 취소 티켓을 생성한다.',
    parameters: cancelTicketParameters,
    execute: async (input, runContext) => {
      const context = getContext(runContext);
      if (!context.ordersRead) throw new Error('주문 조회를 먼저 수행해야 합니다.');

      const line = MOCK_ORDER.lines[0];
      if (input.orderId !== MOCK_ORDER.orderId || input.orderItemId !== line.orderItemId) {
        throw new Error('조회 결과에 없는 주문입니다.');
      }
      if (!line.canRequestCancel) throw new Error('취소할 수 없는 주문입니다.');

      context.logger.info({
        event: 'agent_tool_call',
        tool: 'create_order_cancel_ticket',
        mode: 'mock',
        status: 'success',
        conversationId: context.conversationId,
        orderId: input.orderId,
        orderItemId: input.orderItemId,
        quantity: input.quantity
      });
      return {
        ticketId: 'CANCEL-MOCK-1001',
        status: 'accepted',
        request: {
          orderId: input.orderId,
          partials: [{ orderItemId: input.orderItemId, quantity: input.quantity }],
          reason: input.reason,
          isCustomerNegligence: true
        }
      };
    }
  });

  return [getOrders, createCancelTicket];
};

export { MOCK_ORDER };
