-- client.lua

-- Load config
local config = Config or {}
local discord = config.discord or {}

-- Predeclare essential FiveM functions and globals
local SendNUIMessage = SendNUIMessage
local SetNuiFocus = SetNuiFocus
local GetGameTimer = GetGameTimer
local GetCurrentResourceName = GetCurrentResourceName
local RegisterNetEvent = RegisterNetEvent
local AddEventHandler = AddEventHandler
local RegisterNUICallback = RegisterNUICallback
local json = json

-- Security environment setup
local _ENV = _ENV
local type = type
local tostring = tostring
local string = string
local print = print
local pcall = pcall
local rawset = rawset
local error = error

-- Log client events by sending to server
local function logClientEvent(title, description)
    TriggerServerEvent('antiExploit:logClientEvent', title, description)
end

-- Security note: Removed overly restrictive global protection to prevent FiveM compatibility issues

-- Security variables
local lastMessageTime = 0
local messageCooldown = 3000
local MAX_MESSAGE_LENGTH = 1000
local MESSAGE_ATTEMPTS = {}
local MAX_ATTEMPTS = 5
local ATTEMPT_WINDOW = 60000

-- Rate limiting function
local function isRateLimited(identifier)
    local currentTime = GetGameTimer()
    MESSAGE_ATTEMPTS[identifier] = MESSAGE_ATTEMPTS[identifier] or {count = 0, firstAttempt = currentTime}
    if currentTime - MESSAGE_ATTEMPTS[identifier].firstAttempt > ATTEMPT_WINDOW then
        MESSAGE_ATTEMPTS[identifier] = {count = 1, firstAttempt = currentTime}
        return false
    end
    MESSAGE_ATTEMPTS[identifier].count = MESSAGE_ATTEMPTS[identifier].count + 1
    return MESSAGE_ATTEMPTS[identifier].count > MAX_ATTEMPTS
end

-- HTML sanitizer
local function sanitizeHTML(html)
    if type(html) ~= 'string' then return '' end
    html = html:gsub("&", "&amp;")
               :gsub("<", "&lt;")
               :gsub(">", "&gt;")
               :gsub('"', "&quot;")
               :gsub("'", "&#x27;")
               :gsub("/", "&#x2F;")
    if html:lower():match("javascript:") or html:lower():match("data:") then
        logClientEvent("Dangerous Content Blocked", "Attempted to inject script/data URI")
        return "[BLOCKED] Dangerous content detected"
    end
    return html
end

-- Secure event handler for displaying message on client
RegisterNetEvent("secure:showMessage")
AddEventHandler("secure:showMessage", function(rawMessage)
    local clientId = "client"

    if isRateLimited(clientId) then
        print("^1Rate limit exceeded for client^0")
        logClientEvent("Client Rate Limited", "Too many messages received")
        return
    end

    local currentTime = GetGameTimer()

    if currentTime - lastMessageTime < messageCooldown then
        print("^3Warning: Too many messages in a short time^0")
        logClientEvent("Message Cooldown", "Messages too frequent")
        return
    end
    lastMessageTime = currentTime

    if type(rawMessage) ~= "string" or rawMessage == "" then
        print("^1Invalid message received^0")
        logClientEvent("Invalid Message", "Type: " .. type(rawMessage))
        return
    end

    if #rawMessage > MAX_MESSAGE_LENGTH then
        print("^1Message exceeds maximum length^0")
        logClientEvent("Oversized Message", "Length: " .. #rawMessage)
        rawMessage = rawMessage:sub(1, MAX_MESSAGE_LENGTH) .. "..."
    end

    local cleanMessage = sanitizeHTML(rawMessage)

    local success, err = pcall(SendNUIMessage, {
        action = "showMessage",
        content = cleanMessage,
        timestamp = currentTime,
        verified = true
    })

    if not success then
        print("^1Error in NUI message dispatch: " .. tostring(err) .. "^0")
        logClientEvent("NUI Error", tostring(err))
        return
    end

    SetNuiFocus(true, true)

    print("^2Safe message displayed:^0 " .. cleanMessage)
    logClientEvent("Message Displayed", "Length: " .. #cleanMessage)
end)

-- Resource protection
local resourceName = GetCurrentResourceName()

-- Use proper FiveM resource event handling
Citizen.CreateThread(function()
    print("^2Resource started: " .. resourceName .. "^0")
    logClientEvent("Resource Started", "Client script initialized")
end)

-- Ensure RegisterNUICallback is available (FiveM provides this natively)
if not RegisterNUICallback then
    print("^1Warning: RegisterNUICallback not available^0")
end
