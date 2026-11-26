import { buildMessageSchema } from '@chatwoot/prosemirror-schema';
import { getFileInfo, getMaxUploadSizeByChannel } from '@chatwoot/utils';
import { MARKDOWN_PATTERNS } from 'dashboard/constants/editor';
import {
  getEffectiveChannelType,
  getFormattingForEditor,
  stripUnsupportedFormatting,
} from 'dashboard/helper/editorHelper';
import {
  checkFileSizeLimit,
  isFileTypeAllowedForChannel,
} from 'shared/helpers/FileHelper';

export const CHANGE_TYPES = {
  BOLD: 'bold',
  ITALIC: 'italic',
  CODE: 'code',
  STRIKETHROUGH: 'strikethrough',
  QUOTE: 'quote',
  LINK: 'link',
  LIST: 'list',
  IMAGE_MOVED: 'imageMoved',
  IMAGE_BLOCKED: 'imageBlocked',
  FILE_SEPARATE: 'fileSeparate',
  FILE_BLOCKED: 'fileBlocked',
};

const FORMATTING_CHANGES = {
  strong: CHANGE_TYPES.BOLD,
  em: CHANGE_TYPES.ITALIC,
  code: CHANGE_TYPES.CODE,
  codeBlock: CHANGE_TYPES.CODE,
  strike: CHANGE_TYPES.STRIKETHROUGH,
  blockquote: CHANGE_TYPES.QUOTE,
  link: CHANGE_TYPES.LINK,
  bulletList: CHANGE_TYPES.LIST,
  orderedList: CHANGE_TYPES.LIST,
};

const IMAGE_MARKDOWN = /!\[[^\]]*\]\(([^)\s]+)[^)]*\)/g;
// An uploaded image's URL carries the signed id of its blob
const BLOB_URL =
  /\/rails\/active_storage\/blobs\/(?:redirect|proxy)\/([^/]+)\//;

// Shaped like canned response files, so a channel that can't show an image in
// the text can take it as an attachment.
const getInlineImages = content =>
  Array.from(content.matchAll(IMAGE_MARKDOWN), ([, url]) => {
    const { name, type } = getFileInfo(url);
    return {
      signed_id: url.match(BLOB_URL)?.[1],
      filename: name,
      content_type: `image/${type === 'jpg' ? 'jpeg' : type}`,
      file_url: url,
    };
  });

const hasFormatting = (content, type) =>
  MARKDOWN_PATTERNS.find(format => format.type === type).patterns.some(
    ({ pattern }) => content.search(pattern) !== -1
  );

const canSendFile = (file, channel) => {
  if (!file.signed_id) return false;

  const upload = {
    name: file.filename,
    type: file.content_type,
    size: file.byte_size,
  };
  if (!isFileTypeAllowedForChannel(upload, channel)) return false;
  // An image written into the message has no known size
  if (!upload.size) return true;

  const maxSize = getMaxUploadSizeByChannel({ ...channel, mime: upload.type });
  return checkFileSizeLimit(upload, maxSize);
};

export const adaptCannedResponse = ({ content, files = [] }, channel) => {
  const { marks, nodes } = getFormattingForEditor(
    getEffectiveChannelType(channel.channelType, channel.medium)
  );
  const supported = [...marks, ...nodes];
  // Channels that show images in the text also deliver files with the message
  const isRichChannel = supported.includes('image');

  const images = isRichChannel ? [] : getInlineImages(content);
  const sentImages = images.filter(image => canSendFile(image, channel));
  const sentFiles = files.filter(file => canSendFile(file, channel));

  // An image's markdown also reads as a link, so formatting is looked for in
  // the text around the images.
  const text = content.replace(IMAGE_MARKDOWN, '');
  const droppedFormatting = Object.keys(FORMATTING_CHANGES).filter(
    type => !supported.includes(type) && hasFormatting(text, type)
  );
  const changes = Array.from(
    new Set(droppedFormatting.map(type => FORMATTING_CHANGES[type])),
    type => ({ type })
  );

  if (sentImages.length) {
    changes.push({ type: CHANGE_TYPES.IMAGE_MOVED });
  }
  if (sentImages.length < images.length) {
    changes.push({ type: CHANGE_TYPES.IMAGE_BLOCKED });
  }
  if (sentFiles.length && !isRichChannel) {
    changes.push({ type: CHANGE_TYPES.FILE_SEPARATE });
  }
  files
    .filter(file => !sentFiles.includes(file))
    .forEach(file => {
      changes.push({ type: CHANGE_TYPES.FILE_BLOCKED, name: file.filename });
    });

  return {
    content: stripUnsupportedFormatting(
      content,
      buildMessageSchema(marks, nodes)
    ),
    attachments: [...sentImages, ...sentFiles],
    changes,
  };
};
