// Touch gestures for the attachment gallery (Chatwit mobile parity): pinch
// to zoom, horizontal swipe to navigate, swipe down to dismiss. Handlers are
// inert on mouse-only devices, so desktop behavior is untouched.
export const useGalleryTouchGestures = ({
  zoomBy,
  zoomScale,
  next,
  prev,
  close,
}) => {
  let pinchDistance = 0;
  let isPinching = false;
  let startX = 0;
  let startY = 0;
  let tracking = false;

  const touchDistance = touches =>
    Math.hypot(
      touches[0].clientX - touches[1].clientX,
      touches[0].clientY - touches[1].clientY
    );

  const onTouchStart = event => {
    if (event.touches.length === 2) {
      isPinching = true;
      tracking = false;
      pinchDistance = touchDistance(event.touches);
      return;
    }
    if (event.touches.length === 1) {
      isPinching = false;
      tracking = true;
      startX = event.touches[0].clientX;
      startY = event.touches[0].clientY;
    }
  };

  const onTouchMove = event => {
    if (!isPinching || event.touches.length !== 2) return;
    event.preventDefault();
    const distance = touchDistance(event.touches);
    const delta = (distance - pinchDistance) / 250;
    if (Math.abs(delta) >= 0.04) {
      zoomBy(delta);
      pinchDistance = distance;
    }
  };

  const onTouchEnd = event => {
    if (isPinching) {
      isPinching = event.touches.length >= 2;
      return;
    }
    if (!tracking || !event.changedTouches.length) return;
    tracking = false;
    // While zoomed in, the finger is exploring the picture, not navigating.
    if (zoomScale.value > 1) return;
    const deltaX = event.changedTouches[0].clientX - startX;
    const deltaY = event.changedTouches[0].clientY - startY;
    if (Math.abs(deltaX) > 60 && Math.abs(deltaX) > Math.abs(deltaY) * 1.5) {
      if (deltaX < 0) next();
      else prev();
      return;
    }
    if (deltaY > 80 && Math.abs(deltaY) > Math.abs(deltaX) * 1.5) {
      close();
    }
  };

  return { onTouchStart, onTouchMove, onTouchEnd };
};

export default useGalleryTouchGestures;
