/**
 * Stops propagation of click event and removes event listener
 *
 * @private
 * @param {object} event The click event
 */
function preventClickHandler(event) {
    event.stopPropagation();
    document.body.removeEventListener('click', preventClickHandler, true);
}

/**
 * Starts listening for click event and prevent propagation
 *
 * @param {object} values Values
 */
export default function preventClick(values) {
    document.body.addEventListener('click', preventClickHandler, true);
}
