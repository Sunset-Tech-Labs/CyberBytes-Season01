#!/usr/bin/env python3
import socketserver
import subprocess


class Handler(socketserver.StreamRequestHandler):
    def handle(self):
        self.wfile.write(b"DAWNSTAR TELEMETRY 1.3\n")
        line = self.rfile.readline(4096).decode("utf-8", "replace").strip()
        if line == "HELP":
            self.wfile.write(b"HELP STATUS PROBE <host>\n")
        elif line == "STATUS":
            self.wfile.write(b"telemetry nominal\n")
        elif line.startswith("PROBE "):
            target = line[6:]
            result = subprocess.run(
                f"ping -c 1 -W 1 {target}",
                shell=True,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=8,
            )
            self.wfile.write(result.stdout.encode())
        else:
            self.wfile.write(b"ERR unknown command\n")


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True


with Server(("172.30.10.10", 4040), Handler) as server:
    server.serve_forever()
