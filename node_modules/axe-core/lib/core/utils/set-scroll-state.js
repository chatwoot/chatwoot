/**
 * set the scroll position of an element
 */
function setScroll(elm, top, left) {
  if (elm === window) {
    return elm.scroll(left, top);
  } else {
    elm.scrollTop = top;
    elm.scrollLeft = left;
  }
}

/**
 * set the scroll position of all items in the scrollState array
 * @deprecated
 */
export function setScrollState(scrollState) {
  scrollState.forEach(({ elm, top, left }) => setScroll(elm, top, left));
}

export default setScrollState;
