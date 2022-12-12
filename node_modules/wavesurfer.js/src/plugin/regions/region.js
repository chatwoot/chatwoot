/**
 *  @since 4.0.0
 *
 * (Single) Region plugin class
 *
 * Must be turned into an observer before instantiating. This is done in
 * `RegionsPlugin` (main plugin class).
 *
 * @extends {Observer}
 */
export class Region {
    constructor(params, regionsUtils, ws) {
        this.wavesurfer = ws;
        this.wrapper = ws.drawer.wrapper;
        this.util = ws.util;
        this.style = this.util.style;
        this.regionsUtil = regionsUtils;
        this.vertical = ws.drawer.params.vertical;

        this.id = params.id == null ? ws.util.getId() : params.id;
        this.start = Number(params.start) || 0;
        this.end =
            params.end == null
                ? // small marker-like region
                this.start +
                (4 / this.wrapper.scrollWidth) * this.wavesurfer.getDuration()
                : Number(params.end);
        this.resize =
            params.resize === undefined ? true : Boolean(params.resize);
        this.drag = params.drag === undefined ? true : Boolean(params.drag);
        // reflect resize and drag state of region for region-updated listener
        this.isResizing = false;
        this.isDragging = false;
        this.loop = Boolean(params.loop);
        this.color = params.color || 'rgba(0, 0, 0, 0.1)';
        // The left and right handleStyle properties can be set to 'none' for
        // no styling or can be assigned an object containing CSS properties.
        this.handleStyle = params.handleStyle || {
            left: {},
            right: {}
        };
        this.handleLeftEl = null;
        this.handleRightEl = null;
        this.data = params.data || {};
        this.attributes = params.attributes || {};
        this.showTooltip = params.showTooltip ?? true;

        this.maxLength = params.maxLength;
        // It assumes the minLength parameter value, or the regionsMinLength parameter value, if the first one not provided
        this.minLength = params.minLength;
        this._onRedraw = () => this.updateRender();

        this.scroll = params.scroll !== false && ws.params.scrollParent;
        this.scrollSpeed = params.scrollSpeed || 1;
        this.scrollThreshold = params.scrollThreshold || 10;
        // Determines whether the context menu is prevented from being opened.
        this.preventContextMenu =
            params.preventContextMenu === undefined
                ? false
                : Boolean(params.preventContextMenu);

        // select channel ID to set region
        let channelIdx =
            params.channelIdx == null ? -1 : parseInt(params.channelIdx);
        this.channelIdx = channelIdx;
        this.regionHeight = '100%';
        this.marginTop = '0px';

        if (channelIdx !== -1) {
            let channelCount =
                this.wavesurfer.backend.buffer != null
                    ? this.wavesurfer.backend.buffer.numberOfChannels
                    : -1;
            if (channelCount >= 0 && channelIdx < channelCount) {
                this.regionHeight = Math.floor((1 / channelCount) * 100) + '%';
                this.marginTop =
                    this.wavesurfer.getHeight() * channelIdx + 'px';
            }
        }

        this.formatTimeCallback = params.formatTimeCallback;
        this.edgeScrollWidth = params.edgeScrollWidth;
        this.bindInOut();
        this.render();
        this.wavesurfer.on('zoom', this._onRedraw);
        this.wavesurfer.on('redraw', this._onRedraw);
        this.wavesurfer.fireEvent('region-created', this);
    }

    /* Update region params. */
    update(params, eventParams) {
        if (params.start != null) {
            this.start = Number(params.start);
        }
        if (params.end != null) {
            this.end = Number(params.end);
        }
        if (params.loop != null) {
            this.loop = Boolean(params.loop);
        }
        if (params.color != null) {
            this.color = params.color;
        }
        if (params.handleStyle != null) {
            this.handleStyle = params.handleStyle;
        }
        if (params.data != null) {
            this.data = params.data;
        }
        if (params.resize != null) {
            this.resize = Boolean(params.resize);
            this.updateHandlesResize(this.resize);
        }
        if (params.drag != null) {
            this.drag = Boolean(params.drag);
        }
        if (params.maxLength != null) {
            this.maxLength = Number(params.maxLength);
        }
        if (params.minLength != null) {
            this.minLength = Number(params.minLength);
        }
        if (params.attributes != null) {
            this.attributes = params.attributes;
        }

        this.updateRender();
        this.fireEvent('update');
        this.wavesurfer.fireEvent('region-updated', this, eventParams);
    }

