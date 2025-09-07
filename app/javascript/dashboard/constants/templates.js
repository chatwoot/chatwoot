/**
 * Template related constants
 */

export const MEDIA_FORMATS = ['IMAGE', 'VIDEO', 'DOCUMENT'];

export const HEADER_FORMATS = [
  { value: 'TEXT', label: 'Text', icon: 'i-lucide-type' },
  { value: 'IMAGE', label: 'Image', icon: 'i-lucide-image' },
  { value: 'VIDEO', label: 'Video', icon: 'i-lucide-video' },
  { value: 'DOCUMENT', label: 'Document', icon: 'i-lucide-file' },
  { value: 'LOCATION', label: 'Location', icon: 'i-lucide-map-pin' },
];

export const UPLOAD_CONFIG = {
  IMAGE: { accept: 'image/jpeg,image/jpg,image/png' },
  VIDEO: { accept: 'video/mp4' },
  DOCUMENT: { accept: 'application/pdf' },
};
