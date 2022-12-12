/**
 * Gets the width and height of the viewport; used to calculate the right and bottom boundaries of the viewable area.
 * @method getViewportSize
 * @memberof axe.commons.dom
 * @instance
 * @param  {Object}  win The `window` object that should be measured
 * @return {Object}  Object with the `width` and `height` of the viewport
 */
function getViewportSize(win) {
  const doc = win.document;
  const docElement = doc.documentElement;

  if (win.innerWidth) {
    return {
      width: win.innerWidth,
      height: win.innerHeight
    };
  }

  if (docElement) {
    return {
      width: docElement.clientWidth,
      height: docElement.clientHeight
    };
  }

  const body = doc.body;

  return {
    width: body.clientWidth,
    height: body.clientHeight
  };
}

export default getViewportSize;
