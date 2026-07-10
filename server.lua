-- server.lua

-- Load config
local config = Config or {}
local discord = config.discord or {}

-- Constants
local MAX_MESSAGE_LENGTH = 1000
local MAX_ATTEMPTS = 5
local ATTEMPT_WINDOW = 60000 -- 1 minute
local LAST_LOG_TIME = 0
local MESSAGE_ATTEMPTS = {}

-- Discord logging function
local function sendToDiscord(title, description, color)
    if not discord.serverLogs then return end

    local currentTime = GetGameTimer()
    if currentTime - LAST_LOG_TIME < (discord.logCooldown or 5000) then return end
    LAST_LOG_TIME = currentTime

    local embed = {
        {
            ["color"] = color or 16711680,
            ["title"] = title,
            ["description"] = description,
            ["footer"] = {
                ["text"] = os.date("%c") .. " | " .. GetCurrentResourceName(),
            },
        }
    }

    PerformHttpRequest(discord.serverLogs, function(err, text, headers)
        if err ~= 200 then
            print(string.format("^1Discord log failed: %s | %s^0", tostring(err), tostring(text)))
        end
    end, 'POST', json.encode({
        username = discord.serverName or "tech-SecureShield Logger",
        avatar_url = discord.serverAvatar or "",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Rate limiting
local function isRateLimited(source)
    local currentTime = os.time() * 1000
    MESSAGE_ATTEMPTS[source] = MESSAGE_ATTEMPTS[source] or { count = 0, firstAttempt = currentTime }

    if currentTime - MESSAGE_ATTEMPTS[source].firstAttempt > ATTEMPT_WINDOW then
        MESSAGE_ATTEMPTS[source] = { count = 1, firstAttempt = currentTime }
        return false
    end

    MESSAGE_ATTEMPTS[source].count = MESSAGE_ATTEMPTS[source].count + 1
    return MESSAGE_ATTEMPTS[source].count > MAX_ATTEMPTS
end

-- Input validation
local function validateInput(message, targetId)
    if type(message) ~= "string" then
        return false, "Invalid message type"
    end
    if #message > MAX_MESSAGE_LENGTH then
        return false, "Message too long"
    end
    if type(targetId) ~= "number" then
        return false, "Invalid target ID"
    end
    return true
end

-- Event handler for admin messages
RegisterNetEvent('secure:showMessage', function(targetId, message)
    local src = source
    local srcName = GetPlayerName(src) or "Unknown"

    -- Source validation
    if not src or src <= 0 then
        print("^1[SECURE] Invalid source^0")
        sendToDiscord("🚨 Invalid Source", "Attempt from invalid source ID", 16711680)
        return
    end

    -- Rate limit check
    if isRateLimited(src) then
        print(("^1Rate limit exceeded for %s^0"):format(src))
        sendToDiscord("⚠️ Rate Limit Exceeded", ("Player %s (%s) exceeded rate limits"):format(srcName, src), 16776960)
        DropPlayer(src, "Rate limit exceeded")
        return
    end

    -- Permissions check
    if not IsPlayerAceAllowed(src, 'admin.menu') then
        print(("^1Unauthorized message attempt from %s^0"):format(srcName))
        sendToDiscord("🚫 Unauthorized Access", ("Player %s (%s) attempted admin message"):format(srcName, src), 16711680)
        DropPlayer(src, "Unauthorized message attempt")
        return
    end

    -- Input validation
    local isValid, errMsg = validateInput(message, targetId)
    if not isValid then
        print(("^1Input validation failed: %s^0"):format(errMsg))
        sendToDiscord("❌ Invalid Input", ("Player %s (%s) sent invalid input: %s"):format(srcName, src, errMsg), 16711680)
        DropPlayer(src, "Invalid message format")
        return
    end

    -- Target player check
    local targetName = GetPlayerName(targetId)
    if not targetName then
        print(("^3Invalid target ID (%s) by %s^0"):format(targetId, srcName))
        sendToDiscord("⚠️ Invalid Target", ("Admin %s attempted to message invalid target %s"):format(srcName, targetId), 16776960)
        return
    end

    -- Log action
    print(("^2Admin %s sending message to %s^0"):format(srcName, targetName))
    sendToDiscord("📨 Admin Message Sent", ("Admin **%s** sent to **%s**:\n```\n%s\n```"):format(srcName, targetName, message), 65280)

    -- Trigger message
    local success, err = pcall(function()
        TriggerClientEvent('secure:showMessage', targetId, message)
    end)

    if not success then
        print(("^1Error sending message: %s^0"):format(err))
        sendToDiscord("❌ Message Failed", ("Failed to send message from %s to %s: %s"):format(srcName, targetName, err), 16711680)
    end
end)

-- Server-side logging from client
RegisterNetEvent('antiExploit:logClientEvent')
AddEventHandler('antiExploit:logClientEvent', function(title, description)
    local src = source
    local playerName = GetPlayerName(src) or "Unknown"
    sendToDiscord("[CLIENT] "..title, ("From %s (%d):\n%s"):format(playerName, src, description), 16711680)
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        MESSAGE_ATTEMPTS = {}
        sendToDiscord("🔴 Resource Stopped", "tech-SecureShield system has been stopped", 16711680)
    end
end)

-- Log on resource start
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        sendToDiscord("🟢 Resource Started", "tech-SecureShield system initialized", 65280)
    end
end)

-- Test webhook on startup
CreateThread(function()
    Wait(1000)
    if discord.serverLogs then
        PerformHttpRequest(discord.serverLogs, function(err)
            print("^2✅ Webhook test sent. Response code: " .. tostring(err) .. "^0")
        end, 'POST', json.encode({
            content = "✅ Webhook test successful."
        }), { ['Content-Type'] = 'application/json' })
    else
        print("^3⚠️ No Discord webhook configured in config.lua^0")
    end
end)