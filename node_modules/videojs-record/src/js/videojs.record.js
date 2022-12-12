/**
 * @file videojs.record.js
 *
 * The main file for the videojs-record project.
 * MIT license: https://github.com/collab-project/videojs-record/blob/master/LICENSE
 */

import videojs from 'video.js';

import AnimationDisplay from './controls/animation-display';
import RecordCanvas from './controls/record-canvas';
import DeviceButton from './controls/device-button';
import CameraButton from './controls/camera-button';
import RecordToggle from './controls/record-toggle';
import RecordIndicator from './controls/record-indicator';
import PictureInPictureToggle from './controls/picture-in-picture-toggle';

import Event from './event';
import defaultKeyHandler from './hot-keys';
import pluginDefaultOptions from './defaults';
import formatTime from './utils/format-time';
import setSrcObject from './utils/browser-shim';
import compareVersion from './utils/compare-version';
import {detectBrowser} from './utils/detect-browser';

import {getAudioEngine, isAudioPluginActive, getVideoEngine, getConvertEngine} from './engine/engine-loader';
import {IMAGE_ONLY, AUDIO_ONLY, VIDEO_ONLY, AUDIO_VIDEO, AUDIO_SCREEN, ANIMATION, SCREEN_ONLY, getRecorderMode} from './engine/record-mode';

const Plugin = videojs.getPlugin('plugin');
const Player = videojs.getComponent('Player');

const AUTO = 'auto';

/**
 * Record audio/video/images using the Video.js player.
 *
 * @class
 * @augments videojs.Plugin
 */
class Record extends Plugin {
    /**
     * The constructor function for the class.
     *
     * @param {(videojs.Player|Object)} player - video.js Player object.
     * @param {Object} options - Player options.
     */
    constructor(player, options) {
        super(player, options);

        // monkey-patch play (#152)
        Player.prototype.play = function play() {
            let retval = this.techGet_('play');
            // silence errors (unhandled promise from play)
            if (retval !== undefined && typeof retval.then === 'function') {
                retval.then(null, (e) => {});
            }
            return retval;
        };

        // add plugin style
        player.addClass('vjs-record');

        // setup plugin options
        this.loadOptions();

        // (re)set recorder state
        this.resetState();

        // use custom time format for video.js player
        if (options.formatTime && typeof options.formatTime === 'function') {
            // user-supplied formatTime
            this.setFormatTime(options.formatTime);
        } else {
            // plugin's default formatTime
            this.setFormatTime((seconds, guide) => {
                return formatTime(seconds, guide, this.displayMilliseconds);
            });
        }

        // add device button with icon based on type
        let deviceIcon = 'av-perm';
        switch (this.getRecordType()) {
            case IMAGE_ONLY:
            case VIDEO_ONLY:
            case ANIMATION:
                deviceIcon = 'video-perm';
                break;
            case AUDIO_ONLY:
                deviceIcon = 'audio-perm';
                break;
            case SCREEN_ONLY:
                deviceIcon = 'screen-perm';
                break;
            case AUDIO_SCREEN:
                deviceIcon = 'sv-perm';
                break;
        }

        // add custom interface elements
        DeviceButton.prototype.buildCSSClass = () => {
            // use dynamic icon class
            return 'vjs-record vjs-device-button vjs-control vjs-icon-' + deviceIcon;
        };
        player.deviceButton = new DeviceButton(player, options);
        player.addChild(player.deviceButton);

        // add blinking record indicator
        player.recordIndicator = new RecordIndicator(player, options);
        player.recordIndicator.hide();
        player.addChild(player.recordIndicator);

        // add canvas for recording and displaying image
        player.recordCanvas = new RecordCanvas(player, options);
        player.recordCanvas.hide();
        player.addChild(player.recordCanvas);

        // add image for animation display
        player.animationDisplay = new AnimationDisplay(player, options);
        player.animationDisplay.hide();
        player.addChild(player.animationDisplay);

        // add camera button
        player.cameraButton = new CameraButton(player, options);
        player.cameraButton.hide();

        // add record toggle button
        player.recordToggle = new RecordToggle(player, options);
        player.recordToggle.hide();

        // picture-in-picture
        let oldVideoJS = videojs.VERSION === undefined || compareVersion(videojs.VERSION, '7.6.0') === -1;
        if (!('pictureInPictureEnabled' in document)) {
            // no support for picture-in-picture, disable pip
            this.pictureInPicture = false;
        }
        if (this.pictureInPicture === true) {
            if (oldVideoJS) {
                // add picture-in-picture toggle button for older video.js versions
                // in browsers that support PIP
                player.pipToggle = new PictureInPictureToggle(player, options);
                player.pipToggle.hide();
            }
            // define Picture-in-Picture event handlers once
            this.onEnterPiPHandler = this.onEnterPiP.bind(this);
            this.onLeavePiPHandler = this.onLeavePiP.bind(this);
        }

        // exclude custom UI elements
        if (this.player.options_.controlBar) {
            let customUIElements = ['deviceButton', 'recordIndicator',
                'cameraButton', 'recordToggle'];
            if (player.pipToggle) {
                customUIElements.push('pipToggle');
            }

            customUIElements.forEach((element) => {
                if (this.player.options_.controlBar[element] !== undefined) {
                    this.player[element].layoutExclude = true;
                    this.player[element].hide();
                }
            });
        }

        // wait until player ui is ready
        this.player.one(Event.READY, this.setupUI.bind(this));
    }

    /**
     * Setup plugin options.
     *
     * @param {Object} newOptions - Optional new player options.
     */
    loadOptions(newOptions = {}) {
        let recordOptions = videojs.mergeOptions(pluginDefaultOptions,
            this.player.options_.plugins.record, newOptions);

        // record settings
        this.recordImage = recordOptions.image;
        this.recordAudio = recordOptions.audio;
        this.recordVideo = recordOptions.video;
        this.recordAnimation = recordOptions.animation;
        this.recordScreen = recordOptions.screen;
        this.maxLength = recordOptions.maxLength;
        this.maxFileSize = recordOptions.maxFileSize;
        this.displayMilliseconds = recordOptions.displayMilliseconds;
        this.debug = recordOptions.debug;
        this.pictureInPicture = recordOptions.pip;
        this.recordTimeSlice = recordOptions.timeSlice;
        this.autoMuteDevice = recordOptions.autoMuteDevice;
        this.pluginLibraryOptions = recordOptions.pluginLibraryOptions;

        // video/canvas settings
        this.videoFrameWidth = recordOptions.frameWidth;
        this.videoFrameHeight = recordOptions.frameHeight;
        this.videoFrameRate = recordOptions.videoFrameRate;
        this.videoBitRate = recordOptions.videoBitRate;
        this.videoEngine = recordOptions.videoEngine;
        this.videoRecorderType = recordOptions.videoRecorderType;
        this.videoMimeType = recordOptions.videoMimeType;
        this.videoWorkerURL = recordOptions.videoWorkerURL;
        this.videoWebAssemblyURL = recordOptions.videoWebAssemblyURL;

        // convert settings
        this.convertEngine = recordOptions.convertEngine;
        this.convertAuto = recordOptions.convertAuto;
        this.convertWorkerURL = recordOptions.convertWorkerURL;
        this.convertOptions = recordOptions.convertOptions;

        // audio settings
        this.audioEngine = recordOptions.audioEngine;
        this.audioRecorderType = recordOptions.audioRecorderType;
        this.audioWorkerURL = recordOptions.audioWorkerURL;
        this.audioWebAssemblyURL = recordOptions.audioWebAssemblyURL;
        this.audioBufferSize = recordOptions.audioBufferSize;
        this.audioSampleRate = recordOptions.audioSampleRate;
        this.audioBitRate = recordOptions.audioBitRate;
        this.audioChannels = recordOptions.audioChannels;
        this.audioMimeType = recordOptions.audioMimeType;
        this.audioBufferUpdate = recordOptions.audioBufferUpdate;

        // image settings
        this.imageOutputType = recordOptions.imageOutputType;
        this.imageOutputFormat = recordOptions.imageOutputFormat;
        this.imageOutputQuality = recordOptions.imageOutputQuality;

        // animation settings
        this.animationFrameRate = recordOptions.animationFrameRate;
        this.animationQuality = recordOptions.animationQuality;
    }

