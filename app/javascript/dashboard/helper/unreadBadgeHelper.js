/**
 * Renders the unread state of the dashboard on the browser tab:
 * a numbered red badge drawn on top of the favicon and a `(N) ` prefix on the
 * document title.
 *
 * The module keeps no framework dependency so that it can be exercised in
 * isolation (unit tests / a plain HTML harness).
 */

const BADGE_FILL = '#ff382d';
const BADGE_TEXT = '#ffffff';
const MAX_COUNT = 99;
// A 16x16 favicon cannot fit a legible number, so it only gets the dot.
const MIN_SIZE_FOR_NUMBER = 32;

const baseTitle = document.title;
const baseImages = {};

let unreadCount = 0;
let showDot = false;
let renderedSignature = null;
// Rendering a badge waits on an image load, so a newer state can win the race
// while an older one is still pending.
let renderToken = 0;

const faviconLinks = () =>
  Array.from(document.querySelectorAll('link.favicon'));

const sizeOfLink = link => {
  const size = parseInt(link.getAttribute('sizes') || '', 10);
  return Number.isFinite(size) && size > 0 ? size : 32;
};

const countLabel = count => (count > MAX_COUNT ? `${MAX_COUNT}+` : `${count}`);

/**
 * Loads (and caches) the favicon shipped with the app. The link `href` is
 * replaced by a data URL once a badge is drawn, so the original path is the
 * only safe source to draw from.
 */
const loadBaseImage = size =>
  new Promise((resolve, reject) => {
    if (baseImages[size]) {
      resolve(baseImages[size]);
      return;
    }
    const image = new Image();
    image.addEventListener('load', () => {
      baseImages[size] = image;
      resolve(image);
    });
    image.addEventListener('error', reject);
    image.src = `/favicon-${size}x${size}.png`;
  });

const drawBadge = (context, size, count) => {
  const withNumber = count > 0 && size >= MIN_SIZE_FOR_NUMBER;
  const label = withNumber ? countLabel(count) : '';
  const height = withNumber ? size * 0.6 : size * 0.5;
  const radius = height / 2;
  // `99+` needs a smaller face to stay inside the icon.
  const fontSize = Math.round(height * (label.length > 2 ? 0.6 : 0.78));
  const fontStack = '-apple-system, "Helvetica Neue", Arial, sans-serif';

  context.font = `bold ${fontSize}px ${fontStack}`;
  context.textAlign = 'center';
  context.textBaseline = 'middle';

  const inset = size * 0.02;
  const textWidth = withNumber ? context.measureText(label).width : 0;
  const width = Math.min(
    size - inset * 2,
    Math.max(height, textWidth + height * 0.5)
  );
  const right = size - inset;
  const left = right - width;
  const top = inset;
  const centerY = top + radius;

  // Pill shaped badge so that a two digit count still fits inside the icon.
  context.beginPath();
  context.moveTo(left + radius, top);
  context.arcTo(right, top, right, top + height, radius);
  context.arcTo(right, top + height, left, top + height, radius);
  context.arcTo(left, top + height, left, top, radius);
  context.arcTo(left, top, right, top, radius);
  context.closePath();

  // A light outline keeps the badge readable on both light and dark tab strips.
  context.lineWidth = Math.max(1, size * 0.05);
  context.strokeStyle = 'rgba(255, 255, 255, 0.9)';
  context.stroke();
  context.fillStyle = BADGE_FILL;
  context.fill();

  if (!withNumber) return;

  context.fillStyle = BADGE_TEXT;
  context.fillText(label, left + width / 2, centerY + height * 0.04);
};

const renderLink = async (link, token) => {
  const size = sizeOfLink(link);
  const hasBadge = unreadCount > 0 || showDot;
  const count = unreadCount;

  try {
    const baseImage = await loadBaseImage(size);
    if (token !== renderToken) return;

    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const context = canvas.getContext('2d');
    context.drawImage(baseImage, 0, 0, size, size);
    if (hasBadge) drawBadge(context, size, count);
    link.href = canvas.toDataURL('image/png');
  } catch {
    if (token !== renderToken) return;
    // Canvas unavailable or the icon failed to load: fall back to the static
    // badged favicons shipped with the app.
    link.href = hasBadge
      ? `/favicon-badge-${size}x${size}.png`
      : `/favicon-${size}x${size}.png`;
  }
};

const renderFavicons = () => {
  renderToken += 1;
  const token = renderToken;
  faviconLinks().forEach(link => renderLink(link, token));
};

const renderTitle = () => {
  document.title =
    unreadCount > 0 ? `(${countLabel(unreadCount)}) ${baseTitle}` : baseTitle;
};

const render = () => {
  const signature = `${unreadCount}|${showDot}`;
  if (signature === renderedSignature) return;

  // Nothing to badge yet: leave the static favicons the layout shipped with.
  const isUntouchedAndClean =
    renderedSignature === null && unreadCount === 0 && !showDot;
  renderedSignature = signature;
  if (isUntouchedAndClean) return;

  renderTitle();
  renderFavicons();
};

/**
 * Number of unread notifications for the current user. `0` restores the plain
 * favicon and title.
 */
export const setUnreadCount = count => {
  const nextCount = Number.isFinite(count) && count > 0 ? Math.floor(count) : 0;
  unreadCount = nextCount;
  // An exact count is always more useful than the plain dot.
  if (nextCount > 0) showDot = false;
  render();
};

/**
 * Marks the tab as "something happened" without a count. Used by the audio
 * alerts, which fire for conversations that may not create a notification
 * record (e.g. unassigned conversations the user only wants a sound for).
 */
export const showDotOnFavicon = () => {
  if (unreadCount > 0) return;
  showDot = true;
  render();
};

export const clearDotOnFavicon = () => {
  if (!showDot) return;
  showDot = false;
  render();
};
