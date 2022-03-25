require 'asledgehammer/util'
require 'asledgehammer/class'
require 'crafthammer/plugin/module'

CraftHammer = class(function(o)
    -- Debug flag for global debugging CraftHammer's Lua framework.
    o.DEBUG = false;
    -- List of the module.
    o.modules = {};
    -- List of the module by their Names.
    o.modulesByName = {};
    -- List of the module by their IDs.
    o.modulesByID = {};
    -- Load flag.
    o.loaded = false;
    -- Start flag.
    o.started = false;
    o.delayStartSeconds = 1;
    o.delayStart = false;
    o.handshakeAttempt = 1;
    -- List of CraftHammer Player LuaObjects, identified via ID.
    o.players = {};
    -- Map of CraftHammer Player LuaObjects, identified via string (username).
    o.playersByName = {};
    -- Player Object for the player running this engine.
    o.self = nil;
end);

----------------------------------------------------------------
-- Initializes the CraftHammer Lua Framework.
----------------------------------------------------------------
function CraftHammer:init()
    local startTimeStamp = getTimestamp();
    print("Initializing CraftHammer Lua framework. Version: " ..
              tostring(CraftHammer:getVersion()));
    if preloaded_modules_index > 0 then
        -- Grab the length of the preloaded module table.
        local length = preloaded_modules_index - 1;
        -- Formally register preloaded module.
        for index = 0, length, 1 do
            local nextModule = preloaded_modules[index];
            self:register(nextModule);
        end
        -- nullify the preload table.
        preloaded_modules_index = 0;
        preloaded_modules = nil;
    end
    -- Set loaded flag.
    self.loaded = true;
    -- Initialization time.
    self.initTimeStamp = getTimestamp();
    -- Register the update method.
    Events.OnTickEvenPaused.Add(update_crafthammer);
    print("CraftHammer initialized. Took " ..
              tostring(self.initTimeStamp - startTimeStamp) .. " seconds.");
end

----------------------------------------------------------------
-- Starts the CraftHammer Lua Framework.
----------------------------------------------------------------
function CraftHammer:start()
    -- Register the command method.
    Events.OnServerCommand.Add(command_crafthammer);
    self.startTimeStamp = getTimestamp();
    self:doHandshake();
    self.started = true;
end

----------------------------------------------------------------
-- Handles CraftHammer protocol.
----------------------------------------------------------------
function CraftHammer:onHandshake()
    -- Start Modules after the initial handshake for CraftHammer.
    self:startModules();
    -- Also Handshake Modules.
    self:handshakeModules();
end

function CraftHammer:doHandshake()
    local handshakeSuccess = function(table, request)
        -- Flag the handshake as successful.
        CraftHammer.instance.handshake = true;
        if CraftHammer.instance.DEBUG then print("Handshake accepted!"); end
        CraftHammer.instance:onHandshake();
    end
    local handshakeFailure = function(error, request)
        if CraftHammer.instance.DEBUG then
            print("Handshake failed. ErrorCode: " .. tostring(error));
        end
    end
    local handshake = Request("crafthammer.module.core", "handshake", nil,
                              handshakeSuccess, handshakeFailure);
    handshake:send();
end

----------------------------------------------------------------
-- Handles the updates for the CraftHammer Lua Framework. 
----------------------------------------------------------------
function CraftHammer:update()
    if self.hasUpdated == true then
        -- As of Build 37.14, there is a bug where 'sendClientCommand()' does not send to the server until after
        -- the first update tick. Cycling the update tick once fixes that problem.
        if not self.started then self:start(); end
        self:updateModules();
    end
    self.hasUpdated = true;
end

----------------------------------------------------------------
-- Loads the Modules registered.
----------------------------------------------------------------
function CraftHammer:loadModules()
    -- Get the length of the module.
    local length = tLength(self.modules) - 1;
    -- Go through each module.
    for index = 0, length, 1 do
        -- Grab the next module.
        local nextModule = self.modules[index];
        if nextModule ~= nil then self:loadModule(nextModule); end
    end