    /**
     * Player UI is ready.
     * @private
     */
    setupUI() {
        // insert custom controls on left-side of controlbar
        this.player.controlBar.addChild(this.player.cameraButton);
        this.player.controlBar.el().insertBefore(
            this.player.cameraButton.el(),
            this.player.controlBar.el().firstChild);
        this.player.controlBar.el().insertBefore(
            this.player.recordToggle.el(),
            this.player.controlBar.el().firstChild);

        // picture-in-picture
        if (this.pictureInPicture === true) {
            if (this.player.controlBar.pictureInPictureToggle === undefined &&
                this.player.pipToggle !== undefined) {
                // add custom PiP toggle
                this.player.controlBar.addChild(this.player.pipToggle);
            } else if (this.player.controlBar.pictureInPictureToggle !== undefined) {
                // use video.js PiP toggle
                this.player.pipToggle = this.player.controlBar.pictureInPictureToggle;
                this.player.pipToggle.hide();
            }
        } else if (
            this.pictureInPicture === false &&
            this.player.controlBar.pictureInPictureToggle !== undefined) {
            this.player.controlBar.pictureInPictureToggle.hide();
        }

        // get rid of unused controls
        if (this.player.controlBar.remainingTimeDisplay !== undefined) {
            this.player.controlBar.remainingTimeDisplay.el().style.display = 'none';
        }
        if (this.player.controlBar.liveDisplay !== undefined) {
            this.player.controlBar.liveDisplay.el().style.display = 'none';
        }

        // loop feature is never used in this plugin
        this.player.loop(false);

        // tweak player UI based on type
        switch (this.getRecordType()) {
            case AUDIO_ONLY:
                // reference to videojs-wavesurfer plugin
                this.surfer = this.player.wavesurfer();

                // use same time format as this plugin
                this.surfer.setFormatTime(this._formatTime);
                break;

            case IMAGE_ONLY:
            case VIDEO_ONLY:
            case AUDIO_VIDEO:
            case ANIMATION:
            case SCREEN_ONLY:
            case AUDIO_SCREEN:
                // customize controls
                if (this.player.bigPlayButton !== undefined) {
                    this.player.bigPlayButton.hide();
                }

                // 'loadedmetadata' and 'loadstart' events reset the
                // durationDisplay for the first time: prevent this
                this.player.one(Event.LOADEDMETADATA, () => {
                    // display max record time
                    this.setDuration(this.maxLength);
                });
                this.player.one(Event.LOADSTART, () => {
                    // display max record time
                    this.setDuration(this.maxLength);
                });

                // the native controls don't work for this UI so disable
                // them no matter what
                if (this.player.usingNativeControls_ === true) {
                    if (this.player.tech_.el_ !== undefined) {
                        this.player.tech_.el_.controls = false;
                    }
                }

                // clicking or tapping the player video element should not try
                // to start playback
                this.player.removeTechControlsListeners_();

                if (this.player.options_.controls) {
                    // progress control isn't used by this plugin, hide if present
                    if (this.player.controlBar.progressControl !== undefined) {
                        this.player.controlBar.progressControl.hide();
                    }

                    // prevent controlbar fadeout
                    this.player.on(Event.USERINACTIVE, (event) => {
                        this.player.userActive(true);
                    });

                    // videojs automatically hides the controls when no valid 'source'
                    // element is included in the video or audio tag. Don't. Ever again.
                    this.player.controlBar.show();
                    this.player.controlBar.el().style.display = 'flex';
                }
                break;
        }

        // disable time display events that constantly try to reset the current time
        // and duration values
        this.player.off(Event.TIMEUPDATE);
        this.player.off(Event.DURATIONCHANGE);
        this.player.off(Event.LOADEDMETADATA);
        this.player.off(Event.LOADSTART);
        this.player.off(Event.ENDED);

        // display max record time
        this.setDuration(this.maxLength);

        // hot keys
        if (this.player.options_.plugins.record &&
            this.player.options_.plugins.record.hotKeys &&
            (this.player.options_.plugins.record.hotKeys !== false)) {

            let handler = this.player.options_.plugins.record.hotKeys;
            if (handler === true) {
                handler = defaultKeyHandler;
            }
            // enable video.js user action
            this.player.options_.userActions = {
                hotkeys: handler
            };
        }

        // hide play control (if present)
        if (this.player.controlBar.playToggle !== undefined) {
            this.player.controlBar.playToggle.hide();
        }
    }

    /**
     * Indicates whether the plugin is currently recording or not.
     *
     * @return {boolean} Plugin currently recording or not.
     */
    isRecording() {
        return this._recording;
    }

    /**
     * Indicates whether the plugin is currently processing recorded data
     * or not.
     *
     * @return {boolean} Plugin processing or not.
     */
    isProcessing() {
        return this._processing;
    }

    /**
     * Indicates whether the plugin is destroyed or not.
     *
     * @return {boolean} Plugin destroyed or not.
     */
    isDestroyed() {
        let destroyed = (this.player === null);
        if (destroyed === false) {
            destroyed = (this.player.children() === null);
        }
        return destroyed;
    }

