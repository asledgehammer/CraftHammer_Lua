export class Request {
    static ASYNC_ERROR_NONE = 0;
    static ASYNC_ERROR_TIMEOUT = 1;

    private readonly module: string;
    private readonly command: string;
    private readonly args: any[];
    private readonly _timeout: number;
    private readonly _callbackSuccess: RequestSuccess | null;
    private readonly _callbackError: RequestError | null;
    private _started: boolean = false;
    private _timeStarted: number = -1;

    constructor(
        module: string,
        command: string,
        args: any[],
        timeout: number = 5,
        success: RequestSuccess,
        error: RequestError
    ) {
        this.module = module;
        this.command = command;
        this.args = args;
        this._callbackSuccess = success;
        this._callbackError = error;
        this._timeout = timeout;
    }

    public send() {
        if (this._started) return;
        this._timeStarted = new Date().getTime();
        // @ts-ignore Add the dispatch function.
        Events.OnServerCommand.Add(this.dispatch);
        // @ts-ignore Add the ontick function.
        Events.OnTickEvenPaused.Add(this.update);
        // @ts-ignore
        sendClientCommand(self.mod, self.command, self.args);
    }

    public dispatch(module: string, command: string, result: object) {
        if (this.module !== this.module || this.command !== command) {
            return;
        }
        // @ts-ignore Remove from Events list after executing.
        Events.OnServerCommand.Remove(this.dispatch);
        // @ts-ignore Remove the update function from the OnTick Event.
        Events.OnTickEvenPaused.Remove(this.update);
        if (this._callbackSuccess) {
            this._callbackSuccess(result, this);
        }
    }

    public update() {
        let current = new Date().getTime();
        if (current - this._timeStarted > this._timeout) {
            // @ts-ignore Remove dispatch callback function from Events list.
            Events.OnServerCommand.Remove(request.__dispatch);
            // @ts-ignore Remove this function from the OnTick event.
            Events.OnTickEvenPaused.Remove(request.__update);
            if (this._callbackError) {
                this._callbackError(Request.ASYNC_ERROR_TIMEOUT, this);
            }
        }
    }
}

export type RequestSuccess = (result: object, request: Request) => void;
export type RequestError = (error: number, request: Request) => void;
