'use strict';

// Discord webhook URL from config
const DISCORD_WEBHOOK = 'https://discord.com/api/webhooks/1395189418956161064/kabNesDqFF0S6vc33ZBKMJjOsw18fyoEmsCblqfVrtRO9_zqZnOZ61awL2e0Kj9tCqI0';

const SecureMessageHandler = (function() {
    // Private constants
    const MAX_MESSAGE_LENGTH = 1000;
    const REFRESH_COOLDOWN = 3000;
    let lastMessageTime = 0;
    let lastLogTime = 0;

    // Enhanced dangerous patterns
    const dangerousPatterns = [
        /javascript:/i, /data:/i, /vbscript:/i, /file:/i, /about:/i,
        /blob:/i, /ws:/i, /wss:/i, /chrome:/i, /ms-/i,
        /<script.*?>.*?<\/script>/i, /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
        /<img[^>]+src[^>]*/i, /<iframe[^>]+src[^>]*/i, /<embed[^>]+src[^>]*/i,
        /<object[^>]+data[^>]*/i, /on\w+\s*=/i, /\bonon\w+\s*=/i,
        /http-equiv[\s]*=[\s]*['"]*refresh['"]/i, /url[\s]*=[\s]*['"]*[^'"]+['"]/i,
        /<base[^>]*>/i, /<svg[^>]*>/i, /expression[\s]*\(/i, /@import/i,
        /localStorage/i, /sessionStorage/i, /&#x?\d+;/i, /\\x[0-9a-f]{2}/i,
        /\\u[0-9a-f]{4}/i, /<link[^>]*>/i, /<style[^>]*>/i, /<meta[^>]*>/i,
        /behavior:/i, /-moz-binding:/i
    ];

    // Enhanced HTML escaping
    const escapeHTML = (unsafe) => {
        if (typeof unsafe !== 'string') return '';
        const div = document.createElement('div');
        div.textContent = unsafe;
        return div.innerHTML
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;")
            .replace(/`/g, "&#x60;")
            .replace(/\$/g, "&#x24;")
            .replace(/\r?\n/g, "<br>");
    };

    // Discord logging function
    const logFrontendEvent = async (title, details) => {
        const currentTime = Date.now();
        if (currentTime - lastLogTime < 5000) return;
        lastLogTime = currentTime;
        
        try {
            await fetch(DISCORD_WEBHOOK, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    username: 'Frontend Security Logs',
                    content: `**${title}**\n${details}\n\`${new Date().toISOString()}\``
                }),
            });
        } catch (error) {
            console.error('Failed to send log:', error);
        }
    };

    // Content security validation
    const isContentSecure = (content) => {
        if (typeof content !== 'string') {
            logFrontendEvent("Invalid Content Type", `Expected string, got ${typeof content}`);
            return false;
        }
        
        if (content.length > MAX_MESSAGE_LENGTH) {
            logFrontendEvent("Oversized Content", `Length: ${content.length}`);
            return false;
        }
        
        const isDangerous = dangerousPatterns.some(pattern => pattern.test(content));
        if (isDangerous) {
            logFrontendEvent("Dangerous Content Blocked", `Content: ${content.substring(0, 100)}...`);
        }
        
        return !isDangerous;
    };

    // Rate limiting check
    const isRateLimited = () => {
        const currentTime = Date.now();
        if (currentTime - lastMessageTime < REFRESH_COOLDOWN) {
            logFrontendEvent("Rate Limited", "Too many messages");
            return true;
        }
        lastMessageTime = currentTime;
        return false;
    };

    // Message display handler
    const displayMessage = (content) => {
        const container = document.getElementById('message-container');
        const message = document.getElementById('message');
        
        if (!container || !message) {
            console.error("Required DOM elements not found");
            logFrontendEvent("DOM Error", "Message elements missing");
            return;
        }

        message.innerHTML = escapeHTML(content);
        container.style.display = "block";
        logFrontendEvent("Message Displayed", `Length: ${content.length}`);
    };

    // Public API
    return {
        handleMessage: function(event) {
            try {
                // Origin verification
                if (event.origin !== window.location.origin) {
                    logFrontendEvent("Unauthorized Origin", 
                        `Blocked: ${event.origin}\nExpected: ${window.location.origin}`);
                    return;
                }

                // Basic validation
                if (!event.data || typeof event.data !== 'object' || !event.data.action) {
                    logFrontendEvent("Invalid Message Format", `Received: ${typeof event.data}`);
                    return;
                }

                const data = event.data;

                // Rate limiting
                if (isRateLimited()) {
                    logFrontendEvent("Rate Limited", "Too frequent messages");
                    return;
                }

                switch (data.action) {
                    case "showMessage":
                        if (!isContentSecure(data.content)) {
                            logFrontendEvent("Blocked Content", "Security check failed");
                            return;
                        }
                        displayMessage(data.content);
                        break;

                    case "close":
                        const container = document.getElementById('message-container');
                        if (container) {
                            container.style.display = "none";
                            logFrontendEvent("UI Closed", "User closed message");
                        }
                        break;

                    default:
                        logFrontendEvent("Unknown Action", `Action: ${data.action || 'undefined'}`);
                }
            } catch (error) {
                console.error("Error processing message:", error);
                logFrontendEvent("Handler Error", error.toString());
            }
        },

        logFrontendEvent,  // expose logging publicly
    };
})();

// Call logFrontendEvent after initialization
SecureMessageHandler.logFrontendEvent("UI Initialized", "Frontend security system ready");

window.addEventListener('message', function(event) {
    try {
        SecureMessageHandler.handleMessage(event);
    } catch (error) {
        console.error("Critical error in message handler:", error);
        SecureMessageHandler.logFrontendEvent("Critical Error", error.toString());
    }
}, false);

// Prevent tampering
Object.freeze(SecureMessageHandler);
