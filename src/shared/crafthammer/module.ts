import { Request, RequestError, RequestSuccess } from './util/request';

export abstract class Module {
    readonly properties: ModuleProperties;

    private _loaded: boolean = false;
    private _started: boolean = false;
    private _handshaked: boolean = false;

    constructor(properties: ModuleProperties) {
        this.properties = properties;
    }

    sendRequest(command: string, args: any[], timeout: number, success: RequestSuccess, error: RequestError) {
        let request = new Request('crafthammer.module.' + this.properties.id, command, args, timeout, success, error);
    }

    public get loaded(): boolean {
        return this._loaded;
    }

    public get started(): boolean {
        return this._started;
    }

    public get handshaked(): boolean {
        return this._handshaked;
    }

    public handshake() {
        this.onHandshake();
        this._handshaked = true;
    }

    public load() {
        const { id } = this.properties;
        if (this._loaded) {
            throw new Error(`The module is already loaded: ${id}`);
        }
        this.onLoad();
        this._loaded = true;
    }

    public start() {
        const { id } = this.properties;
        if (!this._loaded) {
            throw new Error(`The module is not loaded: ${id}`);
        } else if (this._started) {
            throw new Error(`The module has already started: ${id}`);
        }
        this.onStart();
        this._started = true;
    }

    public update() {
        const { id } = this.properties;
        if (!this._loaded) {
            throw new Error(`The module is not loaded: ${id}`);
        } else if (!this._started) {
            throw new Error(`The module has not started: ${id}`);
        }
        this.onUpdate();
    }

    public stop() {
        const { id } = this.properties;
        if (!this._loaded) {
            throw new Error(`The module is not loaded: ${id}`);
        } else if (!this._started) {
            throw new Error(`The module has not started: ${id}`);
        }
        this.onStop();
        this._started = false;
    }

    public unload() {
        const { id } = this.properties;
        if (!this._loaded) {
            throw new Error(`The module is not loaded: ${id}`);
        } else if (this._started) {
            throw new Error(`The module is running and cannot be unloaded: ${id}`);
        }
        this.onUnload();
        this._loaded = false;
    }

    protected onHandshake() {}
    protected onLoad() {}
    protected onStart() {}
    protected onUpdate() {}
    protected onStop() {}
    protected onUnload() {}
}

export type ModuleProperties = {
    id: string;
    name: string;
    version: string;
};
