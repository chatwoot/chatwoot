import { getMaxUploadSizeByChannel } from '@chatwoot/utils';
import { DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE } from 'shared/helpers/FileHelper';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

export const WHATSAPP_STANDARD_MAX_SIDE = 1600;
export const WHATSAPP_HD_MAX_SIDE = 4096;

const BYTES_PER_MB = 1024 * 1024;
const SAFETY_MARGIN = 0.9;
const OPTIMIZABLE_MIMES = ['image/jpeg', 'image/png'];

// Ladders go from the highest to the lowest step: { maxSide, quality (0..1) }.
const WHATSAPP_STANDARD_LADDER = [
  { maxSide: 1600, quality: 0.85 },
  { maxSide: 1280, quality: 0.8 },
  { maxSide: 1024, quality: 0.75 },
];

const WHATSAPP_HD_LADDER = [
  { maxSide: 4096, quality: 0.92 },
  { maxSide: 4096, quality: 0.85 },
  { maxSide: 3072, quality: 0.9 },
  { maxSide: 3072, quality: 0.82 },
  { maxSide: 2560, quality: 0.88 },
  { maxSide: 2560, quality: 0.8 },
  { maxSide: 2048, quality: 0.85 },
  { maxSide: 2048, quality: 0.78 },
  ...WHATSAPP_STANDARD_LADDER,
];

const FIT_LADDER = [
  { maxSide: 4096, quality: 0.85 },
  { maxSide: 3072, quality: 0.82 },
  { maxSide: 2560, quality: 0.8 },
  { maxSide: 2048, quality: 0.78 },
  { maxSide: 1600, quality: 0.75 },
  { maxSide: 1280, quality: 0.72 },
];

export const getImageOptimizationPolicy = ({
  inbox,
  mime,
  installationLimit,
}) => {
  const channelType = inbox?.channel_type;
  if (!channelType || channelType === INBOX_TYPES.WEB) return null;
  if (!OPTIMIZABLE_MIMES.includes(mime)) return null;

  const channelLimit = getMaxUploadSizeByChannel({
    channelType,
    medium: inbox.medium,
    mime,
  });
  if (channelLimit === DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE) return null;
  if (channelLimit >= installationLimit) return null;

  const limitBytes = channelLimit * BYTES_PER_MB;
  const maxBytes = limitBytes * SAFETY_MARGIN;

  if (channelType === INBOX_TYPES.WHATSAPP) {
    return {
      limitBytes,
      maxBytes,
      supportsHd: true,
      standardMaxSide: WHATSAPP_STANDARD_MAX_SIDE,
      hdMaxSide: WHATSAPP_HD_MAX_SIDE,
      standardLadder: WHATSAPP_STANDARD_LADDER,
      hdLadder: WHATSAPP_HD_LADDER,
    };
  }

  return {
    limitBytes,
    maxBytes,
    supportsHd: false,
    standardMaxSide: null,
    hdMaxSide: null,
    standardLadder: FIT_LADDER,
    hdLadder: null,
  };
};

export const imageNeedsOptimization = (
  policy,
  profile,
  { size, longestSide }
) => {
  if (size > policy.limitBytes) return true;
  return (
    profile === 'standard' &&
    !!policy.standardMaxSide &&
    longestSide != null &&
    longestSide > policy.standardMaxSide
  );
};

export const getImageLadder = (policy, profile) =>
  profile === 'hd' && policy.hdLadder ? policy.hdLadder : policy.standardLadder;
