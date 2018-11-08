#!/usr/bin/env python
import ntpath
import os
import re
import socket
import subprocess
import sys

hostname = socket.gethostname()

# Remove anything with "Ching" and "lfads"
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
    # python_paths.append("/z/ELZ/VS265/lfads-run-manager/src")
    # python_paths.append("/z/ELZ/VS265/models/research/lfads")
else:
    print("Unknown hostname %s. Not doing import paths automatically." % hostname)
    running_on_windows = False

sys.path += python_paths

if running_on_windows:
    lfadsqueue_directory = 'Z:\\ELZ\\VS265\\generated\\latest'
else:
    lfadsqueue_directory = '/Volumes/DATA_01/ELZ/VS265/generated/latest'

sys.path.append(lfadsqueue_directory)

from run_lfadsqueue import task_specs

subprocess_env = os.environ.copy()
subprocess_env['PYTHONPATH'] = ':'.join(sys.path)
subprocess_env['PATH'] = ':'.join(subprocess_env['PATH'].split(':') + sys.path)


def correct_paths(content):
    if running_on_windows:
        content = correct_paths_research(content)
        content = correct_paths_generated(content)
    return content


def correct_paths_research(content):
    while True:
        matches = re.findall(r'/Volumes/DATA_01/ELZ/VS265/models/research/lfads/[A-Za-z0-9/_.-]*', content)
        if len(matches) == 0:
            break
        original = matches[0]
        replaced = ntpath.join('Z:\\', ntpath.normpath(original.replace('/Volumes/DATA_01/', ''))).replace('\\', '\\\\\\')
        print("Replacing %s to %s" % (original, replaced))
        content = content.replace(original, replaced)
    return content


def correct_paths_generated(content):
    while True:
        matches = re.findall(r'/Volumes/DATA_01/ELZ/VS265/generated/latest/[A-Za-z0-9/_.-]*', content)
        if len(matches) == 0:
            break
        original = matches[0]
        replaced = ntpath.join('Z:\\', ntpath.normpath(original.replace('/Volumes/DATA_01/', ''))).replace('\\', '\\\\\\')
        print("Replacing %s to %s" % (original, replaced))
        content = content.replace(original, replaced)
    return content


for task_spec in task_specs:
    print("Running task %s. spec=%s" % (task_spec['name'], task_spec))
    command_split = task_spec['command'].split(" ")
    lfads_train_filename = correct_paths(command_split[1])

    f = open(lfads_train_filename, 'r')
    read = f.read()
    replaced = correct_paths(read)
    f.close()
    f = open(lfads_train_filename, 'w')
    f.write(replaced)
    f.close()

    s = subprocess.check_call('bash ' + lfads_train_filename, shell=True, env=subprocess_env)
    print("Task %s finished with code %s" % (task_spec['name'], s))
