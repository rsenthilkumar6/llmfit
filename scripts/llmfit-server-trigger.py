#!/usr/bin/env python3
# llmfit-server-trigger.py
# HTTP service that receives startup triggers and starts the llmfit-server
# on first request. Runs on port 8098 to avoid conflicts with main server.

from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess
import time

TRIGGER_PORT = 8097
SERVER_PORT = 8787


def wait_for_server(timeout=30):
    for _ in range(timeout):
        try:
            result = subprocess.run(
                ["curl", "-sf", f"http://127.0.0.1:{SERVER_PORT}/health"],
                capture_output=True, timeout=5
            )
            if result.returncode == 0:
                return True
        except subprocess.TimeoutExpired:
            pass
        time.sleep(1)
    return False


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/start":
            result = subprocess.run(
                ["curl", "-sf", f"http://127.0.0.1:{SERVER_PORT}/health"],
                capture_output=True, timeout=5
            )
            if result.returncode == 0:
                self.send_response(200)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"already running")
            else:
                subprocess.run(["launchctl", "start", "ai.llmfit.server"], check=False)
                if wait_for_server():
                    self.send_response(200)
                    self.send_header("Content-Type", "text/plain")
                    self.end_headers()
                    self.wfile.write(b"started")
                else:
                    self.send_response(503)
                    self.send_header("Content-Type", "text/plain")
                    self.end_headers()
                    self.wfile.write(b"failed to start")
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", TRIGGER_PORT), Handler)
    print(f"Trigger service listening on port {TRIGGER_PORT}")
    server.serve_forever()