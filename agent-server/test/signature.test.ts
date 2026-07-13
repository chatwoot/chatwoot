import { createHmac } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import { verifyChatwootSignature } from '../src/chatwoot/signature.js';

describe('verifyChatwootSignature', () => {
  it('accepts a current valid signature', () => {
    const body = '{"event":"message_created"}';
    const secret = 'test-secret';
    const timestamp = '1000';
    const signature = `sha256=${createHmac('sha256', secret)
      .update(`${timestamp}.${body}`)
      .digest('hex')}`;

    expect(verifyChatwootSignature(body, { signature, timestamp }, secret, 1000)).toBe(true);
  });

  it('rejects an old timestamp', () => {
    const body = '{}';
    const secret = 'test-secret';
    const timestamp = '1';
    const signature = `sha256=${createHmac('sha256', secret)
      .update(`${timestamp}.${body}`)
      .digest('hex')}`;

    expect(verifyChatwootSignature(body, { signature, timestamp }, secret, 1000)).toBe(false);
  });
});