    /**
     * Open the browser's recording device selection dialog and start the
     * device.
     */
    getDevice() {
        // define device callbacks once
        if (this.deviceReadyCallback === undefined) {
            this.deviceReadyCallback = this.onDeviceReady.bind(this);
        }
        if (this.deviceErrorCallback === undefined) {
            this.deviceErrorCallback = this.onDeviceError.bind(this);
        }
        if (this.engineStopCallback === undefined) {
            this.engineStopCallback = this.onRecordComplete.bind(this);
        }
        if (this.streamVisibleCallback === undefined) {
            this.streamVisibleCallback = this.onStreamVisible.bind(this);
        }

        // check for support because some browsers still do not support
        // getDisplayMedia or getUserMedia (like Chrome iOS, see:
        // https://bugs.chromium.org/p/chromium/issues/detail?id=752458)
        if (this.getRecordType() === SCREEN_ONLY || this.getRecordType() === AUDIO_SCREEN) {
            if (navigator.mediaDevices === undefined ||
                navigator.mediaDevices.getDisplayMedia === undefined) {
                this.player.trigger(Event.ERROR,
                    'This browser does not support navigator.mediaDevices.getDisplayMedia');
                return;
            }
        } else {
            if (navigator.mediaDevices === undefined ||
                navigator.mediaDevices.getUserMedia === undefined) {
                this.player.trigger(Event.ERROR,
                    'This browser does not support navigator.mediaDevices.getUserMedia');
                return;
            }
        }

        // ask the browser to give the user access to the media device
        // and get a stream reference in the callback function
        switch (this.getRecordType()) {
            case AUDIO_ONLY:
                // setup microphone
                this.mediaType = {
                    audio: (this.audioRecorderType === AUTO) ? true : this.audioRecorderType,
                    video: false
                };
                // remove existing microphone listeners
                this.surfer.surfer.microphone.un(Event.DEVICE_READY,
                    this.deviceReadyCallback);
                this.surfer.surfer.microphone.un(Event.DEVICE_ERROR,
                    this.deviceErrorCallback);

                // setup new microphone listeners
                this.surfer.surfer.microphone.on(Event.DEVICE_READY,
                    this.deviceReadyCallback);
                this.surfer.surfer.microphone.on(Event.DEVICE_ERROR,
                    this.deviceErrorCallback);

                // disable existing playback events
                this.surfer.setupPlaybackEvents(false);

                // (re)set surfer liveMode
                this.surfer.liveMode = true;
                this.surfer.surfer.microphone.paused = false;

                // resume AudioContext when it's suspended by the browser, due to
                // autoplay rules. Chrome warns with the following message:
                // "The AudioContext was not allowed to start. It must be resumed
                // (or created) after a user gesture on the page."
                if (this.surfer.surfer.backend.ac.state === 'suspended') {
                    this.surfer.surfer.backend.ac.resume();
                }

                // assign custom reloadBufferFunction for microphone plugin to
                // obtain AudioBuffer chunks
                if (this.audioBufferUpdate === true) {
                    this.surfer.surfer.microphone.reloadBufferFunction = (event) => {
                        if (!this.surfer.surfer.microphone.paused) {
                            // redraw
                            this.surfer.surfer.empty();
                            this.surfer.surfer.loadDecodedBuffer(event.inputBuffer);

                            // store data and notify others
                            this.player.recordedData = event.inputBuffer;
                            this.player.trigger(Event.AUDIO_BUFFER_UPDATE);
                        }
                    };
                }
                // open browser device selection/permissions dialog
                this.surfer.surfer.microphone.start();
                break;

            case IMAGE_ONLY:
            case VIDEO_ONLY:
                if (this.getRecordType() === IMAGE_ONLY) {
                    // using player.el() here because this.mediaElement is not available yet
                    this.player.el().firstChild.addEventListener(Event.PLAYING,
                        this.streamVisibleCallback);
                }

                // setup camera
                this.mediaType = {
                    audio: false,
                    video: (this.videoRecorderType === AUTO) ? true : this.videoRecorderType
                };
                navigator.mediaDevices.getUserMedia({
                    audio: false,
                    video: (this.getRecordType() === IMAGE_ONLY) ? this.recordImage : this.recordVideo
                }).then(
                    this.onDeviceReady.bind(this)
                ).catch(
                    this.onDeviceError.bind(this)
                );
                break;

            case AUDIO_SCREEN:
                // setup camera and microphone
                this.mediaType = {
                    audio: (this.audioRecorderType === AUTO) ? true : this.audioRecorderType,
                    video: (this.videoRecorderType === AUTO) ? true : this.videoRecorderType
                };
                let audioScreenConstraints = {};
                if (this.recordScreen === true) {
                    audioScreenConstraints = {
                        video: true // needs to be true for it to work in Firefox
                    };
                } else if (typeof this.recordScreen === 'object' &&
                    this.recordScreen.constructor === Object) {
                    audioScreenConstraints = this.recordScreen;
                }
                navigator.mediaDevices.getDisplayMedia(audioScreenConstraints).then(screenStream => {
                    navigator.mediaDevices.getUserMedia({
                        audio: this.recordAudio
                    }).then((mic) => {
                        // join microphone track with screencast stream (order matters)
                        screenStream.addTrack(mic.getTracks()[0]);
                        this.onDeviceReady.bind(this)(screenStream);
                    }).catch((code) => {
                        // here the screen sharing is in progress as successful result of navigator.mediaDevices.getDisplayMedia and
                        // needs to be stopped because microphone permissions are not acquired by navigator.mediaDevices.getUserMedia
                        if (screenStream.active) {
                            screenStream.stop();
                        }
                        this.onDeviceError(code);
                    });
                }).catch(
                    this.onDeviceError.bind(this)
                );
                break;

            case AUDIO_VIDEO:
                // setup camera and microphone
                this.mediaType = {
                    audio: (this.audioRecorderType === AUTO) ? true : this.audioRecorderType,
                    video: (this.videoRecorderType === AUTO) ? true : this.videoRecorderType
                };
                navigator.mediaDevices.getUserMedia({
                    audio: this.recordAudio,
                    video: this.recordVideo
                }).then(
                    this.onDeviceReady.bind(this)
                ).catch(
                    this.onDeviceError.bind(this)
                );
                break;

            case ANIMATION:
                // setup camera
                this.mediaType = {
                    // animated GIF
                    audio: false,
                    video: false,
                    gif: true
                };
                navigator.mediaDevices.getUserMedia({
                    audio: false,
                    video: this.recordAnimation
                }).then(
                    this.onDeviceReady.bind(this)
                ).catch(
                    this.onDeviceError.bind(this)
                );
                break;

            case SCREEN_ONLY:
                // setup screen
                this.mediaType = {
                    // screen capture
                    audio: false,
                    video: false,
                    screen: true,
                    gif: false
                };
                let screenOnlyConstraints = {};
                if (this.recordScreen === true) {
                    screenOnlyConstraints = {
                        video: true
                    };
                } else if (typeof this.recordScreen === 'object' &&
                    this.recordScreen.constructor === Object) {
                    screenOnlyConstraints = this.recordScreen;
                }
                navigator.mediaDevices.getDisplayMedia(screenOnlyConstraints).then(
                    this.onDeviceReady.bind(this)
                ).catch(
                    this.onDeviceError.bind(this)
                );
                break;
        }
    }