end

----------------------------------------------------------------
-- Starts the Modules registered.
----------------------------------------------------------------
function CraftHammer:startModules()
    -- Get the length of the module.
    local length = tLength(self.modules) - 1;
    -- Go through each module.
    for index = 0, length, 1 do
        -- Grab the next module.
        local nextModule = self.modules[index];
        if nextModule ~= nil then self:startModule(nextModule); end
    end
end

----------------------------------------------------------------
-- Handshakes all registered Modules.
----------------------------------------------------------------
function CraftHammer:handshakeModules()
    -- Get the length of the module.
    local length = tLength(self.modules) - 1;
    -- Go through each module.
    for index = 0, length, 1 do
        -- Grab the next module.
        local nextModule = self.modules[index];
        if nextModule ~= nil then self:handshakeModule(nextModule); end
    end
end

----------------------------------------------------------------
-- Updates the Modules registered.
----------------------------------------------------------------
function CraftHammer:updateModules()
    -- Get the length of the module.
    local length = tLength(self.modules) - 1;
    -- Go through each module.
    for index = 0, length, 1 do
        -- Grab the next module.
        local nextModule = self.modules[index];
        -- If the Module is valid.
        if nextModule ~= nil and nextModule:isLoaded() and
            nextModule:isStarted() then
            -- Update the module.
            nextModule:update();
        end
    end
end

----------------------------------------------------------------
-- Stops the Modules registered.
----------------------------------------------------------------
function CraftHammer:stopModules()
    -- Get the length of the module.
    local length = tLength(self.modules) - 1;
    -- Go through each module.
    for index = 0, length, 1 do
        -- Grab the next module.
        local nextModule = self.modules[index];
    end
end

----------------------------------------------------------------
-- Unloads the Modules registered.
----------------------------------------------------------------
function CraftHammer:unloadModules()
    -- Get the length of the module.
    local length = tLength(self.modules) - 1;
    -- Go through each module.
    for index = 0, length, 1 do
        -- Grab the next module.
        local nextModule = self.modules[index];
        if nextModule ~= nil then self:unloadModule(nextModule); end
    end
    self.modules = {};
end

----------------------------------------------------------------
-- Loads a Module.
----------------------------------------------------------------
function CraftHammer:loadModule(mod)
    if mod == nil then return; end
    if mod:isLoaded() then return; end
    print("CraftHammer: Loading Module: '" .. tostring(mod:getName()) .. "'.");
    mod:load();
    mod.loaded = true;
end

----------------------------------------------------------------
-- Starts a Module. (Loads the Module if not done already)
----------------------------------------------------------------
function CraftHammer:startModule(mod)
    if mod == nil then return; end
    if mod:isStarted() then return; end
    if mod:isUnloaded() then self:loadModule(mod); end
    print("CraftHammer: Starting Module: '" .. tostring(mod:getName()) .. "'.");
    mod:start();
    mod.started = true;
end

----------------------------------------------------------------
-- Handshakes a Module. 
----------------------------------------------------------------
function CraftHammer:handshakeModule(mod)
    if mod == nil then return; end
    if mod:isStopped() then return; end
    if mod:isHandshaked() then return; end
    mod:handshake();
    mod.handshaked = true;
end

----------------------------------------------------------------
-- Stops a Module.
----------------------------------------------------------------
function CraftHammer:stopModule(mod)
    if mod == nil then return; end
    if mod:isStopped() then return; end
    print("CraftHammer: Stopping Module: '" .. tostring(mod:getName()) .. "'.");
    mod:stop();
    mod.started = false;
end

