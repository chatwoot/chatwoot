/* eslint-env browser */
import { useEffect } from '@storybook/addons';
import { drawSelectedElement } from './box-model/visualizer';
import { init, rescale, destroy } from './box-model/canvas';
import { deepElementFromPoint } from './util';
let nodeAtPointerRef;
const pointer = {
  x: 0,
  y: 0
};

function findAndDrawElement(x, y) {
  nodeAtPointerRef = deepElementFromPoint(x, y);
  drawSelectedElement(nodeAtPointerRef);
}

export const withMeasure = (StoryFn, context) => {
  const {
    measureEnabled
  } = context.globals;
  useEffect(() => {
    const onMouseMove = event => {
      window.requestAnimationFrame(() => {
        event.stopPropagation();
        pointer.x = event.clientX;
        pointer.y = event.clientY;
      });
    };

    document.addEventListener('mousemove', onMouseMove);
    return () => {
      document.removeEventListener('mousemove', onMouseMove);
    };
  }, []);
  useEffect(() => {
    const onMouseOver = event => {
      window.requestAnimationFrame(() => {
        event.stopPropagation();
        findAndDrawElement(event.clientX, event.clientY);
      });
    };

    const onResize = () => {
      window.requestAnimationFrame(() => {
        rescale();
      });
    };

    if (measureEnabled) {
      document.addEventListener('mouseover', onMouseOver);
      init();
      window.addEventListener('resize', onResize); // Draw the element below the pointer when first enabled

      findAndDrawElement(pointer.x, pointer.y);
    }

    return () => {
      window.removeEventListener('resize', onResize);
      destroy();
    };
  }, [measureEnabled]);
  return StoryFn();
};