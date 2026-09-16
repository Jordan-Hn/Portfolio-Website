# Prints a URL to PDF via the Chrome DevTools Protocol.
# Workaround for brave.exe --print-to-pdf hanging; drives an already-launched
# headless instance instead. Usage: python cdp-print.py <debug-port> <url> <out.pdf>
import base64
import json
import sys
import time
import urllib.request

import websocket

port, url, out = sys.argv[1], sys.argv[2], sys.argv[3]

version = json.loads(urllib.request.urlopen(f"http://127.0.0.1:{port}/json/version", timeout=10).read())
print("browser:", version.get("Browser"))

req = urllib.request.Request(f"http://127.0.0.1:{port}/json/new?about:blank", method="PUT")
target = json.loads(urllib.request.urlopen(req, timeout=10).read())
ws = websocket.create_connection(target["webSocketDebuggerUrl"], timeout=30)

msg_id = 0
def send(method, params=None):
    global msg_id
    msg_id += 1
    ws.send(json.dumps({"id": msg_id, "method": method, "params": params or {}}))
    return msg_id

def wait_for(want_id=None, event=None, timeout=30):
    deadline = time.time() + timeout
    while time.time() < deadline:
        m = json.loads(ws.recv())
        if want_id is not None and m.get("id") == want_id:
            return m
        if event is not None and m.get("method") == event:
            return m
    raise TimeoutError(f"waiting for id={want_id} event={event}")

wait_for(want_id=send("Page.enable"))
wait_for(want_id=send("Page.navigate", {"url": url}))
wait_for(event="Page.loadEventFired", timeout=30)
# Wait for self-hosted fonts and the deferred contact-email script before printing.
ready = wait_for(want_id=send("Runtime.evaluate", {
    "expression": "document.fonts.ready.then(() => document.readyState)",
    "awaitPromise": True,
    "returnByValue": True,
}))
if "error" in ready or "exceptionDetails" in ready.get("result", {}):
    raise RuntimeError(f"Page preparation failed: {ready}")

pid = send("Page.printToPDF", {
    "printBackground": True,
    "displayHeaderFooter": False,
    "preferCSSPageSize": True,
    "paperWidth": 210 / 25.4, "paperHeight": 297 / 25.4,
    "marginTop": 0, "marginBottom": 0, "marginLeft": 0, "marginRight": 0,
})
resp = wait_for(want_id=pid, timeout=60)
if "error" in resp:
    print("printToPDF error:", resp["error"])
    sys.exit(1)
with open(out, "wb") as f:
    f.write(base64.b64decode(resp["result"]["data"]))
print("wrote", out)
ws.close()
