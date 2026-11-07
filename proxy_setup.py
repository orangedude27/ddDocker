"""Configure nginx for the running decomp instance, using its current window secret."""
import json
import os
from pathlib import Path
import re
import sys

state = Path(os.environ.get("DECOMP_HOME", "/data")) / ".decomp/server.json"
try:
    data = json.loads(state.read_text())
    port = int(data["port"])
    secret = data["secret"]
    if data["pid"] != int(sys.argv[1]) or not 1 <= port <= 65535:
        raise ValueError("stale server state")
    if not isinstance(secret, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", secret):
        raise ValueError("invalid server secret")
except (OSError, ValueError, KeyError, json.JSONDecodeError):
    sys.exit(1)

Path("/etc/nginx/sites-enabled/default").write_text(f"""server {{
    listen 8080 default_server;
    client_max_body_size 100M;

    location / {{
        proxy_pass http://127.0.0.1:{port};
        proxy_set_header Host 127.0.0.1:{port};
        proxy_set_header User-Agent decompdecomp-window/{secret};
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }}
}}
""")
