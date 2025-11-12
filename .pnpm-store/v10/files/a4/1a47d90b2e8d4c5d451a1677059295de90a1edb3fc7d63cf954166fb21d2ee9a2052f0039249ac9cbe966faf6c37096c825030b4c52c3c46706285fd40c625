import TransmuxWorker from 'worker!./transmuxer-worker.js';

export const handleData_ = (event, transmuxedData, callback) => {
  const {
    type,
    initSegment,
    captions,
    captionStreams,
    metadata,
    videoFrameDtsTime,
    videoFramePtsTime
  } = event.data.segment;

  transmuxedData.buffer.push({
    captions,
    captionStreams,
    metadata
  });

  const boxes = event.data.segment.boxes || {
    data: event.data.segment.data
  };

  const result = {
    type,
    // cast ArrayBuffer to TypedArray
    data: new Uint8Array(
      boxes.data,
      boxes.data.byteOffset,
      boxes.data.byteLength
    ),
    initSegment: new Uint8Array(
      initSegment.data,
      initSegment.byteOffset,
      initSegment.byteLength
    )
  };

  if (typeof videoFrameDtsTime !== 'undefined') {
    result.videoFrameDtsTime = videoFrameDtsTime;
  }

  if (typeof videoFramePtsTime !== 'undefined') {
    result.videoFramePtsTime = videoFramePtsTime;
  }

  callback(result);
};

export const handleDone_ = ({
  transmuxedData,
  callback
}) => {
  // Previously we only returned data on data events,
  // not on done events. Clear out the buffer to keep that consistent.
  transmuxedData.buffer = [];

  // all buffers should have been flushed from the muxer, so start processing anything we
  // have received
  callback(transmuxedData);
};

export const handleGopInfo_ = (event, transmuxedData) => {
  transmuxedData.gopInfo = event.data.gopInfo;
};