    /**
     * Invoked when the device is ready.
     *
     * @private
     * @param {LocalMediaStream} stream - Local media stream from device.
     */
    onDeviceReady(stream) {
        this._deviceActive = true;

        // stop previous stream if it is active
        if (this.stream !== undefined && this.stream.active) {
            this.stream.stop();
        }

        // store reference to stream for stopping etc.
        this.stream = stream;

        // hide device selection button
        this.player.deviceButton.hide();

        // reset time (e.g. when stopDevice was used)
        this.setDuration(this.maxLength);
        this.setCurrentTime(0);

        // hide play/pause control (e.g. when stopDevice was used)
        if (this.player.controlBar.playToggle !== undefined) {
            this.player.controlBar.playToggle.hide();
        }

        // reset playback listeners
        this.off(this.player, Event.TIMEUPDATE, this.playbackTimeUpdate);
        this.off(this.player, Event.ENDED, this.playbackTimeUpdate);

        // setup recording engine
        if (this.getRecordType() !== IMAGE_ONLY) {
            // currently record plugins are only supported in audio-only mode
            if (this.getRecordType() !== AUDIO_ONLY && isAudioPluginActive(this.audioEngine)) {
                throw new Error('Currently ' + this.audioEngine +
                    ' is only supported in audio-only mode.');
            }

            // load plugins, if any
            let EngineClass, engineType;
            switch (this.getRecordType()) {
                case AUDIO_ONLY:
                    // get audio plugin engine class (or default recordrtc engine)
                    EngineClass = getAudioEngine(this.audioEngine);
                    engineType = this.audioEngine;
                    break;

                default:
                    // get video plugin engine class (or default recordrtc engine)
                    EngineClass = getVideoEngine(this.videoEngine);
                    engineType = this.videoEngine;
            }

            // create recording engine
            try {
                // connect stream to recording engine
                this.engine = new EngineClass(this.player, this.player.options_);
            } catch (err) {
                throw new Error('Could not load ' + engineType + ' plugin');
            }

            // listen for events
            this.engine.on(Event.RECORD_COMPLETE, this.engineStopCallback);

            // audio settings
            this.engine.bufferSize = this.audioBufferSize;
            this.engine.sampleRate = this.audioSampleRate;
            this.engine.bitRate = this.audioBitRate;
            this.engine.audioChannels = this.audioChannels;
            this.engine.audioWorkerURL = this.audioWorkerURL;
            this.engine.audioWebAssemblyURL = this.audioWebAssemblyURL;

            // mime type
            this.engine.mimeType = {
                video: this.videoMimeType,
                gif: 'image/gif'
            };
            if (this.audioMimeType !== null &&
                this.audioMimeType !== AUTO) {
                this.engine.mimeType.audio = this.audioMimeType;
            }

            // video/canvas settings
            this.engine.videoWorkerURL = this.videoWorkerURL;
            this.engine.videoWebAssemblyURL = this.videoWebAssemblyURL;
            this.engine.videoBitRate = this.videoBitRate;
            this.engine.videoFrameRate = this.videoFrameRate;
            this.engine.video = {
                width: this.videoFrameWidth,
                height: this.videoFrameHeight
            };
            this.engine.canvas = {
                width: this.videoFrameWidth,
                height: this.videoFrameHeight
            };

            // animated GIF settings
            this.engine.quality = this.animationQuality;
            this.engine.frameRate = this.animationFrameRate;

            // timeSlice
            if (this.recordTimeSlice && this.recordTimeSlice > 0) {
                this.engine.timeSlice = this.recordTimeSlice;
                this.engine.maxFileSize = this.maxFileSize;
            }

            // additional 3rd-party library options
            this.engine.pluginLibraryOptions = this.pluginLibraryOptions;

            // initialize recorder
            this.engine.setup(this.stream, this.mediaType, this.debug);

            // create converter engine
            if (this.convertEngine !== '') {
                let ConvertEngineClass = getConvertEngine(this.convertEngine);
                try {
                    this.converter = new ConvertEngineClass(this.player,
                        this.player.options_);
                }
                catch (err) {
                    throw new Error('Could not load ' + this.convertEngine +
                        ' plugin');
                }

                // convert settings
                this.converter.convertAuto = this.convertAuto;
                this.converter.convertWorkerURL = this.convertWorkerURL;
                this.converter.convertOptions = this.convertOptions;
                this.converter.pluginLibraryOptions = this.pluginLibraryOptions;

                // initialize converter
                this.converter.setup(this.mediaType, this.debug);
            }

            // show elements that should never be hidden in animation,
            // audio and/or video modus
            let uiElements = ['currentTimeDisplay', 'timeDivider', 'durationDisplay'];
            uiElements.forEach((element) => {
                element = this.player.controlBar[element];
                if (element !== undefined) {
                    element.el().style.display = 'block';
                    element.show();
                }
            });

            // show record button
            this.player.recordToggle.show();
        } else {
            // disable record indicator
            this.player.recordIndicator.disable();

            // setup UI for retrying snapshot (e.g. when stopDevice was
            // used)
            this.retrySnapshot();

            // camera button will be displayed as soon as this.onStreamVisible fires
        }

        // setup preview
        if (this.getRecordType() !== AUDIO_ONLY) {
            // show live preview
            this.mediaElement = this.player.el().firstChild;
            this.mediaElement.controls = false;

            // mute incoming audio for feedback loops
            this.mediaElement.muted = true;

            // hide the volume bar while it's muted
            this.displayVolumeControl(false);

            // picture-in-picture
            if (this.pictureInPicture === true) {
                // show button
                this.player.pipToggle.show();

                // listen to and forward Picture-in-Picture events
                this.mediaElement.removeEventListener(Event.ENTERPICTUREINPICTURE,
                    this.onEnterPiPHandler);
                this.mediaElement.removeEventListener(Event.LEAVEPICTUREINPICTURE,
                    this.onLeavePiPHandler);
                this.mediaElement.addEventListener(Event.ENTERPICTUREINPICTURE,
                    this.onEnterPiPHandler);
                this.mediaElement.addEventListener(Event.LEAVEPICTUREINPICTURE,
                    this.onLeavePiPHandler);
            }
            // load stream
            this.load(this.stream);

            // stream loading is async, so we wait until it's ready to play
            // the stream
            this.player.one(Event.LOADEDMETADATA, () => {
                // start stream
                this.mediaElement.play();

                // forward to listeners
                this.player.trigger(Event.DEVICE_READY);
            });
        } else {
            // forward to listeners
            this.player.trigger(Event.DEVICE_READY);
        }
    }

    /**
     * Invoked when an device error occurred.
     *
     * @private
     * @param {(string|number)} code - Error code/description.
     */
    onDeviceError(code) {
        this._deviceActive = false;

        if (!this.isDestroyed()) {
            // store code
            this.player.deviceErrorCode = code;

            // forward error to player
            this.player.trigger(Event.DEVICE_ERROR);
        }
    }

    /**
     * Start recording.
     */
    start() {
        if (!this.isProcessing()) {
            // check if user didn't revoke permissions after a previous recording
            if (this.stream && this.stream.active === false) {
                // ask for permissions again
                this.getDevice();
                return;
            }
            this._recording = true;

            // hide play/pause control
            if (this.player.controlBar.playToggle !== undefined) {
                this.player.controlBar.playToggle.hide();
            }

            // reset playback listeners
            this.off(this.player, Event.TIMEUPDATE, this.playbackTimeUpdate);
            this.off(this.player, Event.ENDED, this.playbackTimeUpdate);

            // start preview
            switch (this.getRecordType()) {
                case AUDIO_ONLY:
                    // disable playback events
                    this.surfer.setupPlaybackEvents(false);

                    // start/resume live audio visualization
                    this.surfer.surfer.microphone.paused = false;
                    this.surfer.liveMode = true;
                    this.surfer.surfer.microphone.play();
                    break;

                case VIDEO_ONLY:
                case AUDIO_VIDEO:
                case AUDIO_SCREEN:
                case SCREEN_ONLY:
                    // preview video stream in video element
                    this.startVideoPreview();
                    break;

                case ANIMATION:
                    // hide the first frame
                    this.player.recordCanvas.hide();

                    // hide the animation
                    this.player.animationDisplay.hide();

                    // show preview video
                    this.mediaElement.style.display = 'block';

                    // for animations, capture the first frame
                    // that can be displayed as soon as recording
                    // is complete
                    this.captureFrame().then((result) => {
                        // start video preview **after** capturing first frame
                        this.startVideoPreview();
                    });
                    break;
            }

            if (this.autoMuteDevice) {
                // unmute device
                this.muteTracks(false);
            }

            // start recording
            switch (this.getRecordType()) {
                case IMAGE_ONLY:
                    // create snapshot
                    this.createSnapshot();

                    // notify UI
                    this.player.trigger(Event.START_RECORD);
                    break;

                case VIDEO_ONLY:
                case AUDIO_VIDEO:
                case AUDIO_SCREEN:
                case ANIMATION:
                case SCREEN_ONLY:
                    // wait for media stream on video element to actually load
                    this.player.one(Event.LOADEDMETADATA, () => {
                        // start actually recording process
                        this.startRecording();
                    });
                    break;

                default:
                    // all resources have already loaded, so we can start
                    // recording right away
                    this.startRecording();
            }
        }
    }