    /* Remove a single region. */
    remove() {
        if (this.element) {
            this.wrapper.removeChild(this.element.domElement);
            this.element = null;
            this.fireEvent('remove');
            this.wavesurfer.un('zoom', this._onRedraw);
            this.wavesurfer.un('redraw', this._onRedraw);
            this.wavesurfer.fireEvent('region-removed', this);
        }
    }

    /**
     * Play the audio region.
     * @param {number} start Optional offset to start playing at
     */
    play(start) {
        const s = start || this.start;
        this.wavesurfer.play(s, this.end);
        this.fireEvent('play');
        this.wavesurfer.fireEvent('region-play', this);
    }

    /**
     * Play the audio region in a loop.
     * @param {number} start Optional offset to start playing at
     * */
    playLoop(start) {
        this.loop = true;
        this.play(start);
    }

    /**
     * Set looping on/off.
     * @param {boolean} loop True if should play in loop
     */
    setLoop(loop) {
        this.loop = loop;
    }

    /* Render a region as a DOM element. */
    render() {
        this.element = this.util.withOrientation(
            this.wrapper.appendChild(document.createElement('region')),
            this.vertical
        );

        this.element.className = 'wavesurfer-region';
        if (this.showTooltip) {
            this.element.title = this.formatTime(this.start, this.end);
        }
        this.element.setAttribute('data-id', this.id);

        for (const attrname in this.attributes) {
            this.element.setAttribute(
                'data-region-' + attrname,
                this.attributes[attrname]
            );
        }

        this.style(this.element, {
            position: 'absolute',
            zIndex: 3,
            height: this.regionHeight,
            top: this.marginTop
        });

        /* Resize handles */
        if (this.resize) {
            this.handleLeftEl = this.util.withOrientation(
                this.element.appendChild(document.createElement('handle')),
                this.vertical
            );
            this.handleRightEl = this.util.withOrientation(
                this.element.appendChild(document.createElement('handle')),
                this.vertical
            );

            this.handleLeftEl.className = 'wavesurfer-handle wavesurfer-handle-start';
            this.handleRightEl.className = 'wavesurfer-handle wavesurfer-handle-end';

            // Default CSS properties for both handles.
            const css = {
                cursor: this.vertical ? 'row-resize' : 'col-resize',
                position: 'absolute',
                top: '0px',
                width: '2px',
                height: '100%',
                backgroundColor: 'rgba(0, 0, 0, 1)'
            };

            // Merge CSS properties per handle.
            const handleLeftCss =
                this.handleStyle.left !== 'none'
                    ? Object.assign(
                        { left: '0px' },
                        css,
                        this.handleStyle.left
                    )
                    : null;
            const handleRightCss =
                this.handleStyle.right !== 'none'
                    ? Object.assign(
                        { right: '0px' },
                        css,
                        this.handleStyle.right
                    )
                    : null;

            if (handleLeftCss) {
                this.style(this.handleLeftEl, handleLeftCss);
            }

            if (handleRightCss) {
                this.style(this.handleRightEl, handleRightCss);
            }
        }

        this.updateRender();
        this.bindEvents();
    }

    formatTime(start, end) {
        if (this.formatTimeCallback) {
            return this.formatTimeCallback(start, end);
        }
        return (start == end ? [start] : [start, end])
            .map((time) =>
                [
                    Math.floor((time % 3600) / 60), // minutes
                    ('00' + Math.floor(time % 60)).slice(-2) // seconds
                ].join(':')
            )
            .join('-');
    }