export const processTransmux = (options) => {
  const {
    transmuxer,
    bytes,
    audioAppendStart,
    gopsToAlignWith,
    remux,
    onData,
    onTrackInfo,
    onAudioTimingInfo,
    onVideoTimingInfo,
    onVideoSegmentTimingInfo,
    onAudioSegmentTimingInfo,
    onId3,
    onCaptions,
    onDone,
    onEndedTimeline,
    onTransmuxerLog,
    isEndOfTimeline
  } = options;
  const transmuxedData = {
    buffer: []
  };
  let waitForEndedTimelineEvent = isEndOfTimeline;

  const handleMessage = (event) => {
    if (transmuxer.currentTransmux !== options) {
      // disposed
      return;
    }

    if (event.data.action === 'data') {
      handleData_(event, transmuxedData, onData);
    }
    if (event.data.action === 'trackinfo') {
      onTrackInfo(event.data.trackInfo);
    }
    if (event.data.action === 'gopInfo') {
      handleGopInfo_(event, transmuxedData);
    }
    if (event.data.action === 'audioTimingInfo') {
      onAudioTimingInfo(event.data.audioTimingInfo);
    }
    if (event.data.action === 'videoTimingInfo') {
      onVideoTimingInfo(event.data.videoTimingInfo);
    }
    if (event.data.action === 'videoSegmentTimingInfo') {
      onVideoSegmentTimingInfo(event.data.videoSegmentTimingInfo);
    }
    if (event.data.action === 'audioSegmentTimingInfo') {
      onAudioSegmentTimingInfo(event.data.audioSegmentTimingInfo);
    }
    if (event.data.action === 'id3Frame') {
      onId3([event.data.id3Frame], event.data.id3Frame.dispatchType);
    }
    if (event.data.action === 'caption') {
      onCaptions(event.data.caption);
    }
    if (event.data.action === 'endedtimeline') {
      waitForEndedTimelineEvent = false;
      onEndedTimeline();
    }
    if (event.data.action === 'log') {
      onTransmuxerLog(event.data.log);
    }

    // wait for the transmuxed event since we may have audio and video
    if (event.data.type !== 'transmuxed') {
      return;
    }

    // If the "endedtimeline" event has not yet fired, and this segment represents the end
    // of a timeline, that means there may still be data events before the segment
    // processing can be considerred complete. In that case, the final event should be
    // an "endedtimeline" event with the type "transmuxed."
    if (waitForEndedTimelineEvent) {
      return;
    }

    transmuxer.onmessage = null;
    handleDone_({
      transmuxedData,
      callback: onDone
    });

    /* eslint-disable no-use-before-define */
    dequeue(transmuxer);
    /* eslint-enable */
  };

  transmuxer.onmessage = handleMessage;

  if (audioAppendStart) {
    transmuxer.postMessage({
      action: 'setAudioAppendStart',
      appendStart: audioAppendStart
    });
  }

  // allow empty arrays to be passed to clear out GOPs
  if (Array.isArray(gopsToAlignWith)) {
    transmuxer.postMessage({
      action: 'alignGopsWith',
      gopsToAlignWith
    });
  }

  if (typeof remux !== 'undefined') {
    transmuxer.postMessage({
      action: 'setRemux',
      remux
    });
  }

  if (bytes.byteLength) {
    const buffer = bytes instanceof ArrayBuffer ? bytes : bytes.buffer;
    const byteOffset = bytes instanceof ArrayBuffer ? 0 : bytes.byteOffset;

    transmuxer.postMessage(
      {
        action: 'push',
        // Send the typed-array of data as an ArrayBuffer so that
        // it can be sent as a "Transferable" and avoid the costly
        // memory copy
        data: buffer,
        // To recreate the original typed-array, we need information
        // about what portion of the ArrayBuffer it was a view into
        byteOffset,
        byteLength: bytes.byteLength
      },
      [ buffer ]
    );
  }

  if (isEndOfTimeline) {
    transmuxer.postMessage({ action: 'endTimeline' });
  }
  // even if we didn't push any bytes, we have to make sure we flush in case we reached
  // the end of the segment
  transmuxer.postMessage({ action: 'flush' });
};

export const dequeue = (transmuxer) => {
  transmuxer.currentTransmux = null;
  if (transmuxer.transmuxQueue.length) {
    transmuxer.currentTransmux = transmuxer.transmuxQueue.shift();
    if (typeof transmuxer.currentTransmux === 'function') {
      transmuxer.currentTransmux();
    } else {
      processTransmux(transmuxer.currentTransmux);
    }
  }
};

export const processAction = (transmuxer, action) => {
  transmuxer.postMessage({ action });
  dequeue(transmuxer);
};

export const enqueueAction = (action, transmuxer) => {
  if (!transmuxer.currentTransmux) {
    transmuxer.currentTransmux = action;
    processAction(transmuxer, action);
    return;
  }
  transmuxer.transmuxQueue.push(processAction.bind(null, transmuxer, action));
};

export const reset = (transmuxer) => {
  enqueueAction('reset', transmuxer);
};

export const endTimeline = (transmuxer) => {
  enqueueAction('endTimeline', transmuxer);
};

export const transmux = (options) => {
  if (!options.transmuxer.currentTransmux) {
    options.transmuxer.currentTransmux = options;
    processTransmux(options);
    return;
  }
  options.transmuxer.transmuxQueue.push(options);
};

export const createTransmuxer = (options) => {
  const transmuxer = new TransmuxWorker();

  transmuxer.currentTransmux = null;
  transmuxer.transmuxQueue = [];
  const term = transmuxer.terminate;

  transmuxer.terminate = () => {
    transmuxer.currentTransmux = null;
    transmuxer.transmuxQueue.length = 0;
    return term.call(transmuxer);
  };

  transmuxer.postMessage({action: 'init', options});

  return transmuxer;
};

export default {
  reset,
  endTimeline,
  transmux,
  createTransmuxer
};
