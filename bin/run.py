#!/usr/bin/env python
import os
import socket
import subprocess
import sys

hostname = socket.gethostname()

# Remove anything with "Ching" and "models/research/lfads"
sys.path = [p for p in sys.path if not ('Ching' in p and 'lfads' in p)]

python_paths = []
if hostname == "pbotros.local":
    python_paths.append(os.path.expanduser("~/Development/models/research/lfads"))
    python_paths.append(os.path.expanduser("~/Development/lfads-run-manager/src"))
elif hostname == "DESKTOP-EQ0F9DU":
    python_paths.append("Z:\\ELZ\\VS265\\lfads-run-manager\\src")
    python_paths.append("Z:\\ELZ\\VS265\\models\\research\\src")
else:
    print("Unknown hostname %s. Not doing import paths automatically." % hostname)

sys.path += python_paths

if len(sys.argv) != 2:
    print("Usage: %s </path/to/run_lfadsqueue.py>" % (sys.argv[0]))
    sys.exit(1)

file_name = sys.argv[1]
sys.path.append(os.path.dirname(file_name))

import pdb; pdb.set_trace()
from run_lfadsqueue import task_specs

subprocess_env = os.environ.copy()
subprocess_env['PYTHONPATH'] = ':'.join(sys.path)
subprocess_env['PATH'] = ':'.join(subprocess_env['PATH'].split(':') + sys.path)
print(subprocess_env['PATH'])

for task_spec in task_specs:
    print("Running task %s. spec=%s" % (task_spec['name'], task_spec))
    s = subprocess.check_call(task_spec['command'].split(" "), env=subprocess_env)
    print("Task %s finished with code %s" % (task_spec['name'], s))