    /**
     * Start recording.
     * @private
     */
    startRecording() {
        // register starting point
        this.paused = false;
        this.pauseTime = this.pausedTime = 0;
        this.startTime = performance.now();

        // start countdown
        const COUNTDOWN_SPEED = 100; // ms
        this.countDown = this.player.setInterval(
            this.onCountDown.bind(this), COUNTDOWN_SPEED);

        // cleanup previous recording
        if (this.engine !== undefined) {
            this.engine.dispose();
        }

        // start recording stream
        this.engine.start();

        // notify UI
        this.player.trigger(Event.START_RECORD);
    }

    /**
     * Stop recording.
     */
    stop() {
        if (!this.isProcessing()) {
            this._recording = false;
            this._processing = true;

            if (this.getRecordType() !== IMAGE_ONLY) {
                // notify UI
                this.player.trigger(Event.STOP_RECORD);

                // stop countdown
                this.player.clearInterval(this.countDown);

                // stop recording stream (result will be available async)
                if (this.engine) {
                    this.engine.stop();
                }

                if (this.autoMuteDevice) {
                    // mute device
                    this.muteTracks(true);
                }
            } else {
                if (this.player.recordedData) {
                    // notify listeners that image data is (already) available
                    this.player.trigger(Event.FINISH_RECORD);
                }
            }
        }
    }

    /**
     * Stop device(s) and recording if active.
     */
    stopDevice() {
        if (this.isRecording()) {
            // stop stream once recorded data is available,
            // otherwise it'll break recording
            this.player.one(Event.FINISH_RECORD, this.stopStream.bind(this));

            // stop recording
            this.stop();
        } else {
            // stop stream now, since there's no recorded data available
            this.stopStream();
        }
    }

    /**
     * Stop stream and device.
     */
    stopStream() {
        // stop stream and device
        if (this.stream) {
            this._deviceActive = false;

            if (this.getRecordType() === AUDIO_ONLY) {
                // make the microphone plugin stop it's device
                this.surfer.surfer.microphone.stopDevice();
                return;
            }
            this.stream.getTracks().forEach((stream) => {
                stream.stop();
            });
        }
    }

    /**
     * Pause recording.
     */
    pause() {
        if (!this.paused) {
            this.pauseTime = performance.now();
            this.paused = true;

            this.engine.pause();
        }
    }

    /**
     * Resume recording.
     */
    resume() {
        if (this.paused) {
            this.pausedTime += performance.now() - this.pauseTime;

            this.engine.resume();
            this.paused = false;
        }
    }

    /**
     * Invoked when recording completed and the resulting stream is
     * available.
     * @private
     */
    onRecordComplete() {
        // store reference to recorded stream data
        this.player.recordedData = this.engine.recordedData;

        // change the replay button back to a play button
        if (this.player.controlBar.playToggle !== undefined) {
            this.player.controlBar.playToggle.removeClass('vjs-ended');
            this.player.controlBar.playToggle.show();
        }

        // start converter
        if (this.convertAuto === true) {
            this.convert();
        }

        // notify listeners that data is available
        this.player.trigger(Event.FINISH_RECORD);

        // skip loading when player is destroyed after finishRecord event
        if (this.isDestroyed()) {
            return;
        }

        // load and display recorded data
        switch (this.getRecordType()) {
            case AUDIO_ONLY:
                // pause player so user can start playback
                this.surfer.pause();

                // setup events for playback
                this.surfer.setupPlaybackEvents(true);

                // display loader
                this.player.loadingSpinner.show();

                // restore interaction with controls after waveform
                // rendering is complete
                this.surfer.surfer.once(Event.READY, () => {
                    this._processing = false;
                });

                // visualize recorded stream
                this.load(this.player.recordedData);
                break;

            case VIDEO_ONLY:
            case AUDIO_VIDEO:
            case AUDIO_SCREEN:
            case SCREEN_ONLY:
                // pausing the player so we can visualize the recorded data
                // will trigger an async video.js 'pause' event that we
                // have to wait for.
                this.player.one(Event.PAUSE, () => {
                    // video data is ready
                    this._processing = false;

                    // hide loader
                    this.player.loadingSpinner.hide();

                    // show stream total duration
                    this.setDuration(this.streamDuration);

                    // update time during playback and at end
                    this.on(this.player, Event.TIMEUPDATE,
                        this.playbackTimeUpdate);
                    this.on(this.player, Event.ENDED,
                        this.playbackTimeUpdate);

                    // unmute local audio during playback
                    if (this.getRecordType() === AUDIO_VIDEO || this.getRecordType() === AUDIO_SCREEN) {
                        this.mediaElement.muted = false;

                        // show the volume bar when it's unmuted
                        this.displayVolumeControl(true);
                    }

                    // load recorded media
                    this.load(this.player.recordedData);
                });

                // pause player so user can start playback
                this.player.pause();
                break;

            case ANIMATION:
                // animation data is ready
                this._processing = false;

                // hide loader
                this.player.loadingSpinner.hide();

                // show animation total duration
                this.setDuration(this.streamDuration);

                // hide preview video
                this.mediaElement.style.display = 'none';

                // show the first frame
                this.player.recordCanvas.show();

                // pause player so user can start playback
                this.player.pause();

                // show animation on play
                this.on(this.player, Event.PLAY, this.showAnimation);

                // hide animation on pause
                this.on(this.player, Event.PAUSE, this.hideAnimation);
                break;
        }
    }

    /**
     * Invoked during recording and displays the remaining time.
     * @private
     */
    onCountDown() {
        if (!this.paused) {
            let now = performance.now();
            let duration = this.maxLength;
            let currentTime = (now - (this.startTime +
                this.pausedTime)) / 1000; // buddy ignore:line

            this.streamDuration = currentTime;

            if (currentTime >= duration) {
                // at the end
                currentTime = duration;

                // stop recording
                this.stop();
            }

            // update duration
            this.setDuration(duration);

            // update current time
            this.setCurrentTime(currentTime, duration);

            // notify listeners
            this.player.trigger(Event.PROGRESS_RECORD);
        }
    }

