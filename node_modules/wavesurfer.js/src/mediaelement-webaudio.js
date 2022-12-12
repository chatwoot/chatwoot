import MediaElement from './mediaelement';

/**
 * MediaElementWebAudio backend: load audio via an HTML5 audio tag, but playback with the WebAudio API.
 * The advantage here is that the html5 <audio> tag can perform range requests on the server and not
 * buffer the entire file in one request, and you still get the filtering and scripting functionality
 * of the webaudio API.
 * Note that in order to use range requests and prevent buffering, you must provide peak data.
 *
 * @since 3.2.0
 */
export default class MediaElementWebAudio extends MediaElement {
    /**
     * Construct the backend
     *
     * @param {WavesurferParams} params Wavesurfer parameters
     */
    constructor(params) {
        super(params);
        /** @private */
        this.params = params;
        /** @private */
        this.sourceMediaElement = null;
    }

    /**
     * Initialise the backend, called in `wavesurfer.createBackend()`
     */
    init() {
        this.setPlaybackRate(this.params.audioRate);
        this.createTimer();
        this.createVolumeNode();
        this.createScriptNode();
        this.createAnalyserNode();
    }
    /**
     * Private method called by both `load` (from url)
     * and `loadElt` (existing media element) methods.
     *
     * @param {HTMLMediaElement} media HTML5 Audio or Video element
     * @param {number[]|Number.<Array[]>} peaks Array of peak data
     * @param {string} preload HTML 5 preload attribute value
     * @private
     */
    _load(media, peaks, preload) {
        super._load(media, peaks, preload);
        this.createMediaElementSource(media);
    }

    /**
     * Create MediaElementSource node
     *
     * @since 3.2.0
     * @param {HTMLMediaElement} mediaElement HTML5 Audio to load
     */
    createMediaElementSource(mediaElement) {
        this.sourceMediaElement = this.ac.createMediaElementSource(
            mediaElement
        );
        this.sourceMediaElement.connect(this.analyser);
    }

    play(start, end) {
        this.resumeAudioContext();
        return super.play(start, end);
    }

    /**
     * This is called when wavesurfer is destroyed
     *
     */
    destroy() {
        super.destroy();

        this.destroyWebAudio();
    }
}
