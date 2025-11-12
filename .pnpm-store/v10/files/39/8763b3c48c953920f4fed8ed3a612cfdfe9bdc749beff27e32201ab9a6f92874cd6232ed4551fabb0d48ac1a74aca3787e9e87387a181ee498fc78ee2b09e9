/**
 * @file middleware.js
 * @since 3.0.0
 */

const WavesurferMiddleware = {
    /**
     * Setup the routing between a specific source and middleware
     * and eventually set the source on the Tech.
     *
     * @param {Tech~SourceObject} [srcObj] - Source object to manipulate.
     * @param {Function} [next] - The next middleware to run.
     */
    setSource(srcObj, next) {
        // check if this player is using the videojs-wavesurfer plugin
        if (this.player.usingPlugin('wavesurfer')) {
            let backend = this.player.wavesurfer().surfer.params.backend;
            let src = srcObj.src;
            let peaks = srcObj.peaks;

            switch (backend) {
                case 'WebAudio':
                    // load url into wavesurfer
                    this.player.wavesurfer().load(src);
                    break;

                default:
                    // load source into video.js
                    next(null, srcObj);

                    // load media element into wavesurfer
                    let element = this.player.tech_.el();
                    if (peaks === undefined) {
                        // element without peaks
                        this.player.wavesurfer().load(element);
                    } else {
                        // element with peaks
                        this.player.wavesurfer().load(element, peaks);
                    }
                    break;
            }
        } else {
            // ignore middleware (this player isn't using the videojs-wavesurfer
            // plugin) and load source into video.js
            next(null, srcObj);
        }
    }
};

export default WavesurferMiddleware;
