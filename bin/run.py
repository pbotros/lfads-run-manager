#!/usr/bin/env python
import os
import socket
import subprocess
import sys

hostname = socket.gethostname()
python_paths = []
if hostname == "pbotros.local":
    python_paths.append(os.path.expanduser("~/Development/models/research/lfads"))
    python_paths.append(os.path.expanduser("~/Development/lfads-run-manager/src"))
elif hostname == "DESKTOP-EQ0F9DU":
    python_paths.append("/z/ELZ/VS265/lfads-run-manager/src")
    python_paths.append("~/Documents/Ching/models/research/lfads")
else:
    print("Unknown hostname %s. Not doing import paths automatically." % hostname)

sys.path += python_paths

if len(sys.argv) != 2:
    print("Usage: %s </path/to/run_lfadsqueue.py>" % (sys.argv[0]))
    sys.exit(1)

file_name = sys.argv[1]
sys.path.append(os.path.dirname(file_name))

from run_lfadsqueue import task_specs

subprocess_env = os.environ.copy()
subprocess_env['PYTHONPATH'] = ':'.join(sys.path)
subprocess_env['PATH'] = ':'.join(subprocess_env['PATH'].split(':') + sys.path)
print(subprocess_env['PATH'])

for task_spec in task_specs:
    print("Running task %s. spec=%s" % (task_spec['name'], task_spec))
    outfile = open(task_spec['outfile'], 'w')
    donefile = open(task_spec['outfile'], 'w')
    s = subprocess.Popen(task_spec['command'].split(" "), stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        env=subprocess_env)
    for line in s.stdout: # b'\n'-separated lines
        sys.stdout.buffer.write(line) # pass bytes as is
        outfile.write(line.decode('utf-8'))