    getWidth() {
        return this.wavesurfer.drawer.width / this.wavesurfer.params.pixelRatio;
    }

    /* Update element's position, width, color. */
    updateRender() {
        // duration varies during loading process, so don't overwrite important data
        const dur = this.wavesurfer.getDuration();
        const width = this.getWidth();

        let startLimited = this.start;
        let endLimited = this.end;
        if (startLimited < 0) {
            startLimited = 0;
            endLimited = endLimited - startLimited;
        }
        if (endLimited > dur) {
            endLimited = dur;
            startLimited = dur - (endLimited - startLimited);
        }

        if (this.minLength != null) {
            endLimited = Math.max(startLimited + this.minLength, endLimited);
        }

        if (this.maxLength != null) {
            endLimited = Math.min(startLimited + this.maxLength, endLimited);
        }

        if (this.element != null) {
            // Calculate the left and width values of the region such that
            // no gaps appear between regions.
            const left = Math.round((startLimited / dur) * width);
            const regionWidth = Math.round((endLimited / dur) * width) - left;

            this.style(this.element, {
                left: left + 'px',
                width: regionWidth + 'px',
                backgroundColor: this.color,
                cursor: this.drag ? 'move' : 'default'
            });

            for (const attrname in this.attributes) {
                this.element.setAttribute(
                    'data-region-' + attrname,
                    this.attributes[attrname]
                );
            }

            if (this.showTooltip) {
                this.element.title = this.formatTime(this.start, this.end);
            }
        }
    }

    /* Bind audio events. */
    bindInOut() {
        this.firedIn = false;
        this.firedOut = false;

        const onProcess = (time) => {
            let start = Math.round(this.start * 10) / 10;
            let end = Math.round(this.end * 10) / 10;
            time = Math.round(time * 10) / 10;

            if (
                !this.firedOut &&
                this.firedIn &&
                (start > time || end <= time)
            ) {
                this.firedOut = true;
                this.firedIn = false;
                this.fireEvent('out');
                this.wavesurfer.fireEvent('region-out', this);
            }
            if (!this.firedIn && start <= time && end > time) {
                this.firedIn = true;
                this.firedOut = false;
                this.fireEvent('in');
                this.wavesurfer.fireEvent('region-in', this);
            }
        };

        this.wavesurfer.backend.on('audioprocess', onProcess);

        this.on('remove', () => {
            this.wavesurfer.backend.un('audioprocess', onProcess);
        });

        /* Loop playback. */
        this.on('out', () => {
            if (this.loop) {
                const realTime = this.wavesurfer.getCurrentTime();
                if (realTime >= this.start && realTime <= this.end) {
                    this.wavesurfer.play(this.start);
                }
            }
        });
    }

    /* Bind DOM events. */
    bindEvents() {
        const preventContextMenu = this.preventContextMenu;

        this.element.addEventListener('mouseenter', (e) => {
            this.fireEvent('mouseenter', e);
            this.wavesurfer.fireEvent('region-mouseenter', this, e);
        });

        this.element.addEventListener('mouseleave', (e) => {
            this.fireEvent('mouseleave', e);
            this.wavesurfer.fireEvent('region-mouseleave', this, e);
        });

        this.element.addEventListener('click', (e) => {
            e.preventDefault();
            this.fireEvent('click', e);
            this.wavesurfer.fireEvent('region-click', this, e);
        });

        this.element.addEventListener('dblclick', (e) => {
            e.stopPropagation();
            e.preventDefault();
            this.fireEvent('dblclick', e);
            this.wavesurfer.fireEvent('region-dblclick', this, e);
        });

        this.element.addEventListener('contextmenu', (e) => {
            if (preventContextMenu) {
                e.preventDefault();
            }
            this.fireEvent('contextmenu', e);
            this.wavesurfer.fireEvent('region-contextmenu', this, e);
        });

        /* Drag or resize on mousemove. */
        if (this.drag || this.resize) {
            this.bindDragEvents();
        }
    }

