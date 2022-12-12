"use strict";

describe("loglevel included via node", function () {
    it("is included successfully", function () {
        expect(require('../lib/loglevel')).not.toBeUndefined();
    });

    it("allows setting the logging level", function () {
        var log = require('../lib/loglevel');

        log.setLevel(log.levels.TRACE);
        log.setLevel(log.levels.DEBUG);
        log.setLevel(log.levels.INFO);
        log.setLevel(log.levels.WARN);
        log.setLevel(log.levels.ERROR);
    });

    it("successfully logs", function () {
        var log = require('../lib/loglevel');
        console.info = jasmine.createSpy("info");

        log.setLevel(log.levels.INFO);
        log.info("test message");

        expect(console.info).toHaveBeenCalledWith("test message");
    });

    it("supports using symbols as names", function() {
        var log = require('../lib/loglevel');

        var s1 = Symbol("a-symbol");
        var s2 = Symbol("a-symbol");

        var logger1 = log.getLogger(s1);
        var defaultLevel = logger1.getLevel();
        logger1.setLevel(log.levels.TRACE);

        var logger2 = log.getLogger(s2);

        // Should be unequal: same name, but different symbol instances
        expect(logger1).not.toEqual(logger2);
        expect(logger2.getLevel()).toEqual(defaultLevel);
    });
});
