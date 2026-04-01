// PrivacyShield: Unified Network Interceptor
// Reads settings from window.__privacyShieldSettings (injected by Swift).
// Conditionally blocks based on user preferences.

(function() {
    'use strict';

    var S = window.__privacyShieldSettings || {
        blockReadReceipts: true,
        blockTypingIndicator: true,
        blockSearchTracking: true,
        stealthMode: true,
        cleanLinks: true
    };

    function notify(category, url) {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.privacyShield) {
            window.webkit.messageHandlers.privacyShield.postMessage({
                type: 'blocked',
                category: category,
                url: url
            });
        }
    }

    // Use WeakMap to avoid detectable custom properties on XHR objects
    var xhrMeta = new WeakMap();

    // ========================================
    // UNIFIED XMLHttpRequest INTERCEPTOR
    // ========================================

    var originalXHROpen = XMLHttpRequest.prototype.open;
    var originalXHRSend = XMLHttpRequest.prototype.send;

    XMLHttpRequest.prototype.open = function(method, url) {
        xhrMeta.set(this, { url: url, method: method });
        return originalXHROpen.apply(this, arguments);
    };

    XMLHttpRequest.prototype.send = function(body) {
        var meta = xhrMeta.get(this) || {};
        var url = meta.url || '';
        var method = meta.method || 'GET';

        // --- MESSAGE PRIVACY (conditional) ---
        if (S.blockReadReceipts) {
            if (url.indexOf('/voyager/api/messaging/conversations') !== -1 && url.indexOf('seen') !== -1) {
                notify('read_receipt', url); return;
            }
        }
        if (S.blockTypingIndicator) {
            if (url.indexOf('/voyager/api/messaging/conversations') !== -1 && url.indexOf('typing') !== -1) {
                notify('typing_indicator', url); return;
            }
        }
        if (S.blockReadReceipts || S.blockTypingIndicator) {
            if (url.indexOf('/voyager/api/messaging') !== -1 && (url.indexOf('track') !== -1 || url.indexOf('analytics') !== -1)) {
                notify('message_tracking', url); return;
            }
        }

        // --- SEARCH PRIVACY (conditional) ---
        if (S.blockSearchTracking) {
            if (url.indexOf('/voyager/api/search') !== -1 && (url.indexOf('track') !== -1 || url.indexOf('analytics') !== -1 || url.indexOf('impression') !== -1)) {
                notify('search_analytics', url); return;
            }
            if (url.indexOf('/voyager/api/search/history') !== -1 && (method === 'POST' || method === 'PUT')) {
                notify('search_history', url); return;
            }
            if (url.indexOf('typeahead') !== -1 && url.indexOf('track') !== -1) {
                notify('typeahead_tracking', url); return;
            }
        }

        // --- STEALTH BROWSING (conditional) ---
        if (S.stealthMode) {
            if (url.indexOf('/voyager/api/identity/profileView') !== -1 ||
                (url.indexOf('profileActions') !== -1 && url.indexOf('view') !== -1) ||
                (url.indexOf('/voyager/api/feed/profiles') !== -1 && url.indexOf('track') !== -1)) {
                notify('profile_view', url); return;
            }
            if (url.indexOf('impression') !== -1 || url.indexOf('viewedEntity') !== -1) {
                notify('impression', url); return;
            }
        }

        // --- ALWAYS BLOCK (trackers/beacons regardless of settings) ---
        if (url.indexOf('/li/track') !== -1 || url.indexOf('/px/') !== -1 || url.indexOf('beacon') !== -1) {
            notify('beacon', url); return;
        }
        if ((method === 'POST' || method === 'PUT') &&
            (url.indexOf('/li/fta') !== -1 || url.indexOf('/csp/fta') !== -1 || url.indexOf('telemetry') !== -1)) {
            notify('analytics', url); return;
        }

        return originalXHRSend.apply(this, arguments);
    };

    // ========================================
    // UNIFIED FETCH INTERCEPTOR
    // ========================================

    var originalFetch = window.fetch;
    window.fetch = function(input, init) {
        var url = typeof input === 'string' ? input : ((input && input.url) || '');
        var method = (init && init.method) || 'GET';
        var fakeOk = function() { return Promise.resolve(new Response('{}', { status: 200 })); };

        // --- MESSAGE PRIVACY ---
        if (url.indexOf('/messaging/conversations') !== -1) {
            if (S.blockReadReceipts && url.indexOf('seen') !== -1) { notify('read_receipt', url); return fakeOk(); }
            if (S.blockTypingIndicator && url.indexOf('typing') !== -1) { notify('typing_indicator', url); return fakeOk(); }
        }

        // --- SEARCH PRIVACY ---
        if (S.blockSearchTracking && url.indexOf('/search') !== -1 &&
            (url.indexOf('analytics') !== -1 || url.indexOf('impression') !== -1 || url.indexOf('track') !== -1)) {
            notify('search_analytics', url); return fakeOk();
        }

        // --- STEALTH BROWSING ---
        if (S.stealthMode && (url.indexOf('profileView') !== -1 || (url.indexOf('impression') !== -1 && method === 'POST'))) {
            notify('stealth_fetch', url); return fakeOk();
        }

        // --- ALWAYS BLOCK ---
        if (url.indexOf('/li/track') !== -1 || url.indexOf('/px/') !== -1 || url.indexOf('beacon') !== -1) {
            notify('beacon', url); return fakeOk();
        }

        return originalFetch.apply(this, arguments);
    };

    console.log('[PrivacyShield] Unified Network Interceptor loaded');
})();
