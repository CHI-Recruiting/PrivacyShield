// PrivacyShield: Stealth Browsing
// Blocks profile view events, tracking beacons, and canvas fingerprinting
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

    // Block navigator.sendBeacon (used for tracking on page leave)
    const originalSendBeacon = navigator.sendBeacon;
    navigator.sendBeacon = function(url, data) {
        console.log('[PrivacyShield] Blocked sendBeacon:', url);
        notify('send_beacon', url);
        return true;
    };

    // Block canvas fingerprinting — detect hidden/small fingerprint canvases
    var originalToDataURL = HTMLCanvasElement.prototype.toDataURL;
    HTMLCanvasElement.prototype.toDataURL = function() {
        // Detect fingerprinting: small canvas OR not visible on screen
        var isSmall = this.width <= 300 && this.height <= 300;
        var isHidden = false;
        try {
            var style = window.getComputedStyle(this);
            isHidden = style.display === 'none' || style.visibility === 'hidden' ||
                       style.opacity === '0' || this.offsetParent === null;
        } catch(e) {
            isHidden = true; // If we can't check, assume hidden (fingerprinting)
        }

        if (isSmall || isHidden) {
            try {
                var canvas = document.createElement('canvas');
                canvas.width = this.width;
                canvas.height = this.height;
                var ctx = canvas.getContext('2d');
                if (ctx) {
                    ctx.drawImage(this, 0, 0);
                    var imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
                    for (var i = 0; i < imageData.data.length; i += 100) {
                        imageData.data[i] = imageData.data[i] ^ 1;
                    }
                    ctx.putImageData(imageData, 0, 0);
                    return originalToDataURL.apply(canvas, arguments);
                }
            } catch(e) {}
        }
        return originalToDataURL.apply(this, arguments);
    };

    // Block Battery API (used for fingerprinting)
    if (navigator.getBattery) {
        navigator.getBattery = undefined;
    }

    console.log('[PrivacyShield] Stealth Browsing module loaded');
})();
