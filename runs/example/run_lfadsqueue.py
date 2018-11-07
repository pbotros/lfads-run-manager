import lfadsqueue as lq

queue_name = "example"
tensorboard_script = "/Users/pbotros/Development/lfads-run-manager/runs/example/launch_tensorboard.sh"
gpu_list = []

task_specs = [{"name": "lfads_param_-GyWUm_run001_single_PacoBMI_days", "command": "bash /Users/pbotros/Development/lfads-run-manager/runs/example/param_-GyWUm/single_PacoBMI_days/lfads_train.sh", "memory_req": 2000, "outfile": "/Users/pbotros/Development/lfads-run-manager/runs/example/param_-GyWUm/single_PacoBMI_days/lfads.out", "donefile": "/Users/pbotros/Development/lfads-run-manager/runs/example/param_-GyWUm/single_PacoBMI_days/lfads.done"}, 
{"name": "lfads_param_ORCoel_run002_single_PacoBMI_days", "command": "bash /Users/pbotros/Development/lfads-run-manager/runs/example/param_ORCoel/single_PacoBMI_days/lfads_train.sh", "memory_req": 2000, "outfile": "/Users/pbotros/Development/lfads-run-manager/runs/example/param_ORCoel/single_PacoBMI_days/lfads.out", "donefile": "/Users/pbotros/Development/lfads-run-manager/runs/example/param_ORCoel/single_PacoBMI_days/lfads.done"}, 
{"name": "lfads_param_4XqerO_run003_single_PacoBMI_days", "command": "bash /Users/pbotros/Development/lfads-run-manager/runs/example/param_4XqerO/single_PacoBMI_days/lfads_train.sh", "memory_req": 2000, "outfile": "/Users/pbotros/Development/lfads-run-manager/runs/example/param_4XqerO/single_PacoBMI_days/lfads.out", "donefile": "/Users/pbotros/Development/lfads-run-manager/runs/example/param_4XqerO/single_PacoBMI_days/lfads.done"}, 
{"name": "lfads_param_1kdyLq_run004_single_PacoBMI_days", "command": "bash /Users/pbotros/Development/lfads-run-manager/runs/example/param_1kdyLq/single_PacoBMI_days/lfads_train.sh", "memory_req": 2000, "outfile": "/Users/pbotros/Development/lfads-run-manager/runs/example/param_1kdyLq/single_PacoBMI_days/lfads.out", "donefile": "/Users/pbotros/Development/lfads-run-manager/runs/example/param_1kdyLq/single_PacoBMI_days/lfads.done"}, 
]

tasks = lq.run_lfads_queue(queue_name, tensorboard_script, task_specs, gpu_list=gpu_list, one_task_per_gpu=True)