----------------------------------------------------------------
-- Unloads a Module. (Stops the Module if not stopped already)
----------------------------------------------------------------
function CraftHammer:unloadModule(mod)
    if mod == nil then return; end
    if mod:isUnloaded() then return; end
    if mod:isStarted() then self:stopModule(mod); end
    print("CraftHammer: Unloading Module: '" .. tostring(mod:getName()) .. "'.");
    mod:unload();
    mod.loaded = false;
end

----------------------------------------------------------------
-- Sends commands to the Server-Side CraftHammer module.
--
-- @string mod 		Module name.
-- @string command 	Command being sent to the Module.
-- @table args 		Arguments passed to the Module. 
----------------------------------------------------------------
function CraftHammer:sendCommand(mod, command, args)
    -- Validity check.
    if mod == nil then
        print("Module given is null!");
        return;
    end
    -- Validity check.
    if command == nil then
        print("Module Command given is null!");
        return;
    elseif command == "" then
        print("Module Command given is empty!");
        return;
    end
    -- Send to the Server. (zombie.Lua.LuaManager)
    sendClientCommand(mod, command, args);
end

----------------------------------------------------------------
-- Handles Client-side CraftHammer Module commands.
--
-- @string mod 		Module name.
-- @string command 	Command being sent to the Module.
-- @table args 		Arguments passed to the Module.
----------------------------------------------------------------
function CraftHammer:onClientCommand(mod, command, args)
    -- Checks to see if this is a module command.
    if luautils.stringStarts(mod, "crafthammer.module.") then
        -- Converts to simple module name.
        local modName = toSimpleModuleName(mod);
        -- If this is the core, route directly and return.
        if modName == "core" then
            if command == "debug" then
                self.DEBUG = args.debug;
            elseif command == "reload" then
                self:stopModules();
                self:unloadModules();
                self.modules = {};
                self.modulesByID = {};
                self.handshake = false;
                self:doHandshake();
            elseif command == "sendLua" then
                local func = load_function(args.lua);
                func();
                return;
            elseif command == "sendSelf" then
                -- Grab the Player and the information.
                local player = args.player;
                local id = player.id;
                local name = player.username;
                -- Set the Player object in the maps.
                self.players[id] = player;
                self.playersByName[name] = player;
                self.self = player;
            elseif command == "sendPlayer" then
                -- Grab the Player and the information.
                local player = args.player;
                local id = player.id;
                local name = player.username;
                -- Set the Player object in the maps.
                self.players[id] = player;
                self.playersByName[name] = player;
            end
        end
        -- Grab the module being commanded.
        local modu = self.modulesByID[modName];
        -- Validity check.
        if modu == nil then
            -- print("CraftHammer: Module is null: '" .. tostring(modName) .. "', for command: '" .. command .. "'.");
            return;
        end
        -- Handle the command.
        modu:command(command, args);
    end
end

----------------------------------------------------------------
-- Registers a Module.
----------------------------------------------------------------
function CraftHammer:register(mod)
    -- Validity check.
    if mod == nil then
        print("CraftHammer:register() -> Module given is null!");
        return;
    end
    -- Validity check.
    if tContainsValue(self.modules, mod) then
        print("CraftHammer:register() -> Module already registered: '" ..
                  tostring(mod) .. "'.");
        return;
    end
    -- Grab the next index.
    local length = tLength(self.modules);
    -- Add the module.
    self.modules[length] = mod;
    self.modulesByID[mod:getID()] = mod;
    self.modulesByName[mod:getName()] = mod;
    -- If CraftHammer is not initialized yet, return.
    if not self:isLoaded() then return; end
    -- Check to see if the Module needs to load.
    if not mod:isLoaded() then self:loadModule(mod); end
    -- If CraftHammer is not started, return.
    if not self:isStarted() then return; end
    -- Check to see if the Module needs to handshake.
    if not mod:isHandshaked() then self:handshakeModule(mod); end
    -- Check to see if the Module needs to start;
    if not mod:isStarted() then self:startModule(mod); end
end

