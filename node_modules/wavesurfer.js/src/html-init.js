import loadScript from 'load-script';

/**
 * @typedef {Object} InitParams
 * @property {WavesurferParams} [defaults={backend: 'MediaElement,
 * mediaControls: true}] The default wavesurfer initialisation parameters
 * @property {string|NodeList} containers='wavesurfer' Selector or NodeList of
 * elements to attach instances to
 * @property {string}
 * pluginCdnTemplate='//localhost:8080/dist/plugin/wavesurfer.[name].js' URL
 * template for the dynamic loading of plugins
 * @property {function} loadPlugin If set overwrites the default request function,
 * can be used to inject plugins differently.
 */
/**
 * The HTML initialisation API is not part of the main library bundle file and
 * must be additionally included.
 *
 * The API attaches wavesurfer instances to all `<wavesurfer>` (can be
 * customised), parsing their `data-` attributes to construct an options object
 * for initialisation. Among other things it can dynamically load plugin code.
 *
 * The automatic initialisation can be prevented by setting the
 * `window.WS_StopAutoInit` flag to true. The `html-init[.min].js` file exports
 * the `Init` class, which can be called manually.
 *
 * Site-wide defaults can be added by setting `window.WS_InitOptions`.
 *
 * @example
 * <!-- with minimap and timeline plugin -->
 * <wavesurfer
 *   data-url="../media/demo.wav"
 *   data-plugins="minimap,timeline"
 *   data-minimap-height="30"
 *   data-minimap-wave-color="#ddd"
 *   data-minimap-progress-color="#999"
 *   data-timeline-font-size="13px"
 *   data-timeline-container="#timeline"
 * >
 * </wavesurfer>
 * <div id="timeline"></div>
 *
 * <!-- with regions plugin -->
 * <wavesurfer
 *   data-url="../media/demo.wav"
 *   data-plugins="regions"
 *   data-regions-regions='[{"start": 1,"end": 3,"color": "hsla(400, 100%, 30%, 0.5)"}]'
 * >
 * </wavesurfer>
 */
class Init {
    /**
     * Instantiate Init class and initialize elements
     *
     * This is done automatically if `window` is defined and
     * `window.WS_StopAutoInit` is not set to true
     *
     * @param {WaveSurfer} WaveSurfer The WaveSurfer library object
     * @param {InitParams} params initialisation options
     */
    constructor(WaveSurfer, params = {}) {
        if (!WaveSurfer) {
            throw new Error('WaveSurfer is not available!');
        }

        /**
         * cache WaveSurfer
         * @private
         */
        this.WaveSurfer = WaveSurfer;

        /**
         * build parameters, cache them in _params so minified builds are smaller
         * @private
         */
        const _params = (this.params = Object.assign(
            {},
            {
                // wavesurfer parameter defaults so by default the audio player is
                // usable with native media element controls
                defaults: {
                    backend: 'MediaElement',
                    mediaControls: true
                },
                // containers to instantiate on, can be selector string or NodeList
                containers: 'wavesurfer',
                // @TODO insert plugin CDN URIs
                pluginCdnTemplate:
                    '//localhost:8080/dist/plugin/wavesurfer.[name].js',
                // loadPlugin function can be overridden to inject plugin definition
                // objects, this default function uses load-script to load a plugin
                // and pass it to a callback
                loadPlugin(name, cb) {
                    const src = _params.pluginCdnTemplate.replace(
                        '[name]',
                        name
                    );
                    loadScript(src, { async: false }, (err, plugin) => {
                        if (err) {
                            // eslint-disable-next-line no-console
                            return console.error(
                                `WaveSurfer plugin ${name} not found at ${src}`
                            );
                        }
                        cb(window.WaveSurfer[name]);
                    });
                }
            },
            params
        ));
        /**
         * The nodes that should have instances attached to them
         * @type {NodeList}
         */
        this.containers =
            typeof _params.containers == 'string'
                ? document.querySelectorAll(_params.containers)
                : _params.containers;
        /** @private */
        this.pluginCache = {};
        /**
         * An array of wavesurfer instances
         * @type {Object[]}
         */
        this.instances = [];

        this.initAllEls();
    }

    /**
     * Initialize all container elements
     */
    initAllEls() {
        // iterate over all the container elements
        Array.prototype.forEach.call(this.containers, el => {
            // load the plugins as an array of plugin names
            const plugins = el.dataset.plugins
                ? el.dataset.plugins.split(',')
                : [];

            // no plugins to be loaded, just render
            if (!plugins.length) {
                return this.initEl(el);
            }
            // … or: iterate over all the plugins
            plugins.forEach((name, i) => {
                // plugin is not cached already, load it
                if (!this.pluginCache[name]) {
                    this.params.loadPlugin(name, lib => {
                        this.pluginCache[name] = lib;
                        // plugins were all loaded, render the element
                        if (i + 1 === plugins.length) {
                            this.initEl(el, plugins);
                        }
                    });
                } else if (i === plugins.length) {
                    // plugin was cached and this plugin was the last
                    this.initEl(el, plugins);
                }
            });
        });
    }

    /**
     * Initialize a single container element and add to `this.instances`
     *
     * @param  {HTMLElement} el The container to instantiate wavesurfer to
     * @param  {PluginDefinition[]} plugins An Array of plugin names to initialize with
     * @return {Object} Wavesurfer instance
     */
    initEl(el, plugins = []) {
        const jsonRegex = /^[[|{]/;
        // initialize plugins with the correct options
        const initialisedPlugins = plugins.map(plugin => {
            const options = {};
            // the regex to find this plugin attributes
            const attrNameRegex = new RegExp('^' + plugin);
            let attrName;
            // iterate over all the data attributes and find ones for this
            // plugin
            for (attrName in el.dataset) {
                const regexResult = attrNameRegex.exec(attrName);
                if (regexResult) {
                    const attr = el.dataset[attrName];
                    // if the string begins with a [ or a { parse it as JSON
                    const prop = jsonRegex.test(attr) ? JSON.parse(attr) : attr;
                    // this removes the plugin prefix and changes the first letter
                    // of the resulting string to lower case to follow the naming
                    // convention of ws params
                    const unprefixedOptionName =
                        attrName
                            .slice(plugin.length, plugin.length + 1)
                            .toLowerCase() + attrName.slice(plugin.length + 1);
                    options[unprefixedOptionName] = prop;
                }
            }
            return this.pluginCache[plugin].create(options);
        });
        // build parameter object for this container
        const params = Object.assign(
            { container: el },
            this.params.defaults,
            el.dataset,
            { plugins: initialisedPlugins }
        );

        // @TODO make nicer
        el.style.display = 'block';

        // initialize wavesurfer, load audio (with peaks if provided)
        const instance = this.WaveSurfer.create(params);
        const peaks = params.peaks ? JSON.parse(params.peaks) : undefined;
        instance.load(params.url, peaks);

        // push this instance into the instances cache
        this.instances.push(instance);
        return instance;
    }
}

// if window object exists and window.WS_StopAutoInit is not true
if (typeof window === 'object' && !window.WS_StopAutoInit) {
    // call init when document is ready, apply any custom default settings
    // in window.WS_InitOptions
    if (document.readyState === 'complete') {
        window.WaveSurferInit = new Init(
            window.WaveSurfer,
            window.WS_InitOptions
        );
    } else {
        window.addEventListener('load', () => {
            window.WaveSurferInit = new Init(
                window.WaveSurfer,
                window.WS_InitOptions
            );
        });
    }
}

// export init for manual usage
export default Init;
