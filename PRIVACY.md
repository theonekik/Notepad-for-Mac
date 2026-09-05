# Privacy — No Ads Studio Policy

**Notepad for Mac collects nothing. Shows no ads. Tracks nothing.**

1. **Offline-only.** The app makes zero network requests. No analytics SDK, no crash reporter, no update checker, no fonts fetched, no telemetry.
2. **Your text stays yours.** Files are read/written only where you choose via Open/Save panels. Nothing is uploaded, synced, or cached elsewhere.
3. **No identifiers.** No account, no sign-in, no device fingerprinting, no advertising ID.
4. **No third-party code.** Single Swift/AppKit source file. Nothing bundled that could phone home.
5. **Verifiable.** Search the source — there is no `URLSession`, `URLRequest`, `NSURLConnection`, `WKWebView`, or network entitlement:
   ```bash
   grep -rniE "URLSession|URLRequest|NSURLConnection|WKWebView|http" Sources/ || echo "clean: no network APIs"
   ```

This policy applies to every app under **No Ads Studio by TheOneKiK**: if it shows an ad or tracks you, it's not ours.
