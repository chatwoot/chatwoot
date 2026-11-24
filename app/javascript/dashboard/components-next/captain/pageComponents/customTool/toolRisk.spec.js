import {
  toolRiskScore,
  toolRiskLevel,
  isEmailLikeParam,
  isIdLikeParam,
  RISK_LEVELS,
} from './toolRisk';

const baseTool = {
  title: 'Weather',
  description: 'Current weather for a city',
  endpoint_url: 'https://weather.example.com/now?city={{ city }}',
  http_method: 'GET',
  auth_type: 'none',
  headers: {},
  param_schema: [{ name: 'city', type: 'string', description: 'City name' }],
};

describe('toolRisk', () => {
  it('gives a public lookup no score', () => {
    expect(toolRiskScore(baseTool)).toBe(0);
    expect(toolRiskLevel(baseTool)).toBe(RISK_LEVELS.NONE);
  });

  it('scores a Stripe lookup by email as high', () => {
    const tool = {
      ...baseTool,
      title: 'Find customer by email',
      description: 'Looks up a Stripe customer',
      endpoint_url:
        'https://api.stripe.com/v1/customers/search?query={{ email }}',
      auth_type: 'bearer',
      param_schema: [
        { name: 'email', type: 'string', description: 'Customer email' },
      ],
    };

    expect(toolRiskScore(tool)).toBe(20);
    expect(toolRiskLevel(tool)).toBe(RISK_LEVELS.HIGH);
  });

  it('scores a write with credentials as high', () => {
    const tool = {
      ...baseTool,
      title: 'Create ticket',
      description: 'Opens a ticket',
      http_method: 'POST',
      auth_type: 'api_key',
    };

    expect(toolRiskScore(tool)).toBe(15);
  });

  it('scores a delete more than other writes', () => {
    expect(toolRiskScore({ ...baseTool, http_method: 'DELETE' })).toBe(15);
    expect(toolRiskScore({ ...baseTool, http_method: 'PATCH' })).toBe(10);
  });

  it('scores a lookup with credentials and an ID as medium', () => {
    const tool = {
      ...baseTool,
      title: 'Ticket status',
      description: 'Status of a ticket',
      headers: { 'X-Api-Key': 'secret' },
      param_schema: [
        { name: 'ticket_id', type: 'string', description: 'The ticket' },
      ],
    };

    expect(toolRiskScore(tool)).toBe(10);
    expect(toolRiskLevel(tool)).toBe(RISK_LEVELS.MEDIUM);
  });

  it('counts each signal once', () => {
    const tool = {
      ...baseTool,
      title: 'Billing invoice payment',
      description: 'Billing and invoices',
    };

    expect(toolRiskScore(tool)).toBe(5);
  });

  it('does not count a parameter that Chatwoot fills from the verified email', () => {
    const tool = {
      ...baseTool,
      param_schema: [
        {
          name: 'email',
          type: 'string',
          description: 'Email',
          source: 'verified.email',
        },
      ],
    };

    expect(toolRiskScore(tool)).toBe(0);
  });

  it('recognises email parameters by name or description', () => {
    expect(isEmailLikeParam({ name: 'customer_email' })).toBe(true);
    expect(isEmailLikeParam({ name: 'customerEmail' })).toBe(true);
    expect(isEmailLikeParam({ name: 'e_mail' })).toBe(true);
    expect(
      isEmailLikeParam({
        name: 'address',
        description: 'The email of the customer',
      })
    ).toBe(true);
    expect(isEmailLikeParam({ name: 'city', description: 'City name' })).toBe(
      false
    );
  });

  it('recognises ID parameters by name', () => {
    expect(isIdLikeParam({ name: 'customer_id' })).toBe(true);
    expect(isIdLikeParam({ name: 'orderNumber' })).toBe(true);
    expect(isIdLikeParam({ name: 'city' })).toBe(false);
    expect(isIdLikeParam({ name: 'video' })).toBe(false);
  });
});