function CraftHammer:addPlayer(player)
    -- Validity check.
    if player == nil then
        print("Player given is null!");
        return;
    end
    -- Get the size of the players LuaTable.
    local length = tLength(self.players) - 1;
    -- Go through each index of the players LuaTable.
    for index = 0, length, 1 do
        -- Grab the next player.
        local nextPlayer = self.players[index];
        -- If the player is already in the list.
        if player.id == nextPlayer.id then self.players[index] = player; end
    end
    self.playersByName[player.nickname] = player;
    self.playersByName[player.username] = player;
end

-- Returns a Player LuaObject, with a given ID, or name. Returns nil if player isn't found.
--
-- TODO: Associate an async request with module.
function CraftHammer:getPlayer(identifier)
    if identifier == nil then
        print("CraftHammer:getPlayer() -> Given Identifier is null!");
        return nil;
    end
    if (type(identifier) == "number") then
        return self.players[identifier];
    elseif type(identifier == "string") then
        return self.playersByName[identifier];
    end
end

function CraftHammer:removePlayer(player)
    print("'CraftHammer:removePlayer()' is not implemented.");
end

----------------------------------------------------------------
-- @return 	Returns whether or not CraftHammer has fully loaded.
----------------------------------------------------------------
function CraftHammer:isLoaded() return self.loaded; end

----------------------------------------------------------------
-- @return 	Returns whether or not CraftHammer is unloaded.
----------------------------------------------------------------
function CraftHammer:isUnloaded() return not self.loaded; end

----------------------------------------------------------------
-- @return 	Returns whether or not CraftHammer has started.
----------------------------------------------------------------
function CraftHammer:isStarted() return self.started; end

----------------------------------------------------------------
-- @return 	Returns whether or not CraftHammer is currently stopped.
----------------------------------------------------------------
function CraftHammer:isStopped() return not self.started; end

----------------------------------------------------------------
-- @return Returns the version of this instance of the CraftHammer Lua Framework.
----------------------------------------------------------------
function CraftHammer:getVersion() return "4.00"; end

----------------------------------------------------------------
-- @return Returns the TimeStamp for the initialization of the CraftHammer Lua Framework.
----------------------------------------------------------------
function CraftHammer:getInitializedTimeStamp()
    return CraftHammer.instance.initTimeStamp;
end

----------------------------------------------------------------
-- @return If CraftHammer is being ran in debug mode.
----------------------------------------------------------------
function CraftHammer:isDebug() return CraftHammer.instance.DEBUG; end

----------------------------------------------------------------
----------------------------------------------------------------
--      ######  ########    ###    ######## ####  ######      --
--     ##    ##    ##      ## ##      ##     ##  ##    ##     --
--     ##          ##     ##   ##     ##     ##  ##           --
--      ######     ##    ##     ##    ##     ##  ##           --
--           ##    ##    #########    ##     ##  ##           --
--     ##    ##    ##    ##     ##    ##     ##  ##    ##     --
--      ######     ##    ##     ##    ##    ####  ######      --
----------------------------------------------------------------
----------------------------------------------------------------

-- List of module to be loaded. (static for preloading)
preloaded_modules = {};
-- Index of pre-loaded module.
preloaded_modules_index = 0;

----------------------------------------------------------------
-- Static method to execute the instantiation of the CraftHammer
-- Lua Framwork.
--
-- @static
----------------------------------------------------------------
function load_crafthammer()
    -- Initialize core and store as Singleton.
    CraftHammer.instance = CraftHammer();
end

----------------------------------------------------------------
-- Static method to execute loading of the CraftHammer Lua 
-- Framework.
--
-- @static
----------------------------------------------------------------
function init_crafthammer() CraftHammer.instance:init(); end

----------------------------------------------------------------
-- Static method to pipe updates on every tick.
--
-- @static
----------------------------------------------------------------
function update_crafthammer()
    update_file_routines();
    CraftHammer.instance:update();
end

