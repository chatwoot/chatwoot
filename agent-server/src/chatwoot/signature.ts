import { createHmac, timingSafeEqual } from 'node:crypto';

type SignatureHeaders = {
  signature?: string;
  timestamp?: string;
};

const MAX_TIMESTAMP_AGE_SECONDS = 5 * 60;

export const verifyChatwootSignature = (
  rawBody: string,
  headers: SignatureHeaders,
  secret: string,
  nowInSeconds = Math.floor(Date.now() / 1000)
): boolean => {
  if (!headers.signature?.startsWith('sha256=') || !headers.timestamp) return false;

  const timestamp = Number(headers.timestamp);
  if (!Number.isInteger(timestamp)) return false;
  if (Math.abs(nowInSeconds - timestamp) > MAX_TIMESTAMP_AGE_SECONDS) return false;

  const received = Buffer.from(headers.signature.slice('sha256='.length), 'hex');
  const expected = Buffer.from(
    createHmac('sha256', secret).update(`${headers.timestamp}.${rawBody}`).digest('hex'),
    'hex'
  );

  return received.length === expected.length && timingSafeEqual(received, expected);
};
