import math

import numpy as np
import tensorflow as tf
from numpy.core.multiarray import ndarray


class Trial(object):
    def __init__(self, spikes: ndarray, cursor_data: ndarray):
        # spikes is (num_time_steps, num_channels) array
        # cursor_data is (num_time_steps, 2) array
        self.spikes = spikes
        self.num_time_steps = spikes.shape[0]
        self.num_channels = spikes.shape[1]
        self.cursor_data = cursor_data
        if cursor_data.shape[1] != 2:
            raise ValueError('Should be 2 but was shape %s' % cursor_data.shape)
        if cursor_data.shape[0] != spikes.shape[0]:
            raise ValueError(
                'Spikes and cursor data have different lengths, got %s %s' % (spikes.shape, cursor_data.shape))

    def enumerate(self):
        for time_idx in range(self.spikes.shape[0]):
            yield (time_idx,
                   self.spikes[time_idx, :, None].astype(dtype='double'))


def build_graph(trials):
    # tf.enable_eager_execution()

    trial = trials[0]
    # X * A + b
    A = tf.Variable(initial_value=lambda: np.random.normal(0,
        scale=1.0,
        size=(trial.num_channels, 2)), name='A')
    b = tf.Variable(initial_value=lambda: np.random.normal(0,
        scale=1.0,
        size=(1, 2)), name='b')
    l_s = tf.Variable(initial_value=lambda: 1.0, dtype='double', name='l_s')
    l_e = tf.Variable(initial_value=lambda: 1.0, dtype='double', name='l_e')

    computed_cursor_velocities_across_trials = []
    for trial_idx, trial in enumerate(trials):
        theta_initial = tf.get_variable(shape=(1, 2), name='theta_initial_%d' % trial_idx, trainable=True,
            dtype='double',
            initializer=tf.zeros_initializer)
        computed_cursor_velocities = [[None, None]] * trial.num_time_steps

        theta = theta_initial
        for (time_idx, spikes) in trial.enumerate():
            omega = tf.matmul(spikes.T, A) + b
            vx = tf.multiply(-l_s, tf.math.sin(theta[0, 0])) * omega[0, 0] - l_e * tf.math.sin(theta[0, 1]) * omega[0, 1]
            vy = tf.multiply(l_s, tf.math.cos(theta[0, 0])) * omega[0, 0] + l_e * tf.math.cos(theta[0, 1]) * omega[0, 1]
            computed_cursor_velocities[time_idx][0] = vx
            computed_cursor_velocities[time_idx][1] = vy
            theta = omega + theta

        velocities_t = tf.get_variable('computed_cursor_velocities_' + str(trial_idx),
            shape=(trial.num_time_steps, 2))
        velocities_t.assign(computed_cursor_velocities)
        computed_cursor_velocities_across_trials.append(velocities_t)

    def calculate_error():
        errors = tf.get_variable(size=(len(trials),), dtype='double', name='computed_error',
            initializer=tf.zeros_initializer)
        for trial_idx, trial in enumerate(trials):
            computed_cursor_velocities = tf.get_variable('computed_cursor_velocities_' + str(trial_idx))
            errors[trial_idx] = tf.squared_difference(computed_cursor_velocities, trial.cursor_data)
        return tf.reduce_sum(errors)
    train_op = tf.train.GradientDescentOptimizer(0.01).minimize(calculate_error)

    # Normal TensorFlow - initialize values, create a session and run the model
    model = tf.global_variables_initializer()

    with tf.Session() as session:
        [session.run(c) for c in computed_cursor_velocities_across_trials]
        session.run(model)
        session.run(train_op)


def generate_trials() -> [Trial]:
    l_s = 1.0
    l_e = 1.5
    num_channels = 15
    A = np.random.normal(0, 1.0, size=(num_channels, 2))
    b = np.random.normal(0, 1.0, size=(2,))
    num_trials = 100
    num_time_steps = 100

    initial_thetas = np.random.uniform(0, math.pi, size=(num_trials, 2))
    trials = []

    for trial_idx in range(num_trials):
        spike_data = np.random.poisson(2.0, size=(num_time_steps, num_channels))

        initial_theta = initial_thetas[trial_idx, :]

        thetas = np.zeros(shape=(num_time_steps, 2))
        thetas[0, :] = initial_theta

        # cursor velocity always zero at first
        cursor_velocities = np.zeros(shape=(num_time_steps, 2))

        for time_idx in range(num_time_steps - 1):
            omega = spike_data[time_idx] @ A + b
            thetas[time_idx + 1, :] = thetas[time_idx, :] + omega
            cursor_velocities[time_idx + 1, :] = [
                -l_s * math.sin(thetas[time_idx, 0]) * omega[0] - l_e * math.sin(thetas[time_idx, 1]) * omega[1],
                l_s * math.cos(thetas[time_idx, 0]) * omega[0] + l_s * math.cos(thetas[time_idx, 1]) * omega[1]
            ]
        trials.append(Trial(spike_data, cursor_velocities))
    return trials


if __name__ == '__main__':
    build_graph(generate_trials())
