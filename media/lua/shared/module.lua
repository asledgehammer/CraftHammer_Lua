require 'asledgehammer/class'

Module = class(function(o, id, name)

    -- Set the variables.
    o.id = id;
    o.name = name;
    o.version = '1.00';
    o.loaded = false;
    o.started = false;
    o.handshaked = false;
end);

function Module:sendCommand(command, args)
    -- Sends the command to CraftHammer.
    CraftHammer.instance:sendCommand('crafthammer.module.' .. self:getID(),
                                     command, args);
end

function Module:sendRequest(command, args, success, failure)
    local request = Request('crafthammer.module.' .. self:getID(), command,
                            args, success, failure);
    request:send();
end

----------------------------------------------------------------
--
----------------------------------------------------------------
function Module:writeFile(args)
    local packet = args.packet;
    local execute = false;
    if packet == 0 then
        self._explodedFile = args.explodedFile;
        self._explodedFile.segment = 0;
        self._explodedFile.fileData = {};
        self._explodedFile.path =
            "CraftHammer/module/" .. self:getName() .. "/" ..
                self._explodedFile.path;
    elseif packet == 2 then
        execute = true;
    end
    self._explodedFile.segment = self._explodedFile.segment + 1;
    self._explodedFile.fileData[tLength(self._explodedFile.fileData)] =
        args.data;
    print("(" .. self._explodedFile.path .. ") " ..
              tostring(self._explodedFile.segment) .. "/" ..
              tostring(self._explodedFile.segments));
    if execute then
        writeFile(self._explodedFile);
        self._explodedFile = nil;
    end
end

----------------------------------------------------------------
-- @return 	Returns the version of the Module.
----------------------------------------------------------------
function Module:getVersion() return self.version; end

----------------------------------------------------------------
-- Loads the module. Create objects here.
----------------------------------------------------------------
function Module:load() end

----------------------------------------------------------------
-- Starts the module. Add listeners here.
----------------------------------------------------------------
function Module:start() end

----------------------------------------------------------------
-- Place initial Command requests here.
----------------------------------------------------------------
function Module:handshake() end

----------------------------------------------------------------
-- On every in-game Tick, this function is executed.
----------------------------------------------------------------
function Module:update() end

----------------------------------------------------------------
-- Handles a command from the server.
--
-- @string command 	The command given from the server.
-- @table args 		The arguments given with the command.
----------------------------------------------------------------
function Module:command(command, args) end

----------------------------------------------------------------
-- Stops the module. Remove listeners here.
----------------------------------------------------------------
function Module:stop() end

----------------------------------------------------------------
-- Unloads the module. Nullify or deconstruct objects here.
----------------------------------------------------------------
function Module:unload() end

----------------------------------------------------------------
-- @return 	Returns the name of the Module.
----------------------------------------------------------------
function Module:getName() return self.name; end

----------------------------------------------------------------
-- @return 	Returns the ID of the Module.
----------------------------------------------------------------
function Module:getID() return self.id; end

----------------------------------------------------------------
-- @return 	Returns if the Module has started.
----------------------------------------------------------------
function Module:isStarted() return self.started; end

----------------------------------------------------------------
-- @return 	Returns if the Module has handshaked.
----------------------------------------------------------------
function Module:isHandshaked() return self.handshaked; end

----------------------------------------------------------------
-- @return 	Returns if the Module is currently stopped.
----------------------------------------------------------------
function Module:isStopped() return not self.started; end

----------------------------------------------------------------
-- @return 	Returns if the Module has been loaded.
----------------------------------------------------------------
function Module:isLoaded() return self.loaded; end

----------------------------------------------------------------
-- @return 	Returns if the Module is not loaded.
----------------------------------------------------------------
function Module:isUnloaded() return not self.loaded; end