    /**
     * Get the current time of the recorded stream during playback.
     *
     * Returns 0 if no recording is available (yet).
     *
     * @returns {float} Current time of the recorded stream.
     */
    getCurrentTime() {
        let currentTime = isNaN(this.streamCurrentTime) ? 0 : this.streamCurrentTime;

        if (this.getRecordType() === AUDIO_ONLY) {
            currentTime = this.surfer.getCurrentTime();
        }

        return currentTime;
    }

    /**
     * Updates the player's element displaying the current time.
     *
     * @private
     * @param {number} [currentTime=0] - Current position of the
     *    playhead (in seconds).
     * @param {number} [duration=0] - Duration in seconds.
     */
    setCurrentTime(currentTime, duration) {
        currentTime = isNaN(currentTime) ? 0 : currentTime;
        duration = isNaN(duration) ? 0 : duration;

        switch (this.getRecordType()) {
            case AUDIO_ONLY:
                this.surfer.setCurrentTime(currentTime, duration);
                break;

            case VIDEO_ONLY:
            case AUDIO_VIDEO:
            case AUDIO_SCREEN:
            case ANIMATION:
            case SCREEN_ONLY:
                if (this.player.controlBar.currentTimeDisplay &&
                    this.player.controlBar.currentTimeDisplay.contentEl() &&
                    this.player.controlBar.currentTimeDisplay.contentEl().lastChild) {
                    this.streamCurrentTime = Math.min(currentTime, duration);

                    // update current time display component
                    this.player.controlBar.currentTimeDisplay.formattedTime_ =
                        this.player.controlBar.currentTimeDisplay.contentEl().lastChild.textContent =
                            this._formatTime(this.streamCurrentTime, duration, this.displayMilliseconds);
                }
                break;
        }
    }

    /**
     * Get the length of the recorded stream in seconds.
     *
     * Returns 0 if no recording is available (yet).
     *
     * @returns {float} Duration of the recorded stream.
     */
    getDuration() {
        let duration = isNaN(this.streamDuration) ? 0 : this.streamDuration;

        return duration;
    }

    /**
     * Updates the player's element displaying the duration time.
     *
     * @param {number} [duration=0] - Duration in seconds.
     * @private
     */
    setDuration(duration) {
        duration = isNaN(duration) ? 0 : duration;

        switch (this.getRecordType()) {
            case AUDIO_ONLY:
                this.surfer.setDuration(duration);
                break;

            case VIDEO_ONLY:
            case AUDIO_VIDEO:
            case AUDIO_SCREEN:
            case ANIMATION:
            case SCREEN_ONLY:
                // update duration display component
                if (this.player.controlBar.durationDisplay &&
                    this.player.controlBar.durationDisplay.contentEl() &&
                    this.player.controlBar.durationDisplay.contentEl().lastChild) {
                    this.player.controlBar.durationDisplay.formattedTime_ =
                    this.player.controlBar.durationDisplay.contentEl().lastChild.textContent =
                        this._formatTime(duration, duration, this.displayMilliseconds);
                }
                break;
        }
    }

    /**
     * Start loading data.
     *
     * @param {(string|blob|file)} url - Either the URL of the media file,
     *     a Blob, a File object or MediaStream.
     */
    load(url) {
        switch (this.getRecordType()) {
            case AUDIO_ONLY:
                // visualize recorded Blob stream
                this.surfer.load(url);
                break;

            case IMAGE_ONLY:
            case VIDEO_ONLY:
            case AUDIO_VIDEO:
            case AUDIO_SCREEN:
            case ANIMATION:
            case SCREEN_ONLY:
                if (url instanceof Blob || url instanceof File) {
                    // make sure to reset it (#312)
                    this.mediaElement.srcObject = null;
                    // assign blob using createObjectURL
                    this.mediaElement.src = URL.createObjectURL(url);
                } else {
                    // assign stream with srcObject
                    setSrcObject(url, this.mediaElement);
                }
                break;
        }
    }

    /**
     * Show save as dialog in browser so the user can store the recorded or
     * converted media locally.
     *
     * @param {Object} name - Object with names for the particular blob(s)
     *     you want to save. File extensions are added automatically. For
     *     example: {'video': 'name-of-video-file'}. Supported keys are
     *     'audio', 'video' and 'gif'.
     * @param {String} type - Type of media to save. Legal values are 'record'
     *     (default) and 'convert'.
     * @example
     * // save recorded video file as 'foo.webm'
     * player.record().saveAs({'video': 'foo'});
     *
     * // save converted video file as 'bar.mp4'
     * player.record().saveAs({'video': 'bar'}, 'convert');
     * @returns {void}
     */
    saveAs(name, type = 'record') {
        if (type === 'record') {
            if (this.engine && name !== undefined) {
                this.engine.saveAs(name);
            }
        } else if (type === 'convert') {
            if (this.converter && name !== undefined) {
                this.converter.saveAs(name);
            }
        }
    }

    /**
     * Destroy plugin only.
     *
     * Use [destroy]{@link Record#destroy} to remove the plugin and the player
     * as well.
     */
    dispose() {
        // disable common event listeners
        this.player.off(Event.READY);
        this.player.off(Event.USERINACTIVE);
        this.player.off(Event.LOADEDMETADATA);

        // prevent callbacks if recording is in progress
        if (this.engine) {
            this.engine.dispose();
            this.engine.destroy();
            this.engine.off(Event.RECORD_COMPLETE, this.engineStopCallback);
        }

        // stop recording and device
        this.stop();
        this.stopDevice();

        // garbage collect recording
        this.removeRecording();

        // stop countdown
        this.player.clearInterval(this.countDown);

        // dispose wavesurfer.js
        if (this.getRecordType() === AUDIO_ONLY) {
            if (this.surfer) {
                // also disposes player
                this.surfer.destroy();
            }
        } else if (this.getRecordType() === IMAGE_ONLY) {
            if (this.mediaElement && this.streamVisibleCallback) {
                // cleanup listeners
                this.mediaElement.removeEventListener(Event.PLAYING,
                    this.streamVisibleCallback);
            }
        }

        this.resetState();

        super.dispose();
    }

    /**
     * Destroy plugin and players and cleanup resources.
     */
    destroy() {
        this.player.dispose();
    }

    /**
     * Reset the plugin.
     */
    reset() {
        // prevent callbacks if recording is in progress
        if (this.engine) {
            this.engine.dispose();
            this.engine.off(Event.RECORD_COMPLETE, this.engineStopCallback);
        }

        // stop recording and device
        this.stop();
        this.stopDevice();

        // stop countdown
        this.player.clearInterval(this.countDown);

        // garbage collect recording
        this.removeRecording();

        // reset options
        this.loadOptions();

        // reset recorder state
        this.resetState();

        // reset record time
        this.setDuration(this.maxLength);
        this.setCurrentTime(0);

        // reset player
        this.player.reset();
        switch (this.getRecordType()) {
            case AUDIO_ONLY:
                if (this.surfer && this.surfer.surfer) {
                    // empty last frame
                    this.surfer.surfer.empty();
                }
                break;

            case IMAGE_ONLY:
            case ANIMATION:
                // reset UI
                this.player.recordCanvas.hide();
                this.player.cameraButton.hide();
                break;
        }

        // hide play control
        if (this.player.controlBar.playToggle !== undefined) {
            this.player.controlBar.playToggle.hide();
        }

        // show device selection button
        this.player.deviceButton.show();

        // hide record button
        this.player.recordToggle.hide();

        // loadedmetadata resets the durationDisplay for the
        // first time
        this.player.one(Event.LOADEDMETADATA, () => {
            // display max record time
            this.setDuration(this.maxLength);
        });
    }