----------------------------------------------------------------
-- @static
----------------------------------------------------------------
function command_crafthammer(mod, command, args)
    CraftHammer.instance:onClientCommand(mod, command, args);
end

----------------------------------------------------------------
-- Static method for preloading module.
-- 
-- @static
----------------------------------------------------------------
function register(mod)
    -- Validity check.
    if mod == nil then
        print("register() -> Module is null!");
        return;
    end
    local duplicateRegistry = false;
    local length = 0;
    local nextModule = nil;
    -- If CraftHammer is initialized, use internal tables.
    if CraftHammer.instance ~= nil then
        -- Grab the length of the list.
        length = tLength(CraftHammer.instance.modules) - 1;
        -- Go through all registered Modules.
        for index = 0, length, 1 do
            -- Grab the next Module in the list.
            nextModule = CraftHammer.instance.modules[index];
            -- If the ID's match, then it is a duplicate register.
            if nextModule:getID() == mod:getID() then
                duplicateRegistry = true;
                break
            end
        end
        -- Check to see if the Module is already loaded.
        if duplicateRegistry then
            print("register() -> Module is already registered: " ..
                      tostring(nextModule:getID()));
            return;
        end
        -- Formally register the Module.
        CraftHammer.instance:register(mod);
        -- If CraftHammer is not initialized, use static preloaded tables.
    else
        -- Grab the length of the list.
        length = preloaded_modules_index - 1;
        -- Go through all preoaded Modules.
        for index = 0, length, 1 do
            -- Grab the next Module in the list.
            nextModule = preloaded_modules[index];
            -- If the ID's match, then it is a duplicate register.
            if nextModule:getID() == mod:getID() then
                duplicateRegistry = true;
                break
            end
        end
        -- Check to see if the Module is already preloaded.
        if duplicateRegistry then
            print("register() -> Module is already registered: " ..
                      tostring(nextModule:getID()));
            return;
        end
        -- Set the module.
        preloaded_modules[preloaded_modules_index] = mod;
        -- Increment the index.
        preloaded_modules_index = preloaded_modules_index + 1;
    end
end

file_routines = {};

----------------------------------------------------------------
--
----------------------------------------------------------------
function writeFile(explodedFile)

    local writeBytes = function(fileWriter, bytes)
        for b in string.gmatch(bytes, '([^,]+)') do
            local n = tonumber(b);
            fileWriter:write(toInt(n - 128));
        end
    end

    local writeChars = function(fileWriter, string)
        fileWriter:writeChars(string);
    end

    local run = function()
        print("###| Writing file: " .. explodedFile.path .. "...");
        local fileWriter = getFileOutput(explodedFile.path);
        local length = tLength(explodedFile.segmentTypes) - 1;
        local maxCallsPerYield = 0;
        local offset = 0;
        for index = 0, length, 1 do
            if explodedFile.segmentTypes[index] == 0 then
                writeChars(fileWriter, explodedFile.fileData[index]);
            else
                writeBytes(fileWriter, explodedFile.fileData[index]);
            end
            if offset < maxCallsPerYield then
                offset = offset + 1;
            else
                offset = 0;
                coroutine.yield();
            end
        end
        fileWriter:close();
        print("### File completed: " .. explodedFile.path .. ".");
    end

    file_routines[tLength(file_routines)] = coroutine.create(run);
end

function update_file_routines()
    local length = tLength(file_routines) - 1;
    if length > -1 then
        local ran = false;
        for index = 0, length, 1 do
            local co = file_routines[index];
            if coroutine.status(co) == "suspended" then
                coroutine.resume(co);
                ran = true;
                break
            end
        end
        if not ran then file_routines = {}; end
    end
end

-- Add the creation function to the Event dispatcher.
Events.OnInitWorld.Add(load_crafthammer);

-- Add the initialization function to the Event dispatcher.
Events.OnGameStart.Add(init_crafthammer);
