// PrivacyShield: Message Privacy
// Blocks read receipts and typing indicators in LinkedIn messages
// NOTE: XHR/fetch overrides are centralized in privacy_shield.js to avoid prototype collision

(function() {
    'use strict';

    function notify(category, url) {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.privacyShield) {
            window.webkit.messageHandlers.privacyShield.postMessage({
                type: 'blocked',
                category: category,
                url: url
            });
        }
    }

    // Block WebSocket messages related to typing/read status
    const originalWSSend = WebSocket.prototype.send;
    WebSocket.prototype.send = function(data) {
        try {
            const payload = typeof data === 'string' ? data : '';
            // Only block if the payload is clearly a typing/read receipt event
            if (payload.length < 500 &&
                (payload.includes('"type":"TYPING"') ||
                 payload.includes('"type":"READ_RECEIPT"') ||
                 payload.includes('"type":"SEEN"'))) {
                console.log('[PrivacyShield] Blocked WebSocket typing/read event');
                notify('websocket_tracking', 'websocket');
                return;
            }
        } catch(e) {}
        return originalWSSend.call(this, data);
    };

    console.log('[PrivacyShield] Message Privacy module loaded');
})();