    /**
     * Reset the plugin recorder state.
     * @private
     */
    resetState() {
        this._recording = false;
        this._processing = false;
        this._deviceActive = false;
        this.devices = [];
    }

    /**
     * Removes recorded `Blob` from cache.
     * @private
     */
    removeRecording() {
        if (this.mediaElement &&
            this.mediaElement.src &&
            this.mediaElement.src.startsWith('blob:') === true
        ) {
            URL.revokeObjectURL(this.mediaElement.src);
            this.mediaElement.src = '';
        }
    }

    /**
     * Export image data of waveform (audio-only) or current video frame.
     *
     * The default format is `'image/png'`. Other supported types are
     * `'image/jpeg'` and `'image/webp'`.
     *
     * @param {string} format='image/png' A string indicating the image format.
     * The default format type is `'image/png'`.
     * @param {number} quality=1 A number between 0 and 1 indicating the image
     * quality to use for image formats that use lossy compression such as
     * `'image/jpeg'`` and `'image/webp'`.
     * @return {Promise} Returns a `Promise` resolving with an
     * array of `Blob` instances.
     */
    exportImage(format = 'image/png', quality = 1) {
        if (this.getRecordType() === AUDIO_ONLY) {
            return this.surfer.surfer.exportImage(format, quality, 'blob');
        } else {
            // get a frame and copy it onto the canvas
            let recordCanvas = this.player.recordCanvas.el().firstChild;
            this.drawCanvas(recordCanvas, this.mediaElement);

            return new Promise(resolve => {
                recordCanvas.toBlob(resolve, format, quality);
            });
        }
    }

    /**
     * Mute LocalMediaStream audio and video tracks.
     *
     * @param {boolean} mute - Whether or not the mute the track(s).
     */
    muteTracks(mute) {
        if ((this.getRecordType() === AUDIO_ONLY ||
            this.getRecordType() === AUDIO_SCREEN ||
            this.getRecordType() === AUDIO_VIDEO) &&
            this.stream.getAudioTracks().length > 0) {
            this.stream.getAudioTracks()[0].enabled = !mute;
        }

        if (this.getRecordType() !== AUDIO_ONLY &&
            this.stream.getVideoTracks().length > 0) {
            this.stream.getVideoTracks()[0].enabled = !mute;
        }
    }

    /**
     * Get recorder type.
     *
     * @returns {string} Recorder type constant.
     * @example
     * console.log(player.record().getRecordType()); // 'audio_video'
     */
    getRecordType() {
        return getRecorderMode(this.recordImage, this.recordAudio,
            this.recordVideo, this.recordAnimation, this.recordScreen);
    }

    /**
     * Start converter.
     */
    convert() {
        if (this.converter !== undefined) {
            this.converter.convert(this.player.recordedData);
        }
    }

    /**
     * Create and display snapshot image.
     * @private
     */
    createSnapshot() {
        this.captureFrame().then((result) => {
            if (this.imageOutputType === 'blob') {
                // turn the canvas data into a Blob
                result.toBlob((blob) => {
                    this.player.recordedData = blob;

                    // display the snapshot
                    this.displaySnapshot();
                });
            } else if (this.imageOutputType === 'dataURL') {
                // turn the canvas data into base64 data
                this.player.recordedData = result.toDataURL(
                    this.imageOutputFormat, this.imageOutputQuality);

                // display the snapshot
                this.displaySnapshot();
            }
        }, this.imageOutputFormat, this.imageOutputQuality);
    }

    /**
     * Display snapshot image.
     * @private
     */
    displaySnapshot() {
        // hide preview video
        this.mediaElement.style.display = 'none';

        // show the snapshot
        this.player.recordCanvas.show();

        // stop recording
        this.stop();
    }

    /**
     * Reset UI for retrying a snapshot image.
     * @private
     */
    retrySnapshot() {
        this._processing = false;

        // retry: hide the snapshot
        this.player.recordCanvas.hide();

        // show preview video
        this.player.el().firstChild.style.display = 'block';
    }

    /**
     * Capture frame from camera and copy data to canvas.
     * @private
     * @returns {void}
     */
    captureFrame() {
        let detected = detectBrowser();
        let recordCanvas = this.player.recordCanvas.el().firstChild;
        let track = this.stream.getVideoTracks()[0];
        let settings = track.getSettings();

        // set the canvas size to the dimensions of the camera,
        // which also wipes the content of the canvas
        recordCanvas.width = settings.width;
        recordCanvas.height = settings.height;

        return new Promise((resolve, reject) => {
            const cameraAspectRatio = settings.width / settings.height;
            const playerAspectRatio = this.player.width() / this.player.height();
            let imagePreviewHeight = 0;
            let imagePreviewWidth = 0;
            let imageXPosition = 0;
            let imageYPosition = 0;

            // determine orientation
            // buddy ignore:start
            if (cameraAspectRatio >= playerAspectRatio) {
                // camera feed wider than player
                imagePreviewHeight = settings.height * (this.player.width() / settings.width);
                imagePreviewWidth = this.player.width();
                imageYPosition = (this.player.height() / 2) - (imagePreviewHeight / 2);
            } else {
                // player wider than camera feed
                imagePreviewHeight = this.player.height();
                imagePreviewWidth = settings.width * (this.player.height() / settings.height);
                imageXPosition = (this.player.width() / 2) - (imagePreviewWidth / 2);
            }
            // buddy ignore:end

            // MediaCapture is only supported on:
            // - Chrome 60 and newer (see
            // https://github.com/w3c/mediacapture-image/blob/gh-pages/implementation-status.md)
            // - Firefox behind flag (https://bugzilla.mozilla.org/show_bug.cgi?id=888177)
            //
            // importing ImageCapture can fail when enabling chrome flag is still required.
            // if so; ignore and continue
            if ((detected.browser === 'chrome' && detected.version >= 60) &&
               (typeof ImageCapture === typeof Function)) {
                try {
                    let imageCapture = new ImageCapture(track);
                    // take picture
                    imageCapture.grabFrame().then((imageBitmap) => {
                        // get a frame and copy it onto the canvas
                        this.drawCanvas(recordCanvas, imageBitmap, imagePreviewWidth,
                            imagePreviewHeight, imageXPosition, imageYPosition);

                        // notify others
                        resolve(recordCanvas);
                    }).catch((error) => {
                        // ignore, try oldskool
                    });
                } catch (err) {}
            }
            // no ImageCapture available: do it the oldskool way

            // get a frame and copy it onto the canvas
            this.drawCanvas(recordCanvas, this.mediaElement, imagePreviewWidth,
                imagePreviewHeight, imageXPosition, imageYPosition);

            // notify others
            resolve(recordCanvas);
        });
    }