    bindDragEvents() {
        const container = this.wavesurfer.drawer.container;
        const scrollSpeed = this.scrollSpeed;
        const scrollThreshold = this.scrollThreshold;
        let startTime;
        let touchId;
        let drag;
        let maxScroll;
        let resize;
        let updated = false;
        let scrollDirection;
        let wrapperRect;
        let regionLeftHalfTime;
        let regionRightHalfTime;

        // Scroll when the user is dragging within the threshold
        const edgeScroll = (event) => {
            let orientedEvent = this.util.withOrientation(event, this.vertical);
            const duration = this.wavesurfer.getDuration();
            if (!scrollDirection || (!drag && !resize)) {
                return;
            }

            const x = orientedEvent.clientX;
            let distanceBetweenCursorAndWrapperEdge = 0;
            let regionHalfTimeWidth = 0;
            let adjustment = 0;

            // Get the currently selected time according to the mouse position
            let time = this.regionsUtil.getRegionSnapToGridValue(
                this.wavesurfer.drawer.handleEvent(event) * duration
            );

            if (drag) {
                // Considering the point of contact with the region while edgescrolling
                if (scrollDirection === -1) {
                    regionHalfTimeWidth = regionLeftHalfTime * this.wavesurfer.params.minPxPerSec;
                    distanceBetweenCursorAndWrapperEdge = x - wrapperRect.left;
                } else {
                    regionHalfTimeWidth = regionRightHalfTime * this.wavesurfer.params.minPxPerSec;
                    distanceBetweenCursorAndWrapperEdge = wrapperRect.right - x;
                }
            } else {
                // Considering minLength while edgescroll
                let minLength = this.minLength;
                if (!minLength) {
                    minLength = 0;
                }

                if (resize === 'start') {
                    if (time > this.end - minLength) {
                        time = this.end - minLength;
                        adjustment = scrollSpeed * scrollDirection;
                    }

                    if (time < 0) {
                        time = 0;
                    }
                } else if (resize === 'end') {
                    if (time < this.start + minLength) {
                        time = this.start + minLength;
                        adjustment = scrollSpeed * scrollDirection;
                    }

                    if (time > duration) {
                        time = duration;
                    }
                }
            }

            // Don't edgescroll if region has reached min or max limit
            const wrapperScrollLeft = this.wrapper.scrollLeft;

            if (scrollDirection === -1) {
                if (Math.round(wrapperScrollLeft) === 0) {
                    return;
                }

                if (Math.round(wrapperScrollLeft - regionHalfTimeWidth + distanceBetweenCursorAndWrapperEdge) <= 0) {
                    return;
                }
            } else {
                if (Math.round(wrapperScrollLeft) === maxScroll) {
                    return;
                }

                if (Math.round(wrapperScrollLeft + regionHalfTimeWidth - distanceBetweenCursorAndWrapperEdge) >= maxScroll) {
                    return;
                }
            }

            // Update scroll position
            let scrollLeft = wrapperScrollLeft - adjustment + scrollSpeed * scrollDirection;

            if (scrollDirection === -1) {
                const calculatedLeft = Math.max(0 + regionHalfTimeWidth - distanceBetweenCursorAndWrapperEdge, scrollLeft);
                this.wrapper.scrollLeft = scrollLeft = calculatedLeft;
            } else {
                const calculatedRight = Math.min(maxScroll - regionHalfTimeWidth + distanceBetweenCursorAndWrapperEdge, scrollLeft);
                this.wrapper.scrollLeft = scrollLeft = calculatedRight;
            }

            const delta = time - startTime;
            startTime = time;

            // Continue dragging or resizing
            drag ? this.onDrag(delta) : this.onResize(delta, resize);

            // Repeat
            window.requestAnimationFrame(() => {
                edgeScroll(event);
            });
        };

        const onDown = (event) => {
            const duration = this.wavesurfer.getDuration();
            if (event.touches && event.touches.length > 1) {
                return;
            }
            touchId = event.targetTouches ? event.targetTouches[0].identifier : null;

            // stop the event propagation, if this region is resizable or draggable
            // and the event is therefore handled here.
            if (this.drag || this.resize) {
                event.stopPropagation();
            }

            // Store the selected startTime we begun dragging or resizing
            startTime = this.regionsUtil.getRegionSnapToGridValue(
                this.wavesurfer.drawer.handleEvent(event, true) * duration
            );

            // Store the selected point of contact when we begin dragging
            regionLeftHalfTime = startTime - this.start;
            regionRightHalfTime = this.end - startTime;

            // Store for scroll calculations
            maxScroll = this.wrapper.scrollWidth - this.wrapper.clientWidth;

            wrapperRect = this.util.withOrientation(
                this.wrapper.getBoundingClientRect(),
                this.vertical
            );

            this.isResizing = false;
            this.isDragging = false;
            if (event.target.tagName.toLowerCase() === 'handle') {
                this.isResizing = true;
                resize = event.target.classList.contains('wavesurfer-handle-start')
                    ? 'start'
                    : 'end';
            } else {
                this.isDragging = true;
                drag = true;
                resize = false;
            }
        };
        const onUp = (event) => {
            if (event.touches && event.touches.length > 1) {
                return;
            }

            if (drag || resize) {
                this.isDragging = false;
                this.isResizing = false;
                drag = false;
                scrollDirection = null;
                resize = false;
            }

            if (updated) {
                updated = false;
                this.util.preventClick();
                this.fireEvent('update-end', event);
                this.wavesurfer.fireEvent('region-update-end', this, event);
            }
        };
        const onMove = (event) => {
            const duration = this.wavesurfer.getDuration();
            let orientedEvent = this.util.withOrientation(event, this.vertical);

            if (event.touches && event.touches.length > 1) {
                return;
            }
            if (event.targetTouches && event.targetTouches[0].identifier != touchId) {
                return;
            }
            if (!drag && !resize) {
                return;
            }

            const oldTime = startTime;
            let time = this.regionsUtil.getRegionSnapToGridValue(
                this.wavesurfer.drawer.handleEvent(event) * duration
            );

            if (drag) {
                // To maintain relative cursor start point while dragging
                const maxEnd = this.wavesurfer.getDuration();
                if (time > maxEnd - regionRightHalfTime) {
                    time = maxEnd - regionRightHalfTime;
                }

                if (time - regionLeftHalfTime < 0) {
                    time = regionLeftHalfTime;
                }
            }

            if (resize) {
                // To maintain relative cursor start point while resizing
                // we have to handle for minLength
                let minLength = this.minLength;
                if (!minLength) {
                    minLength = 0;
                }

                if (resize === 'start') {
                    if (time > this.end - minLength) {
                        time = this.end - minLength;
                    }

                    if (time < 0) {
                        time = 0;
                    }
                } else if (resize === 'end') {
                    if (time < this.start + minLength) {
                        time = this.start + minLength;
                    }

                    if (time > duration) {
                        time = duration;
                    }
                }
            }

            let delta = time - startTime;
            startTime = time;

            // Drag
            if (this.drag && drag) {
                updated = updated || !!delta;
                this.onDrag(delta);
            }

            // Resize
            if (this.resize && resize) {
                updated = updated || !!delta;
                this.onResize(delta, resize);
            }

            if (
                this.scroll && container.clientWidth < this.wrapper.scrollWidth
            ) {
                // Triggering edgescroll from within edgeScrollWidth
                let x = orientedEvent.clientX;

                // Check direction
                if (x < wrapperRect.left + this.edgeScrollWidth) {
                    scrollDirection = -1;
                } else if (x > wrapperRect.right - this.edgeScrollWidth) {
                    scrollDirection = 1;
                } else {
                    scrollDirection = null;
                }

                if (scrollDirection) {
                    edgeScroll(event);
                }
            }
        };

        this.element.addEventListener('mousedown', onDown);
        this.element.addEventListener('touchstart', onDown);

        document.body.addEventListener('mousemove', onMove);
        document.body.addEventListener('touchmove', onMove, {passive: false});

        document.addEventListener('mouseup', onUp);
        document.body.addEventListener('touchend', onUp);

        this.on('remove', () => {
            document.removeEventListener('mouseup', onUp);
            document.body.removeEventListener('touchend', onUp);
            document.body.removeEventListener('mousemove', onMove);
            document.body.removeEventListener('touchmove', onMove);
        });

        this.wavesurfer.on('destroy', () => {
            document.removeEventListener('mouseup', onUp);
            document.body.removeEventListener('touchend', onUp);
        });
    }

