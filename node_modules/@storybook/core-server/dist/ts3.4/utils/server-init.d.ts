/// <reference types="node" />
import { Express } from 'express';
import http from 'http';
import https from 'https';
export declare function getServer(app: Express, options: {
    https?: boolean;
    sslCert?: string;
    sslKey?: string;
    sslCa?: string[];
}): Promise<http.Server | https.Server>;