    /**
     * Draw image frame on canvas element.
     * @private
     * @param {HTMLCanvasElement} canvas - Canvas to draw on.
     * @param {HTMLElement} element - Element to draw onto the canvas.
     * @param {Number} width - Width of drawing on canvas.
     * @param {Number} height - Height of drawing on canvas.
     * @param {Number} x - X position on canvas where drawing starts.
     * @param {Number} y - Y position on canvas where drawing starts.
     */
    drawCanvas(canvas, element, width, height, x = 0, y = 0) {
        if (width === undefined) {
            width = canvas.width;
        }
        if (height === undefined) {
            height = canvas.height;
        }
        canvas.getContext('2d').drawImage(element, x, y, width, height);
    }

    /**
     * Start preview of video stream.
     * @private
     */
    startVideoPreview() {
        // disable playback events
        this.off(Event.TIMEUPDATE);
        this.off(Event.DURATIONCHANGE);
        this.off(Event.LOADEDMETADATA);
        this.off(Event.PLAY);

        // mute local audio
        this.mediaElement.muted = true;

        // hide volume control to prevent feedback
        this.displayVolumeControl(false);

        // garbage collect previous recording
        this.removeRecording();

        // start or resume live preview
        this.load(this.stream);
        this.mediaElement.play();
    }

    /**
     * Show animated GIF.
     * @private
     */
    showAnimation() {
        let animationDisplay = this.player.animationDisplay.el().firstChild;

        // set the image size to the dimensions of the recorded animation
        animationDisplay.width = this.player.width();
        animationDisplay.height = this.player.height();

        // hide the first frame
        this.player.recordCanvas.hide();

        // show the animation
        setSrcObject(this.player.recordedData, animationDisplay);
        this.player.animationDisplay.show();
    }

    /**
     * Hide animated GIF.
     * @private
     */
    hideAnimation() {
        // show the first frame
        this.player.recordCanvas.show();

        // hide the animation
        this.player.animationDisplay.hide();
    }

    /**
     * Update time during playback.
     * @private
     */
    playbackTimeUpdate() {
        this.setCurrentTime(this.player.currentTime(),
            this.streamDuration);
    }

    /**
     * Collects information about the media input and output devices
     * available on the system.
     */
    enumerateDevices() {
        if (!navigator.mediaDevices || !navigator.mediaDevices.enumerateDevices) {
            this.player.enumerateErrorCode = 'enumerateDevices() not supported.';
            this.player.trigger(Event.ENUMERATE_ERROR);
            return;
        }

        // list video and audio devices
        navigator.mediaDevices.enumerateDevices(this).then((devices) => {
            this.devices = [];
            devices.forEach((device) => {
                this.devices.push(device);
            });

            // notify listeners
            this.player.trigger(Event.ENUMERATE_READY);
        }).catch((err) => {
            this.player.enumerateErrorCode = err;
            this.player.trigger(Event.ENUMERATE_ERROR);
        });
    }

    /**
     * Change the video input device.
     *
     * @param {string} deviceId - Id of the video input device.
     */
    setVideoInput(deviceId) {
        if (this.recordVideo === Object(this.recordVideo)) {
            // already using video constraints
            this.recordVideo.deviceId = {exact: deviceId};

        } else if (this.recordVideo === true) {
            // not using video constraints already, so force it
            this.recordVideo = {
                deviceId: {exact: deviceId}
            };
        }

        // release existing device
        this.stopDevice();

        // ask for video input device permissions and start device
        this.getDevice();
    }

    /**
     * Change the audio input device.
     *
     * @param {string} deviceId - Id of the audio input device.
     */
    setAudioInput(deviceId) {
        if (this.recordAudio === Object(this.recordAudio)) {
            // already using audio constraints
            this.recordAudio.deviceId = {exact: deviceId};

        } else if (this.recordAudio === true) {
            // not using audio constraints already, so force it
            this.recordAudio = {
                deviceId: {exact: deviceId}
            };
        }

        // update wavesurfer microphone plugin constraints
        switch (this.getRecordType()) {
            case AUDIO_ONLY:
                this.surfer.surfer.microphone.constraints = {
                    video: false,
                    audio: this.recordAudio
                };
                break;
        }

        // release existing device
        this.stopDevice();

        // ask for audio input device permissions and start device
        this.getDevice();
    }

    /**
     * Change the audio output device.
     *
     * @param {string} deviceId - Id of audio output device.
     */
    setAudioOutput(deviceId) {
        let errorMessage;
        switch (this.getRecordType()) {
            case AUDIO_ONLY:
                // use wavesurfer
                this.surfer.surfer.setSinkId(deviceId).then((result) => {
                    // notify listeners
                    this.player.trigger(Event.AUDIO_OUTPUT_READY);
                    return;
                }).catch((err) => {
                    errorMessage = err;
                });
                break;

            default:
                let element = player.tech_.el_;
                if (deviceId) {
                    if (typeof element.sinkId !== 'undefined') {
                        element.setSinkId(deviceId).then((result) => {
                            // notify listeners
                            this.player.trigger(Event.AUDIO_OUTPUT_READY);
                            return;
                        }).catch((err) => {
                            errorMessage = err;
                        });
                    } else {
                        errorMessage = 'Browser does not support audio output device selection.';
                    }
                } else {
                    errorMessage = `Invalid deviceId: ${deviceId}`;
                }
                break;
        }

        // error if we get here: notify listeners
        this.player.trigger(Event.ERROR, errorMessage);
    }

    /**
     * Replaces the default `formatTime` implementation with a custom implementation.
     *
     * @param {function} customImplementation - A function which will be used in place
     *     of the default `formatTime` implementation. Will receive the current time
     *     in seconds and the guide (in seconds) as arguments.
     */
    setFormatTime(customImplementation) {
        this._formatTime = customImplementation;

        videojs.setFormatTime(this._formatTime);

        // audio-only
        if (this.surfer) {
            // use same time format as this plugin
            this.surfer.setFormatTime(this._formatTime);
        }
    }

    /**
     * Show or hide the volume menu.
     *
     * @private
     * @param {boolean} display - Hide/show volume control.
     */
    displayVolumeControl(display) {
        if (this.player.controlBar.volumePanel !== undefined) {
            if (display === true) {
                display = 'flex';
            } else {
                display = 'none';
            }
            this.player.controlBar.volumePanel.el().style.display = display;
        }
    }

    /**
     * Invoked when the video device is ready and stream is visible.
     *
     * @private
     * @param {Event} event - `playing` event
     */
    onStreamVisible(event) {
        // only listen for this once; remove listener
        this.mediaElement.removeEventListener(Event.PLAYING, this.streamVisibleCallback);

        // reset and show camera button
        this.player.cameraButton.onStop();
        this.player.cameraButton.show();
    }

    /**
     * Invoked when entering picture-in-picture mode.
     *
     * @private
     * @param {object} event - Event data.
     */
    onEnterPiP(event) {
        this.player.trigger(Event.ENTER_PIP, event);
    }

    /**
     * Invoked when leaving picture-in-picture mode.
     *
     * @private
     * @param {object} event - Event data.
     */
    onLeavePiP(event) {
        this.player.trigger(Event.LEAVE_PIP);
    }
}

// version nr is injected during build
Record.VERSION = __VERSION__;

// register plugin
videojs.Record = Record;
if (videojs.getPlugin('record') === undefined) {
    videojs.registerPlugin('record', Record);
}

// export plugin
export {Record};