    onDrag(delta) {
        const maxEnd = this.wavesurfer.getDuration();
        if (this.end + delta > maxEnd) {
            delta = maxEnd - this.end;
        }

        if (this.start + delta < 0) {
            delta = this.start * -1;
        }

        const eventParams = {
            direction: this._getDragDirection(delta),
            action: 'drag'
        };

        this.update({
            start: this.start + delta,
            end: this.end + delta
        }, eventParams);
    }

    /**
     * Returns the direction of dragging region based on delta
     * Negative delta means region is moving to the left
     * Positive - to the right
     * For zero delta the direction is not defined
     * @param {number} delta Drag offset
     * @returns {string|null} Direction 'left', 'right' or null
     */
    _getDragDirection(delta) {
        if (delta < 0) {
            return 'left';
        }
        if (delta > 0) {
            return 'right';
        }
        return null;
    }

    /**
     * @example
     * onResize(-5, 'start') // Moves the start point 5 seconds back
     * onResize(0.5, 'end') // Moves the end point 0.5 seconds forward
     *
     * @param {number} delta How much to add or subtract, given in seconds
     * @param {string} direction 'start 'or 'end'
     */
    onResize(delta, direction) {
        const duration = this.wavesurfer.getDuration();
        const eventParams = {
            action: 'resize',
            direction: direction === 'start' ? 'left' : 'right'
        };

        if (direction === 'start') {
            // Check if changing the start by the given delta would result in the region being smaller than minLength
            if (delta > 0 && this.end - (this.start + delta) < this.minLength) {
                delta = this.end - this.minLength - this.start;
            }

            // Check if changing the start by the given delta would result in the region being larger than maxLength
            if (delta < 0 && this.end - (this.start + delta) > this.maxLength) {
                delta = this.end - this.start - this.maxLength;
            }

            if (delta < 0 && (this.start + delta) < 0) {
                delta = this.start * -1;
            }

            this.update({
                start: Math.min(this.start + delta, this.end),
                end: Math.max(this.start + delta, this.end)
            }, eventParams);
        } else {
            // Check if changing the end by the given delta would result in the region being smaller than minLength
            if (delta < 0 && this.end + delta - this.start < this.minLength) {
                delta = this.start + this.minLength - this.end;
            }

            // Check if changing the end by the given delta would result in the region being larger than maxLength
            if (delta > 0 && this.end + delta - this.start > this.maxLength) {
                delta = this.maxLength - (this.end - this.start);
            }

            if (delta > 0 && (this.end + delta) > duration) {
                delta = duration - this.end;
            }

            this.update({
                start: Math.min(this.end + delta, this.start),
                end: Math.max(this.end + delta, this.start)
            }, eventParams);
        }
    }

    updateHandlesResize(resize) {
        let cursorStyle;
        if (resize) {
            cursorStyle = this.vertical ? 'row-resize' : 'col-resize';
        } else {
            cursorStyle = 'auto';
        }

        this.handleLeftEl && this.style(this.handleLeftEl, { cursor: cursorStyle });
        this.handleRightEl && this.style(this.handleRightEl, { cursor: cursorStyle });
    }
}
