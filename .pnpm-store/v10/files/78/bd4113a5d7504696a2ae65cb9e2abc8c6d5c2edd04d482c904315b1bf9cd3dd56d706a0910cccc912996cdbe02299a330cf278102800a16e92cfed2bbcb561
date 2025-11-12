'use strict';

var expect = require('expect.js');
var dijkstra = require('../dijkstra.js');
var find_path = dijkstra.find_path;

describe('dijkstra.js', function () {

    describe('.find_path()', function () {

        it('should find the path between two points, all edges have weight 1', function () {
            // A B C
            // D E F
            // G H I
            var graph = {
                a: {b: 10, d: 1},
                b: {a: 1, c: 1, e: 1},
                c: {b: 1, f: 1},
                d: {a: 1, e: 1, g: 1},
                e: {b: 1, d: 1, f: 1, h: 1},
                f: {c: 1, e: 1, i: 1},
                g: {d: 1, h: 1},
                h: {e: 1, g: 1, i: 1},
                i: {f: 1, h: 1}
            };
            var path = find_path(graph, 'a', 'i');
            expect(path).to.eql(['a', 'd', 'e', 'f', 'i']);
        });

        it('should find the path between two points, weighted edges', function () {
            var graph = {
                a: {b: 10, c: 100, d: 1},
                b: {c: 10},
                d: {b: 1, e: 1},
                e: {f: 1},
                f: {c: 1},
                g: {b: 1}
            };

            var path = find_path(graph, 'a', 'c');
            expect(path).to.eql(['a', 'd', 'e', 'f', 'c']);
            path = find_path(graph, 'd', 'b');
            expect(path).to.eql(['d', 'b']);
        });

        it('should throw on unreachable destination', function () {
            var graph = {
                a: {b: 10, c: 100, d: 1},
                b: {c: 10},
                d: {b: 1, e: 1},
                e: {f: 1},
                f: {c: 1},
                g: {b: 1}
            };

            expect(function () { find_path(graph, 'c', 'a'); }).to.throwException();
            expect(function () { find_path(graph, 'a', 'g'); }).to.throwException();
        });

        it('should throw on non-existent destination', function () {
            var graph = {
                a: {b: 10, c: 100, d: 1},
                b: {c: 10},
                d: {b: 1, e: 1},
                e: {f: 1},
                f: {c: 1},
                g: {b: 1}
            };

            expect(function () { find_path(graph, 'a', 'z'); }).to.throwException();
        });
    });

    describe('.single_source_shortest_paths()', function () {
        it('should find all paths from a node', function () {
            var graph = {
                a: {b: 10, c: 100, d: 1},
                b: {c: 10},
                d: {b: 1, e: 1},
                e: {f: 1},
                f: {c: 1},
                g: {b: 1}
            };

            // All paths from 'a'
            var paths = dijkstra.single_source_shortest_paths(graph, 'a');
            expect(paths).to.eql({
                d: 'a',
                b: 'd',
                e: 'd',
                f: 'e',
                c: 'f'
            });
        });
    });
});
