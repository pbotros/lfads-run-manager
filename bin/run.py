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
    running_on_windows = False
    python_paths.append(os.path.expanduser("~/Development/models/research/lfads"))
    python_paths.append(os.path.expanduser("~/Development/lfads-run-manager/src"))
elif hostname == "DESKTOP-EQ0F9DU":
    running_on_windows = True
    python_paths.append("Z:\\ELZ\\VS265\\lfads-run-manager\\src")
    python_paths.append("Z:\\ELZ\\VS265\\models\\research\\src")
else:
    print("Unknown hostname %s. Not doing import paths automatically." % hostname)
    running_on_windows = False

sys.path += python_paths

if running_on_windows:
    lfadsqueue_filename = '/z/ELZ/VS265/generated/latest/run_lfadsqueue.py'
else:
    lfadsqueue_filename = '/Volumes/DATA_01/ELZ/VS265/generated/latest/run_lfadsqueue.py'

sys.path.append(os.path.dirname(lfadsqueue_filename))

from run_lfadsqueue import task_specs

subprocess_env = os.environ.copy()
subprocess_env['PYTHONPATH'] = ':'.join(sys.path)
subprocess_env['PATH'] = ':'.join(subprocess_env['PATH'].split(':') + sys.path)
print(subprocess_env['PATH'])

for task_spec in task_specs:
    print("Running task %s. spec=%s" % (task_spec['name'], task_spec))
    command_split = task_spec['command'].split(" ")
    lfads_train_filename = command_split[1]
    import pdb; pdb.set_trace()
    if running_on_windows:
        f = open(lfads_train_filename, 'r')
        replaced = f.read().replace('/Volumes/DATA_01/ELZ/VS265/generated/latest', '/z/ELZ/VS265/generated/latest')
        f.close()
        f = open(lfads_train_filename, 'w')
        f.write(replaced)
        f.close()
    else:
        f = open(lfads_train_filename, 'r')
        replaced = f.read().replace('/z/ELZ/VS265/generated/latest', '/Volumes/DATA_01/ELZ/VS265/generated/latest')
        f.close()
        f = open(lfads_train_filename, 'w')
        f.write(replaced)
        f.close()

    # Edit file on disk to normalize
    s = subprocess.check_call(command_split, env=subprocess_env)
    print("Task %s finished with code %s" % (task_spec['name'], s))
