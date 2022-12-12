#!/usr/bin/env node

var detect = require('../index');

detect(function(err, res){
    if (err) {
        process.stderr.write(err);
        process.exit(1);
    }

    // console.log(res)
    process.stdout.write(res.commonName + '\r\n');
});
