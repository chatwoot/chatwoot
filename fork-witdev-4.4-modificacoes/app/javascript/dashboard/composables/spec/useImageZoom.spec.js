import { ref } from 'vue';
import { useImageZoom } from 'dashboard/composables/useImageZoom';

describe('useImageZoom', () => {
  let imageRef;

  beforeEach(() => {
    // Mock imageRef element with getBoundingClientRect method
    imageRef = ref({
      getBoundingClientRect: () => ({
        left: 100,
        top: 100,
        width: 200,
        height: 200,
      }),
    });
  });

  it('should initialize with default values', () => {
    const { zoomScale, imgTransformOriginPoint, activeImageRotation } =
      useImageZoom(imageRef);

    expect(zoomScale.value).toBe(1);
    expect(imgTransformOriginPoint.value).toBe('center center');
    expect(activeImageRotation.value).toBe(0);
  });

  it('should update zoom scale when onZoom is called', () => {
    const { zoomScale, onZoom } = useImageZoom(imageRef);

    onZoom(0.5);
    expect(zoomScale.value).toBe(1.5);

    // Should respect max zoom level
    onZoom(10);
    expect(zoomScale.value).toBe(3);

    // Should respect min zoom level
    onZoom(-10);
    expect(zoomScale.value).toBe(1);
  });

  it('should update rotation when onRotate is called', () => {
    const { activeImageRotation, onRotate } = useImageZoom(imageRef);

    onRotate('clockwise');
    expect(activeImageRotation.value).toBe(90);

    onRotate('counter-clockwise');
    expect(activeImageRotation.value).toBe(0);

    // Test full rotation reset
    onRotate('clockwise');
    onRotate('clockwise');
    onRotate('clockwise');
    onRotate('clockwise');
    onRotate('clockwise');
    // After 360 degrees, it should reset and add the new rotation
    expect(activeImageRotation.value).toBe(90);
  });

  it('should reset zoom and rotation', () => {
    const {
      zoomScale,
      activeImageRotation,
      onZoom,
      onRotate,
      resetZoomAndRotation,
    } = useImageZoom(imageRef);

    onZoom(0.5);
    onRotate('clockwise');
    expect(zoomScale.value).toBe(1); // Rotation resets zoom
    expect(activeImageRotation.value).toBe(90);

    onZoom(0.5);
    expect(zoomScale.value).toBe(1.5);

    resetZoomAndRotation();
    expect(zoomScale.value).toBe(1);
    expect(activeImageRotation.value).toBe(0);
  });

  it('should handle double click zoom', () => {
    const { zoomScale, onDoubleClickZoomImage } = useImageZoom(imageRef);

    // Mock event
    const event = {
      clientX: 150,
      clientY: 150,
      preventDefault: vi.fn(),
    };

    onDoubleClickZoomImage(event);
    expect(zoomScale.value).toBe(3); // Max zoom
    expect(event.preventDefault).toHaveBeenCalled();

    onDoubleClickZoomImage(event);
    expect(zoomScale.value).toBe(1); // Min zoom
  });

  it('should handle wheel zoom', () => {
    const { zoomScale, onWheelImageZoom } = useImageZoom(imageRef);

    // Mock event
    const event = {
      clientX: 150,
      clientY: 150,
      deltaY: -10, // Zoom in
      preventDefault: vi.fn(),
    };

    onWheelImageZoom(event);
    expect(zoomScale.value).toBe(1.2);
    expect(event.preventDefault).toHaveBeenCalled();

    // Zoom out
    event.deltaY = 10;
    onWheelImageZoom(event);
    expect(zoomScale.value).toBe(1);
  });

  it('should correctly compute zoom origin', () => {
    const { getZoomOrigin } = useImageZoom(imageRef);

    // Test center point
    const centerOrigin = getZoomOrigin(200, 200);
    expect(centerOrigin.x).toBeCloseTo(50);
    expect(centerOrigin.y).toBeCloseTo(50);

    // Test top-left corner
    const topLeftOrigin = getZoomOrigin(100, 100);
    expect(topLeftOrigin.x).toBeCloseTo(0);
    expect(topLeftOrigin.y).toBeCloseTo(0);

    // Test bottom-right corner
    const bottomRightOrigin = getZoomOrigin(300, 300);
    expect(bottomRightOrigin.x).toBeCloseTo(100);
    expect(bottomRightOrigin.y).toBeCloseTo(100);
  });
});
