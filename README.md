# tech-SecureShield
- My Tebex Store tshentro.tebex.io
- If you would like to support me, you can take a look at my scripts: https://tshentro.tebex.io

A secure, multi-layered admin messaging system for FiveM servers with comprehensive security features, rate limiting, and Discord webhook logging.

## 🛡️ Features

### Security Features
- **Multi-layer validation** - Server, client, and frontend validation
- **Rate limiting** - Prevents spam and abuse with configurable limits
- **Input sanitization** - HTML escaping and XSS protection
- **Permission checks** - ACE permission system integration
- **Content Security Policy** - Strict CSP headers in frontend
- **Pattern detection** - Blocks dangerous content patterns
- **Comprehensive logging** - Discord webhook integration for all events

### User Experience
- **Clean UI** - Modern, responsive message display
- **Accessibility** - Supports reduced motion and high contrast modes
- **Mobile responsive** - Works on all screen sizes
- **Error handling** - Graceful error recovery

## 📋 Requirements

- **FiveM Server** (latest recommended)
- **Lua 5.4** support
- **Discord Webhook** (for logging - optional but recommended)
- **Admin permissions** (`admin.menu` ACE permission)

## 🚀 Installation

1. Download or clone this repository
2. Place the `tech-SecureShield` folder in your server's `resources` directory
3. Add to your `server.cfg`:
   ```cfg
   ensure tech-SecureShield
   ```
4. Configure Discord webhooks in `config.lua` (see Configuration section)
5. Restart your server

## ⚙️ Configuration

Edit `config.lua` to configure Discord webhooks:

```lua
Config = {}

Config.discord = {
    serverLogs = "YOUR_SERVER_WEBHOOK_URL",
    clientLogs = "YOUR_CLIENT_WEBHOOK_URL",
    frontendLogs = "YOUR_FRONTEND_WEBHOOK_URL",
    
    serverName = "tech-SecureShield Server Logs",
    clientName = "tech-SecureShield Client Logs",
    frontendName = "tech-SecureShield Frontend Logs",
    
    serverAvatar = "YOUR_AVATAR_URL",
    clientAvatar = "YOUR_AVATAR_URL",
    frontendAvatar = "YOUR_AVATAR_URL",
    
    logCooldown = 5000  -- Cooldown between Discord logs (ms)
}
```

### Discord Webhook Setup

1. Go to your Discord server settings
2. Navigate to Integrations → Webhooks
3. Create three webhooks (one for each log type)
4. Copy the webhook URLs to `config.lua`

**⚠️ Security Note:** Keep your webhook URLs private. Consider using environment variables or a secure config file in production.

## 📖 Usage

### Sending Messages

Admins can send messages to players using the server event:

```lua
TriggerServerEvent('secure:showMessage', targetPlayerId, "Your message here")
```

### Example Script

```lua
-- Example: Send message to player ID 1
TriggerServerEvent('secure:showMessage', 1, "Welcome to the server!")
```

### Permissions

Players need the `admin.menu` ACE permission to send messages. Add to your `server.cfg`:

```cfg
add_ace group.admin admin.menu allow
```

## 📁 File Structure

```
tech-SecureShield/
├── fxmanifest.lua      # Resource manifest
├── config.lua          # Configuration file
├── server.lua          # Server-side logic
├── client.lua          # Client-side logic
└── html/
    ├── index.html      # Frontend HTML
    ├── app.js          # Frontend JavaScript
    └── style.css       # Frontend styles
```

## 🔒 Security Details

### Server-Side Security
- ACE permission validation (`admin.menu`)
- Rate limiting (5 attempts per 60 seconds)
- Input validation (type and length checks)
- Target player verification
- Comprehensive error handling

### Client-Side Security
- Message cooldown (3 seconds between messages)
- HTML sanitization
- Message length limits (1000 characters)
- Rate limiting per client
- NUI message validation

### Frontend Security
- Content Security Policy (CSP) headers
- HTML escaping (multiple layers)
- Dangerous pattern detection
- Origin verification
- Object freezing to prevent tampering

## 📊 Logging

All events are logged to Discord webhooks:

- **Server Logs**: Admin actions, permission violations, errors
- **Client Logs**: Client-side security events, rate limiting
- **Frontend Logs**: Frontend security events, content blocking

### Logged Events
- Message sent/received
- Rate limit violations
- Permission denials
- Invalid input attempts
- Security threats blocked
- Resource start/stop

## ⚠️ Known Issues & Limitations

1. **Rate Limiting Identifier**: Client-side rate limiting uses a static identifier (will be fixed in future update)
2. **Webhook Security**: Webhooks are stored in config file (consider environment variables for production)
3. **UI Closing**: No built-in way to close UI from frontend (can be added via NUI callback)

## 🔧 Customization

### Changing Message Display

Edit `html/style.css` to customize the message appearance:

```css
#message-container {
    background-color: rgba(0, 0, 0, 0.85);  /* Background color */
    color: #ffffff;                         /* Text color */
    border-radius: 10px;                    /* Border radius */
    /* ... more styles ... */
}
```

### Adjusting Rate Limits

Edit the constants in `server.lua` and `client.lua`:

```lua
-- server.lua
local MAX_ATTEMPTS = 5           -- Max attempts per window
local ATTEMPT_WINDOW = 60000     -- Window in milliseconds

-- client.lua
local messageCooldown = 3000     -- Cooldown in milliseconds
```

### Changing Message Length Limit

Edit `MAX_MESSAGE_LENGTH` in:
- `server.lua` (line 8)
- `client.lua` (line 37)
- `html/app.js` (line 8)

## 🐛 Troubleshooting

### Messages not displaying
- Check if player has NUI enabled
- Verify target player ID is valid
- Check server console for errors

### Discord logs not working
- Verify webhook URLs are correct
- Check webhook permissions in Discord
- Ensure `logCooldown` isn't too restrictive

### Permission denied errors
- Verify player has `admin.menu` ACE permission
- Check server console for permission errors

## 📝 License

This resource is provided as-is. Modify and use as needed for your server.

## 👤 Author

**tshentro.tech**

## 🤝 Contributing

Contributions are welcome! Please ensure:
- Code follows existing style
- Security features are maintained
- All changes are tested

## 📞 Support

For issues, questions, or suggestions, please open an issue on the GitHub repository.

---

**⚠️ Important Security Notice:** This resource includes security features but should be part of a comprehensive server security strategy. Always keep webhook URLs private and review logs regularly.

