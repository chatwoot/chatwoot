// Batch-relative stagger for <TransitionGroup> enter hooks. Items that enter
// in the same frame get sequential transition delays (the native-app "list
// assembling" effect from Reanimated's LinearTransition.springify()); the
// counter resets on the next frame so later batches restart from zero.
export const useStaggeredEnter = ({ step = 35, cap = 12 } = {}) => {
  let queued = 0;
  let resetScheduled = false;

  const beforeEnter = el => {
    el.style.transitionDelay = `${Math.min(queued, cap) * step}ms`;
    queued += 1;
    if (!resetScheduled) {
      resetScheduled = true;
      requestAnimationFrame(() => {
        queued = 0;
        resetScheduled = false;
      });
    }
  };

  // Clear the delay once entered so FLIP move transitions stay immediate.
  const afterEnter = el => {
    el.style.transitionDelay = '';
  };

  return { beforeEnter, afterEnter, enterCancelled: afterEnter };
};
