#!/usr/bin/env node

var port = process.argv[2];

if(!port){

    if(/^win/.test(process.platform)){

        port = 80;
    }
    else{

        port = 8080;
    }
}

var ws = require('web-servo');

ws.config({

    "server": {
        "port": port,
        "dir": "/",
        "exitOnError": false,
        "ssl": {
            "enabled": false,
            "key": "",
            "cert": ""
        }
    },
    "page": {
        "default": "index.html"
    },
    "methods": {
        "allowed": [
            "OPTIONS",
            "GET",
            "POST",
            "HEAD",
            "PUT",
            "PATCH",
            "DELETE"
            //"COPY",
            //"LINK",
            //"UNLINK",
            //"TRACE",
            //"CONNECT"
        ]
    }
});

//ws.setConfigVar('server.port', port);
ws.silent().start();

console.log("-----------------------------------------------------");
console.log("Hit CTRL-C to stop the server...");
