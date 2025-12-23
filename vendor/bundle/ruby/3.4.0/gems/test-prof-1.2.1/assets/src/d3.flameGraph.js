(function() {
  'use strict';

  function flameGraph() {

    var w = 960, // graph width
      h = 540, // graph height
      c = 18, // cell height
      selection = null, // selection
      tooltip = true, // enable tooltip
      title = "", // graph title
      transitionDuration = 750,
      transitionEase = d3.easeCubic, // tooltip offset
      sort = true,
      reversed = false, // reverse the graph direction
      clickHandler = null;

    var tip = d3.tip()
      .direction("s")
      .offset([8, 0])
      .attr('class', 'd3-flame-graph-tip')
      .html(function(d) { return label(d); });

    var svg;

    var label = function(d) {
      return d.data.name + " (" + d3.format(".3f")(100 * (d.x1 - d.x0), 3) + "%, " + d.data.value + " samples)";
    };

    function setDetails(t) {
      var details = document.getElementById("details");
      if (details)
        details.innerHTML = t;
    }

    function name(d) {
      return d.data.name;
    }

    var colorMapper = function(d) {
      return d.highlight ? "#E600E6" : colorHash(d.data);
    };

    function generateHash(name) {
      // Return a vector (0.0->1.0) that is a hash of the input string.
      // The hash is computed to favor early characters over later ones, so
      // that strings with similar starts have similar vectors. Only the first
      // 6 characters are considered.
      var hash = 0, weight = 1, max_hash = 0, mod = 10, max_char = 6;
      if (name) {
        for (var i = 0; i < name.length; i++) {
          if (i > max_char) { break; }
          hash += weight * (name.charCodeAt(i) % mod);
          max_hash += weight * (mod - 1);
          weight *= 0.70;
        }
        if (max_hash > 0) { hash = hash / max_hash; }
      }
      return hash;
    }

    function colorHash(data) {
      var name = data.name;

      if (data.color) {
        return data.color;
      }
      // Return an rgb() color string that is a hash of the provided name,
      // and with a warm palette.
      var vector = 0;
      if (name) {
        name = name.replace(/.*`/, "");		// drop module name if present
        name = name.replace(/\(.*/, "");	// drop extra info
        vector = generateHash(name);
      }
      var r = 200 + Math.round(55 * vector);
      var g = 0 + Math.round(230 * vector);
      var b = 0 + Math.round(55 * vector);
      data.color = "rgb(" + r + "," + g + "," + b + ")";
      return data.color;
    }

    function hide(d) {
      if(!d.data.original) {
        d.data.original = d.data.value;
      }
      d.data.value = 0;
      if(d.children) {
        d.children.forEach(hide);
      }
    }

    function show(d) {
      d.data.fade = false;
      if(d.data.original) {
        d.data.value = d.data.original;
      }
      if(d.children) {
        d.children.forEach(show);
      }
    }

    function getSiblings(d) {
      var siblings = [];
      if (d.parent) {
        var me = d.parent.children.indexOf(d);
        siblings = d.parent.children.slice(0);
        siblings.splice(me, 1);
      }
      return siblings;
    }

    function hideSiblings(d) {
      var siblings = getSiblings(d);
      siblings.forEach(function(s) {
        hide(s);
      });
      if(d.parent) {
        hideSiblings(d.parent);
      }
    }

    function fadeAncestors(d) {
      if(d.parent) {
        d.parent.data.fade = true;
        fadeAncestors(d.parent);
      }
    }

    function getRoot(d) {
      if(d.parent) {
        return getRoot(d.parent);
      }
      return d;
    }

    function zoom(d) {
      tip.hide(d);
      hideSiblings(d);
      show(d);
      fadeAncestors(d);
      update();
      if (typeof clickHandler === 'function') {
        clickHandler(d);
      }
    }

    function searchTree(d, term) {
      var re = new RegExp(term),
          searchResults = [];

      function searchInner(d) {
        var label = d.data.name;

        if (d.children) {
          d.children.forEach(function (child) {
            searchInner(child);
          });
        }

        if (label.match(re)) {
          d.highlight = true;
          searchResults.push(d);
        } else {
          d.highlight = false;
        }
      }

      searchInner(d);
      return searchResults;
    }

    function clear(d) {
      d.highlight = false;
      if(d.children) {
        d.children.forEach(function(child) {
          clear(child);
        });
      }
    }

    function doSort(a, b) {
      if (typeof sort === 'function') {
        return sort(a, b);
      } else if (sort) {
        return d3.ascending(a.data.name, b.data.name);
      } else {
        return 0;
      }
    }

    var partition = d3.partition();

    function update() {

      selection.each(function(root) {
        var x = d3.scaleLinear().range([0, w]),
            y = d3.scaleLinear().range([0, c]);

        root.sort(doSort);
        root.sum(function(d) {
          if (d.fade) {
            return 0;
          }
          // The node's self value is its total value minus all children.
          var v = d.v || d.value || 0;
          if (d.children) {
            for (var i = 0; i < d.children.length; i++) {
              v -= d.children[i].value;
            }
          }
          return v;
        });
        partition(root);

        var kx = w / (root.x1 - root.x0);
        function width(d) { return (d.x1 - d.x0) * kx; }

        var g = d3.select(this).select("svg").selectAll("g").data(root.descendants());

        g.transition()
          .duration(transitionDuration)
          .ease(transitionEase)
          .attr("transform", function(d) { return "translate(" + x(d.x0) + ","
            + (reversed ? y(d.depth) : (h - y(d.depth) - c)) + ")"; });

        g.select("rect").transition()
          .duration(transitionDuration)
          .ease(transitionEase)
          .attr("width", width);

        var node = g.enter()
          .append("svg:g")
          .attr("transform", function(d) { return "translate(" + x(d.x0) + ","
            + (reversed ? y(d.depth) : (h - y(d.depth) - c)) + ")"; });

        node.append("svg:rect").attr("width", width);

        if (!tooltip)
          node.append("svg:title");

        node.append("foreignObject")
          .append("xhtml:div");

        // Now we have to re-select to see the new elements (why?).
        g = d3.select(this).select("svg").selectAll("g").data(root.descendants());

        g.attr("width", width)
          .attr("height", function(d) { return c; })
          .attr("name", function(d) { return d.data.name; })
          .attr("class", function(d) { return d.data.fade ? "frame fade" : "frame"; });

        g.select("rect")
          .attr("height", function(d) { return c; })
          .attr("fill", function(d) { return colorMapper(d); });

        if (!tooltip)
          g.select("title")
            .text(label);

        g.select("foreignObject")
          .attr("width", width)
          .attr("height", function(d) { return c; })
          .select("div")
          .attr("class", "label")
          .style("display", function(d) { return (width(d) < 35) ? "none" : "block";})
          .text(name);

        g.on('click', zoom);

        g.exit().remove();

        g.on('mouseover', function(d) {
          if (tooltip) tip.show(d);
          setDetails(label(d));
        }).on('mouseout', function(d) {
          if (tooltip) tip.hide(d);
          setDetails("");
        });
      });
    }

    function merge(data, samples) {
      samples.forEach(function (sample) {
        var node = _.find(data, function (element) {
          return element.name === sample.name;
        });

        if (node) {
          if (node.original) {
            node.original += sample.value;
          } else {
            node.value += sample.value;
          }
          if (sample.children) {
            if (!node.children) {
              node.children = [];
            }
            merge(node.children, sample.children)
          }
        } else {
          data.push(sample);
        }
      });
    }

    function chart(s) {
      var root = d3.hierarchy(s.datum(), function(d) { return d.c || d.children; });
      selection = s.datum(root);

      if (!arguments.length) return chart;

      selection.each(function(data) {

	      if (!svg) {
          svg = d3.select(this)
            .append("svg:svg")
            .attr("width", w)
            .attr("height", h)
            .attr("class", "partition d3-flame-graph")
            .call(tip);

          svg.append("svg:text")
            .attr("class", "title")
            .attr("text-anchor", "middle")
            .attr("y", "25")
            .attr("x", w/2)
            .attr("fill", "#808080")
            .text(title);
        }
      });

      // first draw
      update();
    }

    chart.height = function (_) {
      if (!arguments.length) { return h; }
      h = _;
      return chart;
    };

    chart.width = function (_) {
      if (!arguments.length) { return w; }
      w = _;
      return chart;
    };

    chart.cellHeight = function (_) {
      if (!arguments.length) { return c; }
      c = _;
      return chart;
    };

    chart.tooltip = function (_) {
      if (!arguments.length) { return tooltip; }
      if (typeof _ === "function") {
        tip = _;
      }
      tooltip = true;
      return chart;
    };

    chart.title = function (_) {
      if (!arguments.length) { return title; }
      title = _;
      return chart;
    };

    chart.transitionDuration = function (_) {
      if (!arguments.length) { return transitionDuration; }
      transitionDuration = _;
      return chart;
    };

    chart.transitionEase = function (_) {
      if (!arguments.length) { return transitionEase; }
      transitionEase = _;
      return chart;
    };

    chart.sort = function (_) {
      if (!arguments.length) { return sort; }
      sort = _;
      return chart;
    };

    chart.reversed = function (_) {
      if (!arguments.length) { return reversed; }
      reversed = _;
      return chart;
    };

    chart.label = function(_) {
      if (!arguments.length) { return label; }
      label = _;
      return chart;
    };

    chart.search = function(term) {
      var searchResults = [];
      selection.each(function(data) {
        searchResults = searchTree(data, term);
        update();
      });
      return searchResults;
    };

    chart.clear = function() {
      selection.each(function(data) {
        clear(data);
        update();
      });
    };

    chart.zoomTo = function(d) {
      zoom(d);
    };

    chart.resetZoom = function() {
      selection.each(function (data) {
        zoom(data); // zoom to root
      });
    };

    chart.onClick = function(_) {
      if (!arguments.length) {
        return clickHandler;
      }
      clickHandler = _;
      return chart;
    };
    
    chart.merge = function(samples) {
      var newRoot; // Need to re-create hierarchy after data changes.
      selection.each(function (root) {
        merge([root.data], [samples]);
        newRoot = d3.hierarchy(root.data, function(d) { return d.c || d.children; });
      });
      selection = selection.datum(newRoot);
      update();
    }
    
    chart.color = function(_) {
      if (!arguments.length) { return colorMapper; }
      colorMapper = _;
      return chart;
    };

    return chart;
  }

  if (typeof module !== 'undefined' && module.exports){
		module.exports = flameGraph;
	}
	else {
		d3.flameGraph = flameGraph;
	}
})();
