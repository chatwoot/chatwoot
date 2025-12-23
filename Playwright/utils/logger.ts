

export class APILogger {

    private recentLogs: any[] = []

    logRequest(method: string, url: string, headers: Record<string, string>, body?: any){
        const logEntry = {method, url, headers, body}
        this.recentLogs.push({type: 'Request Details', data: logEntry})
    }

    logResponse(statusCode: number, body?: any){
        const logEntry = {statusCode, body}
        this.recentLogs.push({type: 'Response Details', data: logEntry})
    }

    getRecentLogs(){
        const logs = this.recentLogs.map(log => {
            return `===${log.type}===\n${JSON.stringify(log.data, null, 4)}`
        }).join('\n\n')
        return logs
    }

}