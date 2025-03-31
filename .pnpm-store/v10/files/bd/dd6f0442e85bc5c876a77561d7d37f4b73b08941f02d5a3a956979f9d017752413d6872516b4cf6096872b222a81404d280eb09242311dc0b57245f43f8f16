import videojs from 'video.js';

/**
 * The TimelineChangeController acts as a source for segment loaders to listen for and
 * keep track of latest and pending timeline changes. This is useful to ensure proper
 * sync, as each loader may need to make a consideration for what timeline the other
 * loader is on before making changes which could impact the other loader's media.
 *
 * @class TimelineChangeController
 * @extends videojs.EventTarget
 */
export default class TimelineChangeController extends videojs.EventTarget {
  constructor() {
    super();

    this.pendingTimelineChanges_ = {};
    this.lastTimelineChanges_ = {};
  }

  clearPendingTimelineChange(type) {
    this.pendingTimelineChanges_[type] = null;
    this.trigger('pendingtimelinechange');
  }

  pendingTimelineChange({ type, from, to }) {
    if (typeof from === 'number' && typeof to === 'number') {
      this.pendingTimelineChanges_[type] = { type, from, to };
      this.trigger('pendingtimelinechange');
    }
    return this.pendingTimelineChanges_[type];
  }

  lastTimelineChange({ type, from, to }) {
    if (typeof from === 'number' && typeof to === 'number') {
      this.lastTimelineChanges_[type] = { type, from, to };
      delete this.pendingTimelineChanges_[type];
      this.trigger('timelinechange');
    }
    return this.lastTimelineChanges_[type];
  }

  dispose() {
    this.trigger('dispose');
    this.pendingTimelineChanges_ = {};
    this.lastTimelineChanges_ = {};
    this.off();
  }
}
