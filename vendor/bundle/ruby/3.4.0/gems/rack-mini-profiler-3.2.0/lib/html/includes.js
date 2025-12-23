"use strict";

var _MiniProfiler = (function() {
  var _arguments = arguments;
  var options,
    container,
    controls,
    fetchedIds = (window.MiniProfiler && window.MiniProfiler.fetchedIds) || [],
    fetchingIds =
      (window.MiniProfiler && window.MiniProfiler.fetchingIds) || [],
    // so we never pull down a profiler twice
    ajaxStartTime,
    totalsControl,
    reqs = 0,
    expandedResults = false,
    totalTime = 0,
    totalSqlCount = 0;

  var hasLocalStorage = function hasLocalStorage(keyPrefix) {
    try {
      // attempt to save to localStorage as Safari private windows will throw an error
      localStorage[keyPrefix + "-test"] = "1";
      localStorage.removeItem(keyPrefix + "-test");
      return "localStorage" in window && window["localStorage"] !== null;
    } catch (e) {
      return false;
    }
  };

  var getVersionedKey = function getVersionedKey(keyPrefix) {
    return keyPrefix + "-" + options.version;
  };

  // polyfills as helper functions to avoid conflicts
  // needed for IE11
  // remove and replace with Element.closest when we drop IE11 support
  // https://developer.mozilla.org/en-US/docs/Web/API/Element/closest

  var elementMatches =
    Element.prototype.msMatchesSelector ||
    Element.prototype.webkitMatchesSelector;

  var elementClosest = function elementClosest(el, s) {
    if (typeof el.closest === "function") {
      return el.closest(s);
    }

    do {
      if (typeof el.matches === "function") {
        if (el.matches(s)) return el;
      } else {
        if (elementMatches.call(el, s)) return el;
      }

      el = el.parentElement || el.parentNode;
    } while (el !== null && el.nodeType === 1);

    return null;
  };

  var save = function save(keyPrefix, value) {
    if (!hasLocalStorage(keyPrefix)) {
      return;
    } // clear old keys with this prefix, if any

    for (var i = 0; i < localStorage.length; i++) {
      if ((localStorage.key(i) || "").indexOf(keyPrefix) > -1) {
        localStorage.removeItem(localStorage.key(i));
      }
    } // save under this version

    localStorage[getVersionedKey(keyPrefix)] = value;
  };

  var load = function load(keyPrefix) {
    if (!hasLocalStorage(keyPrefix)) {
      return null;
    }

    return localStorage[getVersionedKey(keyPrefix)];
  };

  var getClientPerformance = function getClientPerformance() {
    return window.performance === null ? null : window.performance;
  };

  var fetchResults = function fetchResults(ids) {
    var clientPerformance, clientProbes, i, j, p, id, idx;

    for (i = 0; i < ids.length; i++) {
      id = ids[i];
      clientPerformance = null;
      clientProbes = null;

      if (window.mPt) {
        clientProbes = mPt.results();

        for (j = 0; j < clientProbes.length; j++) {
          clientProbes[j].d = clientProbes[j].d.getTime();
        }

        mPt.flush();
      }

      if (id == options.currentId) {
        clientPerformance = getClientPerformance();

        if (clientPerformance !== null) {
          // ie is buggy strip out functions
          var copy = {
            navigation: {},
            timing: clientPerformance.timing.toJSON()
          };

          if (clientPerformance.navigation) {
            copy.navigation.redirectCount =
              clientPerformance.navigation.redirectCount;
          }

          clientPerformance = copy;
        }
      } else if (
        ajaxStartTime !== null &&
        clientProbes &&
        clientProbes.length > 0
      ) {
        clientPerformance = {
          timing: {
            navigationStart: ajaxStartTime.getTime()
          }
        };
        ajaxStartTime = null;
      }

      if (fetchedIds.indexOf(id) < 0 && fetchingIds.indexOf(id) < 0) {
        idx = fetchingIds.push(id) - 1;

        (function() {
          var request = new XMLHttpRequest();
          var url = options.path + "results";
          var params = {
            id: id,
            clientPerformance: clientPerformance,
            clientProbes: clientProbes,
            popup: 1
          };
          var queryParam = toQueryString(params);
          request.open("POST", url, true);

          request.onload = function() {
            if (request.status >= 200 && request.status < 400) {
              var json = JSON.parse(request.responseText);
              fetchedIds.push(id);

              if (json != "hidden" && MiniProfiler.templates) {
                buttonShow(json);
              }
            }

            fetchingIds.splice(idx, 1);
          };

          request.setRequestHeader("Accept", "application/json");
          request.setRequestHeader("X-Requested-With", "XMLHttpRequest");
          request.setRequestHeader(
            "Content-Type",
            "application/x-www-form-urlencoded"
          );
          request.send(queryParam);
        })();
      }
    }
  };

  var toQueryString = function toQueryString(data, parentKey) {
    var result = [];
    for (var key in data) {
      var val = data[key];
      var newKey = !parentKey ? key : parentKey + "[" + key + "]";
      if (
        typeof val === "object" &&
        !Array.isArray(val) &&
        val !== null &&
        val !== undefined
      ) {
        result[result.length] = toQueryString(val, newKey);
      } else {
        if (Array.isArray(val)) {
          val.forEach(function(v) {
            result[result.length] =
              encodeURIComponent(newKey + "[]") + "=" + encodeURIComponent(v);
          });
        } else if (val === null || val === undefined) {
          result[result.length] = encodeURIComponent(newKey) + "=";
        } else {
          result[result.length] =
            encodeURIComponent(newKey) +
            "=" +
            encodeURIComponent(val.toString());
        }
      }
    }
    return result
      .filter(function(element) {
        return element && element.length > 0;
      })
      .join("&");
  };

  var renderTemplate = function renderTemplate(json) {
    var textDom = MiniProfiler.templates.profilerTemplate(json);
    var tempElement = document.createElement("DIV");
    tempElement.innerHTML = textDom;
    return tempElement.children[0];
  };

  var buttonShow = function buttonShow(json) {
    var result = renderTemplate(json);
    totalTime += parseFloat(json.duration_milliseconds, 10);
    totalSqlCount += parseInt(json.sql_count);
    reqs++;

    if (!controls && reqs > 1 && options.collapseResults && !expandedResults) {
      if (!totalsControl) {
        toArray(container.querySelectorAll(".profiler-result")).forEach(
          function(el) {
            return (el.style.display = "none");
          }
        );
        totalsControl = document.createElement("div");
        totalsControl.setAttribute("class", "profiler-result");
        totalsControl.innerHTML =
          "<div class='profiler-button profiler-totals'></div>";
        container.appendChild(totalsControl);
        totalsControl.addEventListener("click", function() {
          toArray(
            totalsControl.parentNode.querySelectorAll(".profiler-result")
          ).forEach(function(el) {
            return (el.style.display = "block");
          });
          totalsControl.style.display = "none";
          expandedResults = true;
        });
        toArray(totalsControl.querySelectorAll(".profiler-button")).forEach(
          function(el) {
            return (el.style.display = "block");
          }
        );
      }

      var reqsHtml =
        reqs > 1 ? "<span class='profiler-reqs'>" + reqs + "</span>" : "";
      var sqlHtml =
        options.showTotalSqlCount && totalSqlCount > 0
          ? " / <span class='profiler-number'>" +
            totalSqlCount +
            "</span> <span class='profiler-unit'>sql</span>"
          : "";
      totalsControl.querySelector(".profiler-button").innerHTML =
        "<span class='profiler-number'>" +
        totalTime.toFixed(1) +
        "</span> <span class='profiler-unit'>ms</span>" +
        sqlHtml +
        reqsHtml;
      result.style.display = "none";
    }

    if (controls) result.insertBefore(controls);
    else container.appendChild(result);
    var button = result.querySelector(".profiler-button"),
      popup = result.querySelector(".profiler-popup"); // button will appear in corner with the total profiling duration - click to show details

    button.addEventListener("click", function() {
      buttonClick(button, popup);
    }); // small duration steps and the column with aggregate durations are hidden by default; allow toggling

    toggleHidden(popup); // lightbox in the queries

    toArray(popup.querySelectorAll(".profiler-queries-show")).forEach(function(
      el
    ) {
      el.addEventListener("click", function() {
        queriesShow(this, result);
      });
    }); // limit count

    if (
      container.querySelectorAll(".profiler-result").length >
      options.maxTracesToShow
    ) {
      var elem = container.querySelector(".profiler-result");

      if (elem) {
        elem.parentElement.removeChild(elem);
      }
    }

    button.style.display = "block";
  };

  var toggleHidden = function toggleHidden(popup) {
    var trivial = popup.querySelector(".profiler-toggle-trivial");
    var childrenTime = popup.querySelector(
      ".profiler-toggle-duration-with-children"
    );
    var trivialGaps = popup.parentNode.querySelector(
      ".profiler-toggle-trivial-gaps"
    );

    var toggleIt = function toggleIt(node) {
      var link = node,
        klass =
          "profiler-" +
          link.getAttribute("class").substr("profiler-toggle-".length),
        isHidden = link.textContent.indexOf("show") > -1;
      var elements = toArray(popup.parentNode.querySelectorAll("." + klass));

      if (isHidden) {
        elements.forEach(function(el) {
          return (el.style.display = "table-row");
        });
      } else {
        elements.forEach(function(el) {
          return (el.style.display = "none");
        });
      }

      var text = link.textContent;
      link.textContent = text.replace(
        isHidden ? "show" : "hide",
        isHidden ? "hide" : "show"
      );
      popupPreventHorizontalScroll(popup);
    };

    [childrenTime, trivial, trivialGaps].forEach(function(el) {
      if (el) {
        el.addEventListener("click", function() {
          toggleIt(this);
        });
      }
    }); // if option is set or all our timings are trivial, go ahead and show them

    if (
      trivial &&
      (options.showTrivial || trivial.getAttribute("show-on-load"))
    ) {
      toggleIt(trivial);
    } // if option is set, go ahead and show time with children

    if (childrenTime && options.showChildrenTime) {
      toggleIt(childrenTime);
    }
  };

  var toArray = function toArray(list) {
    var arr = [];

    if (!list) {
      return arr;
    }

    for (var i = 0; i < list.length; i++) {
      arr.push(list[i]);
    }

    return arr;
  };

  var buttonClick = function buttonClick(button, popup) {
    // we're toggling this button/popup
    if (popup.offsetWidth > 0 || popup.offsetHeight > 0) {
      // if visible
      popupHide(button, popup);
    } else {
      var visiblePopups = toArray(
        container.querySelectorAll(".profiler-popup")
      ).filter(function(el) {
        return el.offsetWidth > 0 || el.offsetHeight > 0;
      }); // theirButtons = visiblePopups.siblings(".profiler-button");

      var theirButtons = [];
      visiblePopups.forEach(function(el) {
        theirButtons.push(el.parentNode.querySelector(".profiler-button"));
      }); // hide any other popups

      popupHide(theirButtons, visiblePopups); // before showing the one we clicked

      popupShow(button, popup);
    }
  };

  var popupShow = function popupShow(button, popup) {
    button.classList.add("profiler-button-active");
    popupSetDimensions(button, popup);
    popup.style.display = "block";
    popupPreventHorizontalScroll(popup);
  };

  var popupSetDimensions = function popupSetDimensions(button, popup) {
    var px = button.offsetTop - 1,
      // position next to the button we clicked
      windowHeight = window.innerHeight,
      maxHeight = windowHeight - px - 40, // make sure the popup doesn't extend below the fold
      pxVertical = options.renderVerticalPosition === 'bottom' ? button.offsetParent.clientHeight - 21 - px : px;

    popup.style[options.renderVerticalPosition] = "".concat(pxVertical, "px");
    popup.style.maxHeight = "".concat(maxHeight, "px");
    popup.style[options.renderHorizontalPosition] = "".concat(
      button.offsetWidth - 3,
      "px"
    ); // move left or right, based on config
  };

  var popupPreventHorizontalScroll = function popupPreventHorizontalScroll(
    popup
  ) {
    var childrenHeight = 0;
    toArray(popup.children).forEach(function(el) {
      childrenHeight += el.offsetHeight;
    });
    popup.style.paddingRight = "".concat(
      childrenHeight > popup.offsetHeight ? 40 : 10,
      "px"
    );
  };

  var popupHide = function popupHide(button, popup) {
    if (button) {
      if (Array.isArray(button)) {
        button.forEach(function(el) {
          return el.classList.remove("profiler-button-active");
        });
      } else {
        button.classList.remove("profiler-button-active");
      }
    }

    if (popup) {
      if (Array.isArray(popup)) {
        popup.forEach(function(el) {
          return (el.style.display = "none");
        });
      } else {
        popup.style.display = "none";
      }
    }
  };

  var queriesShow = function queriesShow(link, result) {
    result = result;
    var px = 30,
      win = window,
      width = win.innerWidth - 2 * px,
      height = win.innerHeight - 2 * px,
      queries = result.querySelector(".profiler-queries"); // opaque background

    var background = document.createElement("div");
    background.classList.add("profiler-queries-bg");
    document.body.appendChild(background);
    background.style.height = "".concat(window.innerHeight, "px");
    background.style.display = "block"; // center the queries and ensure long content is scrolled

    queries.style[options.renderVerticalPosition] = "".concat(px, "px");
    queries.style.maxHeight = "".concat(height, "px");
    queries.style.width = "".concat(width, "px");
    queries.style[options.renderHorizontalPosition] = "".concat(px, "px");
    queries.querySelector("table").style.width = "".concat(width, "px"); // have to show everything before we can get a position for the first query

    queries.style.display = "block";
    queriesScrollIntoView(link, queries, queries); // syntax highlighting

    prettyPrint();
  };

  var queriesScrollIntoView = function queriesScrollIntoView(
    link,
    queries,
    whatToScroll
  ) {
    var id = elementClosest(link, "tr").getAttribute("data-timing-id"),
      cells = toArray(
        queries.querySelectorAll('tr[data-timing-id="' + id + '"]')
      ); // ensure they're in view

    whatToScroll.scrollTop =
      (whatToScroll.scrollTop || 0) + cells[0].offsetTop - 100; // highlight and then fade back to original bg color; do it ourselves to prevent any conflicts w/ jquery.UI or other implementations of Resig's color plugin

    cells.forEach(function(el) {
      el.classList.add("higlight-animate");
    });
    setTimeout(function() {
      cells.forEach(function(el) {
        return el.classList.remove("higlight-animate");
      });
    }, 3000);
  };

  var onTurboBeforeVisit = function onTurboBeforeVisit(e) {
    if(!e.defaultPrevented) {
      window.MiniProfilerContainer = document.querySelector('body > .profiler-results')
      window.MiniProfiler.pageTransition()
    }
  }

  var onTurboLoad = function onTurboLoad(e) {
    if(window.MiniProfilerContainer) {
      document.body.appendChild(window.MiniProfilerContainer)
    }
  }

  var onClickEvents = function onClickEvents(e) {
    // this happens on every keystroke, and :visible is crazy expensive in IE <9
    // and in this case, the display:none check is sufficient.
    var popup = toArray(document.querySelectorAll(".profiler-popup")).filter(
      function(el) {
        return el.style.display === "block";
      }
    );

    if (!popup.length) {
      return;
    }

    popup = popup[0];
    var button = popup.parentNode.querySelector(".profiler-button"),
      queries = elementClosest(popup, ".profiler-result").querySelector(
        ".profiler-queries"
      ),
      bg = document.querySelector(".profiler-queries-bg"),
      isEscPress = e.type == "keyup" && e.which == 27,
      hidePopup = false,
      hideQueries = false;

    if (bg && bg.style.display === "block") {
      hideQueries =
        isEscPress ||
        (e.type == "click" &&
          !(queries !== e.target && queries.contains(e.target)) &&
          !(popup !== e.target && popup.contains(e.target)));
    } else if (popup.style.display === "block") {
      hidePopup =
        isEscPress ||
        (e.type == "click" &&
          !(popup !== e.target && popup.contains(e.target)) &&
          !(button !== e.target && button.contains(e.target)) &&
          button != e.target);
    }

    if (hideQueries) {
      bg.parentElement.removeChild(bg);
      queries.style.display = "none";
    }

    if (hidePopup) {
      popupHide(button, popup);
    }
  };

  var keydownEvent = function keydownEvent() {
    var results = document.querySelector(".profiler-results");

    if (results.style.display === "none") {
      results.style.display = "block";
    } else {
      results.style.display = "none";
    }

    sessionStorage["rack-mini-profiler-start-hidden"] =
      results.style.display === "none";
  };

  var toggleShortcutEvent = function toggleShortcutEvent(e) {
    // simplified version of https://github.com/jeresig/jquery.hotkeys/blob/master/jquery.hotkeys.js
    var shortcut = options.toggleShortcut.toLowerCase();
    var modifier = "";
    ["alt", "ctrl", "shift"].forEach(function(k) {
      if (e[k + "Key"]) {
        modifier += "".concat(k, "+");
      }
    });
    var specialKeys = {
      8: "backspace",
      9: "tab",
      10: "return",
      13: "return",
      16: "shift",
      17: "ctrl",
      18: "alt",
      27: "esc",
      32: "space",
      59: ";",
      61: "=",
      96: "0",
      97: "1",
      98: "2",
      99: "3",
      100: "4",
      101: "5",
      102: "6",
      103: "7",
      104: "8",
      105: "9",
      106: "*",
      107: "+",
      109: "-",
      110: ".",
      173: "-",
      186: ";",
      187: "="
    };
    var shiftNums = {
      "`": "~",
      "1": "!",
      "2": "@",
      "3": "#",
      "4": "$",
      "5": "%",
      "6": "^",
      "7": "&",
      "8": "*",
      "9": "(",
      "0": ")",
      "-": "_",
      "=": "+",
      ";": ": ",
      "'": '"',
      ",": "<",
      ".": ">",
      "/": "?",
      "\\": "|"
    };
    var character = String.fromCharCode(e.which).toLowerCase();
    var special = specialKeys[e.which];
    var keys = [];

    if (special) {
      keys.push(special);
    } else {
      keys.push(character);
      keys.push(shiftNums[character]);
    }

    for (var i = 0; i < keys.length; i++) {
      if (modifier + keys[i] === shortcut) {
        keydownEvent();
        break;
      }
    }
  };

  var turbolinksSkipResultsFetch = function turbolinksSkipResultsFetch(event) {
    event.data.xhr.__miniProfilerSkipResultsFetch = true;
  };

  var bindDocumentEvents = function bindDocumentEvents() {
    document.addEventListener("click", onClickEvents);
    document.addEventListener("keyup", onClickEvents);
    document.addEventListener("keyup", toggleShortcutEvent);

    if (typeof Turbolinks !== "undefined" && Turbolinks.supported) {
      document.addEventListener("page:change", unbindDocumentEvents);
      document.addEventListener("turbolinks:load", unbindDocumentEvents);
      document.addEventListener(
        "turbolinks:request-start",
        turbolinksSkipResultsFetch
      );
    }

    if (options.hotwireTurboDriveSupport) {
      document.addEventListener("turbo:before-visit", onTurboBeforeVisit)
      document.addEventListener("turbo:load", onTurboLoad)
    }
  };

  var unbindDocumentEvents = function unbindDocumentEvents() {
    document.removeEventListener("click", onClickEvents);
    document.removeEventListener("keyup", onClickEvents);
    document.removeEventListener("keyup", toggleShortcutEvent);
    document.removeEventListener("page:change", unbindDocumentEvents);
    document.removeEventListener("turbolinks:load", unbindDocumentEvents);
    document.removeEventListener(
      "turbolinks:request-start",
      turbolinksSkipResultsFetch
    );
    document.removeEventListener("turbo:before-visit", onTurboBeforeVisit);
    document.removeEventListener("turbo:load", onTurboLoad);
  };

  var initFullView = function initFullView() {
    // profiler will be defined in the full page's head
    container[0].appendChild(renderTemplate(profiler));
    var popup = document.querySelector(".profiler-popup");
    toggleHidden(popup);
    prettyPrint(); // since queries are already shown, just highlight and scroll when clicking a "1 sql" link

    toArray(popup.querySelectorAll(".profiler-queries-show")).forEach(function(
      el
    ) {
      el.addEventListener("click", function() {
        queriesScrollIntoView(
          this,
          document.querySelector(".profiler-queries"),
          document.body
        );
      });
    });
  };

  var initSnapshots = function initSnapshots(dataElement) {
    var data = JSON.parse(dataElement.textContent);
    var temp = document.createElement("DIV");
    if (data.page === "overview") {
      temp.innerHTML = MiniProfiler.templates.snapshotsGroupsList(data);
    } else if (data.group_name) {
      var allCustomFieldsNames = [];
      data.list.forEach(function(snapshot) {
        Object.keys(snapshot.custom_fields).forEach(function(k) {
          if (
            allCustomFieldsNames.indexOf(k) === -1 &&
            options.hiddenCustomFields.indexOf(k.toLowerCase()) === -1
          ) {
            allCustomFieldsNames.push(k);
          }
        });
      });
      allCustomFieldsNames.sort();
      temp.innerHTML = MiniProfiler.templates.snapshotsList({
        data: data,
        allCustomFieldsNames: allCustomFieldsNames
      });
    }
    Array.from(temp.children).forEach(function(child) {
      document.body.appendChild(child);
    });
  };

  var initControls = function initControls(container) {
    if (options.showControls) {
      var _controls = document.createElement("div");

      _controls.classList.add("profiler-controls");

      _controls.innerHTML =
        '<span class="profiler-min-max">m</span><span class="profiler-clear">c</span>';
      container.appendChild(_controls);
      document
        .querySelector(".profiler-controls .profiler-min-max")
        .addEventListener("click", function() {
          return toggleClass(container, "profiler-min");
        });
      container.addEventListener("mouseenter", function() {
        if (this.classList.contains("profiler-min")) {
          this.querySelector(".profiler-min-max").style.display = "block";
        }
      });
      container.addEventListener("mouseleave", function() {
        if (this.classList.contains("profiler-min")) {
          this.querySelector(".profiler-min-max").style.display = "none";
        }
      });
      document
        .querySelector(".profiler-controls .profiler-clear")
        .addEventListener("click", function() {
          toArray(container.querySelectorAll(".profiler-result")).forEach(
            function(el) {
              return el.parentElement.removeChild(el);
            }
          );
        });
    } else {
      container.classList.add("profiler-no-controls");
    }
  };

  var toggleClass = function toggleClass(el, className) {
    if (el.classList) {
      el.classList.toggle(className);
    } else {
      var classes = el.className.split(" ");
      var existingIndex = classes.indexOf(className);
      if (existingIndex >= 0) classes.splice(existingIndex, 1);
      else classes.push(className);
      el.className = classes.join(" ");
    }
  };

  var initPopupView = function initPopupView() {
    if (options.authorized) {
      // all fetched profilings will go in here
      container = document.createElement("div");
      container.className = "profiler-results";
      document.querySelector(options.htmlContainer).appendChild(container); // MiniProfiler.RenderIncludes() sets which corner to render in - default is upper left

      container.classList.add("profiler-" + options.renderHorizontalPosition);
      container.classList.add("profiler-" + options.renderVerticalPosition); //initialize the controls

      initControls(container);
      fetchResults(options.ids);

      if (options.startHidden) container.style.display = "none";
    } else {
      fetchResults(options.ids);
    }

    if (!window.MiniProfiler || !window.MiniProfiler.patchesApplied) {
      var send = XMLHttpRequest.prototype.send;

      XMLHttpRequest.prototype.send = function(data) {
        ajaxStartTime = new Date();
        this.addEventListener("load", function() {
          // responseURL isn't available in IE11
          if (
            this.responseURL &&
            this.responseURL.indexOf(window.location.origin) !== 0
          ) {
            return;
          }
          if (this.__miniProfilerSkipResultsFetch) {
            return;
          }
          // getAllResponseHeaders isn't available in Edge.
          var allHeaders = this.getAllResponseHeaders
            ? this.getAllResponseHeaders()
            : null;
          if (
            allHeaders &&
            allHeaders.toLowerCase().indexOf("x-miniprofiler-ids") === -1
          ) {
            return;
          }
          // should be a string of comma-separated ids
          var stringIds = this.getResponseHeader("X-MiniProfiler-Ids");

          if (stringIds) {
            var ids = stringIds.split(",");
            fetchResults(ids);
          }
        });
        send.call(this, data);
      }; // fetch results after ASP Ajax calls

      if (
        typeof Sys != "undefined" &&
        typeof Sys.WebForms != "undefined" &&
        typeof Sys.WebForms.PageRequestManager != "undefined"
      ) {
        // Get the instance of PageRequestManager.
        var PageRequestManager = Sys.WebForms.PageRequestManager.getInstance();
        PageRequestManager.add_endRequest(function(sender, args) {
          if (args) {
            var response = args.get_response();

            if (
              response.get_responseAvailable() &&
              response._xmlHttpRequest !== null
            ) {
              var stringIds = args
                .get_response()
                .getResponseHeader("X-MiniProfiler-Ids");

              if (stringIds) {
                var ids = stringIds.split(",");
                fetchResults(ids);
              }
            }
          }
        });
      } // more Asp.Net callbacks

      if (typeof WebForm_ExecuteCallback == "function") {
        WebForm_ExecuteCallback = (function(callbackObject) {
          // Store original function
          var original = WebForm_ExecuteCallback;
          return function(callbackObject) {
            original(callbackObject);
            var stringIds = callbackObject.xmlRequest.getResponseHeader(
              "X-MiniProfiler-Ids"
            );

            if (stringIds) {
              var ids = stringIds.split(",");
              fetchResults(ids);
            }
          };
        })();
      } // also fetch results after ExtJS requests, in case it is being used

      if (
        typeof Ext != "undefined" &&
        typeof Ext.Ajax != "undefined" &&
        typeof Ext.Ajax.on != "undefined"
      ) {
        // Ext.Ajax is a singleton, so we just have to attach to its 'requestcomplete' event
        Ext.Ajax.on("requestcomplete", function(e, xhr, settings) {
          //iframed file uploads don't have headers
          if (!xhr || !xhr.getResponseHeader) {
            return;
          }

          var stringIds = xhr.getResponseHeader("X-MiniProfiler-Ids");

          if (stringIds) {
            var ids = stringIds.split(",");
            fetchResults(ids);
          }
        });
      }

      if (typeof MooTools != "undefined" && typeof Request != "undefined") {
        Request.prototype.addEvents({
          onComplete: function onComplete() {
            var stringIds = this.xhr.getResponseHeader("X-MiniProfiler-Ids");

            if (stringIds) {
              var ids = stringIds.split(",");
              fetchResults(ids);
            }
          }
        });
      } // add support for AngularJS, which use the basic XMLHttpRequest object.

      if (window.angular && typeof XMLHttpRequest != "undefined") {
        var _send = XMLHttpRequest.prototype.send;

        XMLHttpRequest.prototype.send = function sendReplacement(data) {
          if (this.onreadystatechange) {
            if (
              typeof this.miniprofiler == "undefined" ||
              typeof this.miniprofiler.prev_onreadystatechange == "undefined"
            ) {
              this.miniprofiler = {
                prev_onreadystatechange: this.onreadystatechange
              };

              this.onreadystatechange = function onReadyStateChangeReplacement() {
                if (this.readyState == 4) {
                  var stringIds = this.getResponseHeader("X-MiniProfiler-Ids");

                  if (stringIds) {
                    var ids = stringIds.split(",");
                    fetchResults(ids);
                  }
                }

                if (this.miniprofiler.prev_onreadystatechange !== null)
                  return this.miniprofiler.prev_onreadystatechange.apply(
                    this,
                    arguments
                  );
              };
            }
          }

          return _send.apply(this, arguments);
        };
      } // https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API

      if (typeof window.fetch === "function") {
        var __originalFetch = window.fetch;

        window.fetch = function(input, init) {
          var originalFetchRun = __originalFetch(input, init);

          originalFetchRun.then(function(response) {
            try {
              // look for x-mini-profile-ids
              var entries = response.headers.entries();
              var _iteratorNormalCompletion = true;
              var _didIteratorError = false;
              var _iteratorError = undefined;

              try {
                for (
                  var _iterator = entries[Symbol.iterator](), _step;
                  !(_iteratorNormalCompletion = (_step = _iterator.next())
                    .done);
                  _iteratorNormalCompletion = true
                ) {
                  var pair = _step.value;

                  if (
                    pair[0] &&
                    pair[0].toLowerCase() == "x-miniprofiler-ids"
                  ) {
                    var ids = pair[1].split(",");
                    fetchResults(ids);
                  }
                }
              } catch (err) {
                _didIteratorError = true;
                _iteratorError = err;
              } finally {
                try {
                  if (!_iteratorNormalCompletion && _iterator.return != null) {
                    _iterator.return();
                  }
                } finally {
                  if (_didIteratorError) {
                    throw _iteratorError;
                  }
                }
              }
            } catch (e) {
              console.error(e);
            }
          });
          return originalFetchRun;
        };
      }
      window.MiniProfiler.patchesApplied = true;
    }

    bindDocumentEvents();
  };

  return {
    fetchedIds: fetchedIds,
    fetchingIds: fetchingIds,
    init: function init() {
      var script = document.getElementById("mini-profiler");
      if (!script || !script.getAttribute) return;

      this.options = options = (function() {
        var version = script.getAttribute("data-version");
        var path = script.getAttribute("data-path");
        var currentId = script.getAttribute("data-current-id");
        var ids = script.getAttribute("data-ids");
        if (ids) ids = ids.split(",");
        var horizontal_position = script.getAttribute(
          "data-horizontal-position"
        );
        var vertical_position = script.getAttribute("data-vertical-position");
        var toggleShortcut = script.getAttribute("data-toggle-shortcut");

        if (script.getAttribute("data-max-traces")) {
          var maxTraces = parseInt(script.getAttribute("data-max-traces"), 10);
        }

        var collapseResults =
          script.getAttribute("data-collapse-results") === "true";
        var trivial = script.getAttribute("data-trivial") === "true";
        var children = script.getAttribute("data-children") === "true";
        var controls = script.getAttribute("data-controls") === "true";
        var totalSqlCount =
          script.getAttribute("data-total-sql-count") === "true";
        var authorized = script.getAttribute("data-authorized") === "true";
        var startHidden =
          script.getAttribute("data-start-hidden") === "true" ||
          sessionStorage["rack-mini-profiler-start-hidden"] === "true";
        var htmlContainer = script.getAttribute("data-html-container");
        var cssUrl = script.getAttribute("data-css-url");
        var hiddenCustomFields = script
          .getAttribute("data-hidden-custom-fields")
          .toLowerCase()
          .split(",");
        var hotwireTurboDriveSupport = script
          .getAttribute('data-turbo-permanent') === "true";
        return {
          ids: ids,
          path: path,
          version: version,
          renderHorizontalPosition: horizontal_position,
          renderVerticalPosition: vertical_position,
          showTrivial: trivial,
          showChildrenTime: children,
          maxTracesToShow: maxTraces,
          showControls: controls,
          showTotalSqlCount: totalSqlCount,
          currentId: currentId,
          authorized: authorized,
          toggleShortcut: toggleShortcut,
          startHidden: startHidden,
          collapseResults: collapseResults,
          htmlContainer: htmlContainer,
          cssUrl: cssUrl,
          hiddenCustomFields: hiddenCustomFields,
          hotwireTurboDriveSupport: hotwireTurboDriveSupport
        };
      })();

      var doInit = function doInit() {
        var snapshotsElement = document.getElementById("snapshots-data");
        if (snapshotsElement != null) {
          initSnapshots(snapshotsElement);
          return;
        }

        // when rendering a shared, full page, this div will exist
        container = document.querySelectorAll(".profiler-result-full");

        if (container.length) {
          if (window.location.href.indexOf("&trivial=1") > 0) {
            options.showTrivial = true;
          }

          initFullView();
        } else {
          initPopupView();
        }
      }; // this preserves debugging

      var load = function load(s, f) {
        var sc = document.createElement("script");
        sc.async = "async";
        sc.type = "text/javascript";
        sc.src = s;
        var done = false;

        sc.onload = sc.onreadystatechange = function(_, abort) {
          if (!sc.readyState || /loaded|complete/.test(sc.readyState)) {
            if (!abort && !done) {
              done = true;
              f();
            }
          }
        };

        document.getElementsByTagName("head")[0].appendChild(sc);
      };

      var wait = 0;
      var finish = false;

      var deferInit = function deferInit() {
        if (finish) return;

        if (
          window.performance &&
          window.performance.timing &&
          window.performance.timing.loadEventEnd === 0 &&
          wait < 10000
        ) {
          setTimeout(deferInit, 100);
          wait += 100;
        } else {
          finish = true;
          init();
        }
      };

      var init = function init() {
        if (options.authorized) {
          var url = options.cssUrl;

          if (document.createStyleSheet) {
            document.createStyleSheet(url);
          } else {
            var head = document.querySelector("head");
            var link = document.createElement("link");
            link.rel = "stylesheet";
            link.type = "text/css";
            link.href = url;
            head.appendChild(link);
          }

          if (!MiniProfiler.loadedVendor) {
            load(options.path + "vendor.js?v=" + options.version, doInit);
          } else {
            doInit();
          }
        } else {
          doInit();
        }
      };

      deferInit();
    },
    cleanUp: function cleanUp() {
      unbindDocumentEvents();
    },
    pageTransition: function pageTransition() {
      if (totalsControl) {
        if (totalsControl.parentElement) {
          totalsControl.parentElement.removeChild(totalsControl);
        }
        totalsControl = null;
      }

      reqs = 0;
      totalTime = 0;
      expandedResults = false;
      toArray(
        document.querySelectorAll(".profiler-results .profiler-result")
      ).forEach(function(el) {
        return el.parentElement.removeChild(el);
      });
    },
    getClientTimingByName: function getClientTimingByName(clientTiming, name) {
      for (var i = 0; i < clientTiming.timings.length; i++) {
        if (clientTiming.timings[i].name == name) {
          return clientTiming.timings[i];
        }
      }

      return {
        Name: name,
        Duration: "",
        Start: ""
      };
    },
    renderDate: function renderDate(jsonDate) {
      // JavaScriptSerializer sends dates as /Date(1308024322065)/
      if (jsonDate) {
        return typeof jsonDate === "string"
          ? new Date(
              parseInt(jsonDate.replace("/Date(", "").replace(")/", ""), 10)
            ).toUTCString()
          : jsonDate;
      }
    },
    renderIndent: function renderIndent(depth) {
      var result = "";

      for (var i = 0; i < depth; i++) {
        result += "&nbsp;";
      }

      return result;
    },
    renderExecuteType: function renderExecuteType(typeId) {
      // see StackExchange.Profiling.ExecuteType enum
      switch (typeId) {
        case 0:
          return "None";

        case 1:
          return "NonQuery";

        case 2:
          return "Scalar";

        case 3:
          return "Reader";
      }
    },
    shareUrl: function shareUrl(id) {
      return options.path + "results?id=" + id;
    },
    flamegraphUrl: function flamegrapgUrl(id) {
      return options.path + "flamegraph?id=" + id;
    },
    moreUrl: function moreUrl(requestName) {
      var linkSuffix = requestName.indexOf("?") > 0 ? "&pp=help" : "?pp=help";
      return requestName + linkSuffix;
    },
    getClientTimings: function getClientTimings(clientTimings) {
      var list = [];
      var t;
      if (!clientTimings.timings) return [];

      for (var i = 0; i < clientTimings.timings.length; i++) {
        t = clientTimings.timings[i];
        var trivial = t.Name != "Dom Complete" && t.Name != "Response";
        trivial = t.Duration < 2 ? trivial : false;
        list.push({
          isTrivial: trivial,
          name: t.Name,
          duration: t.Duration,
          start: t.Start
        });
      } // Use the Paint Timing API for render performance.

      if (window.performance && window.performance.getEntriesByName) {
        var firstPaint = window.performance.getEntriesByName("first-paint");

        if (firstPaint !== undefined && firstPaint.length >= 1) {
          list.push({
            isTrivial: false,
            name: "First Paint Time",
            duration: firstPaint[0].duration,
            start: firstPaint[0].startTime
          });
        }
      }

      list.sort(function(a, b) {
        return a.start - b.start;
      });
      return list;
    },
    getSqlTimings: function getSqlTimings(root) {
      var result = [],
        addToResults = function addToResults(timing) {
          if (timing.sql_timings) {
            for (var i = 0, sqlTiming; i < timing.sql_timings.length; i++) {
              sqlTiming = timing.sql_timings[i]; // HACK: add info about the parent Timing to each SqlTiming so UI can render

              sqlTiming.parent_timing_name = timing.name;

              if (sqlTiming.duration_milliseconds > 50) {
                sqlTiming.row_class = "slow";
              }

              if (sqlTiming.duration_milliseconds > 200) {
                sqlTiming.row_class = "very-slow";
              }

              if (sqlTiming.duration_milliseconds > 400) {
                sqlTiming.row_class = "very-very-slow";
              }

              result.push(sqlTiming);
            }
          }

          if (timing.children) {
            for (var i = 0; i < timing.children.length; i++) {
              addToResults(timing.children[i]);
            }
          }
        }; // start adding at the root and recurse down

      addToResults(root);

      var removeDuration = function removeDuration(list, duration) {
        var newList = [];

        for (var i = 0; i < list.length; i++) {
          var item = list[i];

          if (duration.start > item.start) {
            if (duration.start > item.finish) {
              newList.push(item);
              continue;
            }

            newList.push({
              start: item.start,
              finish: duration.start
            });
          }

          if (duration.finish < item.finish) {
            if (duration.finish < item.start) {
              newList.push(item);
              continue;
            }

            newList.push({
              start: duration.finish,
              finish: item.finish
            });
          }
        }

        return newList;
      };

      var processTimes = function processTimes(elem, parent) {
        var duration = {
          start: elem.start_milliseconds,
          finish: elem.start_milliseconds + elem.duration_milliseconds
        };
        elem.richTiming = [duration];

        if (parent !== null) {
          elem.parent = parent;
          elem.parent.richTiming = removeDuration(
            elem.parent.richTiming,
            duration
          );
        }

        if (elem.children) {
          for (var i = 0; i < elem.children.length; i++) {
            processTimes(elem.children[i], elem);
          }
        }
      };

      processTimes(root, null); // sort results by time

      result.sort(function(a, b) {
        return a.start_milliseconds - b.start_milliseconds;
      });

      var determineOverlap = function determineOverlap(gap, node) {
        var overlap = 0;

        for (var i = 0; i < node.richTiming.length; i++) {
          var current = node.richTiming[i];

          if (current.start > gap.finish) {
            break;
          }

          if (current.finish < gap.start) {
            continue;
          }

          overlap +=
            Math.min(gap.finish, current.finish) -
            Math.max(gap.start, current.start);
        }

        return overlap;
      };

      var determineGap = function determineGap(gap, node, match) {
        var overlap = determineOverlap(gap, node);

        if (match === null || overlap > match.duration) {
          match = {
            name: node.name,
            duration: overlap
          };
        } else if (match.name == node.name) {
          match.duration += overlap;
        }

        if (node.children) {
          for (var i = 0; i < node.children.length; i++) {
            match = determineGap(gap, node.children[i], match);
          }
        }

        return match;
      };

      var time = 0;
      var prev = null;
      result.forEach(function(r) {
        r.prevGap = {
          duration: (r.start_milliseconds - time).toFixed(2),
          start: time,
          finish: r.start_milliseconds
        };
        r.prevGap.topReason = determineGap(r.prevGap, root, null);
        time = r.start_milliseconds + r.duration_milliseconds;
        prev = r;
      });

      if (result.length > 0) {
        var me = result[result.length - 1];
        me.nextGap = {
          duration: (root.duration_milliseconds - time).toFixed(2),
          start: time,
          finish: root.duration_milliseconds
        };
        me.nextGap.topReason = determineGap(me.nextGap, root, null);
      }

      return result;
    },
    getSqlTimingsCount: function getSqlTimingsCount(root) {
      var result = 0,
        countSql = function countSql(timing) {
          if (timing.sql_timings) {
            result += timing.sql_timings.length;
          }

          if (timing.children) {
            for (var i = 0; i < timing.children.length; i++) {
              countSql(timing.children[i]);
            }
          }
        };

      countSql(root);
      return result;
    },
    fetchResultsExposed: function fetchResultsExposed(ids) {
      return fetchResults(ids);
    },
    formatParameters: function formatParameters(parameters) {
      if (parameters != null) {
        return parameters
          .map(function(item, index) {
            return "[" + item[0] + ", " + item[1] + "]";
          })
          .join(", ");
      } else {
        return "";
      }
    },
    formatDuration: function formatDuration(duration) {
      return (duration || 0).toFixed(1);
    },
    showTotalSqlCount: function showTotalSqlCount() {
      return options.showTotalSqlCount;
    },
    timestampToRelative: function timestampToRelative(timestamp) {
      var now = Math.round(new Date().getTime() / 1000);
      timestamp = Math.round(timestamp / 1000);
      var diff = now - timestamp;
      if (diff < 60) {
        return "< 1 minute";
      }
      var buildDisplayTime = function buildDisplayTime(num, unit) {
        var res = num + " " + unit;
        if (num !== 1) {
          res += "s";
        }
        return res;
      };
      diff = Math.round(diff / 60);
      if (diff <= 60) {
        return buildDisplayTime(diff, "minute");
      }
      diff = Math.round(diff / 60);
      if (diff <= 24) {
        return buildDisplayTime(diff, "hour");
      }
      diff = Math.round(diff / 24);
      return buildDisplayTime(diff, "day");
    }
  };
})();

if (window.MiniProfiler) {
  _MiniProfiler.patchesApplied = window.MiniProfiler.patchesApplied;
}
window.MiniProfiler = _MiniProfiler;
_MiniProfiler.init();
