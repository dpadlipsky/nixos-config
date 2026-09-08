"""Integration check: python3 check.py /absolute/path/to/headless-run."""

import concurrent.futures
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

launcher = str(Path(sys.argv[1]).resolve())


def desktop_sockets():
    paths = list(Path('/tmp/.X11-unix').glob('*'))
    paths += list(Path('/tmp').glob('.X[0-9]*-lock'))
    return {str(p): (p.lstat().st_dev, p.lstat().st_ino, p.lstat().st_mode)
            for p in paths}


child = r'''
import json, os, socket, subprocess, sys, time
assert not os.path.exists(sys.argv[1]), 'Host /tmp leaked into graphics job'
assert os.environ['DISPLAY'] == ':99'
assert 'WAYLAND_DISPLAY' not in os.environ
assert 'WAYLAND_SOCKET' not in os.environ
assert not os.path.lexists('/tmp/.X11-unix/X0'), 'Desktop X0 leaked into job'
namespace = os.readlink('/proc/self/ns/net')
assert namespace != sys.argv[2], 'Host network namespace leaked into job'
# Exercise the very path that the old renderer overwrote, only in private /tmp.
s = socket.socket(socket.AF_UNIX)
s.bind('/tmp/.X11-unix/X0')
s.listen()
with open('/tmp/.X0-lock', 'w') as f:
    f.write(str(os.getpid()))
subprocess.run(['xprop', '-root', '_NET_SUPPORTING_WM_CHECK'],
               check=True, capture_output=True, timeout=5)
time.sleep(1)
print(json.dumps({'display': os.environ['DISPLAY'], 'network': namespace}))
'''

before = desktop_sockets()
host_net = os.readlink('/proc/self/ns/net')
with tempfile.NamedTemporaryFile(prefix='headless-run-host-', dir='/tmp') as marker:
    command = [launcher, sys.executable, '-c', child, marker.name, host_net]
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(lambda _: subprocess.run(
            command, check=True, capture_output=True, text=True, timeout=30), range(2)))
    namespaces = [json.loads(r.stdout)['network'] for r in results]
    assert len(set(namespaces)) == 2, 'Concurrent graphics jobs shared a network namespace'

assert desktop_sockets() == before, 'Host display sockets or lock files changed'
failure = subprocess.run([launcher, sys.executable, '-c', 'raise SystemExit(23)'], timeout=30)
assert failure.returncode == 23, 'Client exit status was not preserved'
if os.environ.get('DISPLAY'):
    subprocess.run(['xprop', '-root', '_NET_SUPPORTING_WM_CHECK'],
                   check=True, capture_output=True, timeout=5)
print('PASS: concurrent private displays, isolated /tmp and network, host sockets unchanged, exit status preserved')
