import { Router } from 'express';
export declare const useProgressReporting: (router: Router, startTime: [
    number,
    number
], options: any) => Promise<{
    handler: any;
    modulesCount: number;
}>;
