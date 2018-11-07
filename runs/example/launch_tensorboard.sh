#!/bin/bash
source activate tensorflow
tensorboard --logdir=param_-GyWUm/single_PacoBMI_days:"/Users/pbotros/Development/lfads-run-manager/runs/example/param_-GyWUm/single_PacoBMI_days/lfadsOutput",param_ORCoel/single_PacoBMI_days:"/Users/pbotros/Development/lfads-run-manager/runs/example/param_ORCoel/single_PacoBMI_days/lfadsOutput",param_4XqerO/single_PacoBMI_days:"/Users/pbotros/Development/lfads-run-manager/runs/example/param_4XqerO/single_PacoBMI_days/lfadsOutput",param_1kdyLq/single_PacoBMI_days:"/Users/pbotros/Development/lfads-run-manager/runs/example/param_1kdyLq/single_PacoBMI_days/lfadsOutput"  "$@"

