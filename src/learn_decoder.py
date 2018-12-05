import math
import sys

import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf
from numpy.core.multiarray import ndarray

NUM_CHANNELS = 15
NUM_OUTPUTS = 2
BATCH_SIZE = 10
DT = 0.1

plt.ion()
f, axarr = plt.subplots(2)
plt.show()

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
                   self.spikes[time_idx, :, None].astype(dtype='double'),
                   self.cursor_data[time_idx, :, None].astype(dtype='double')[:, 0])


def pseudo_sin(x):
    return 2.0 * tf.math.sigmoid(x) - 1


def pseudo_cos(x):
    return pseudo_sin(x + math.pi / 2.0)


class Decoder(object):
    def __init__(self, num_time_steps, real_a):
        # tf.enable_eager_execution()

        # X * A + b
        self.A = tf.Variable(initial_value=lambda: real_a, name='A', trainable=False)
        # self.A = tf.Variable(initial_value=lambda: np.random.normal(0,
        #     scale=1.0,
        #     size=(NUM_CHANNELS, NUM_OUTPUTS)), name='A')
        self.b = tf.Variable(initial_value=lambda: np.random.normal(0,
            scale=1.0,
            size=(1, NUM_OUTPUTS)), name='b')
        # TODO: penalize instead of hard constraint
        # self.l_s = tf.Variable(initial_value=lambda: 1.0, dtype='double', name='l_s',
        #     constraint=lambda x: tf.clip_by_value(x, 0, 10))
        # self.l_e = tf.Variable(initial_value=lambda: 1.0, dtype='double', name='l_e',
        #     constraint=lambda x: tf.clip_by_value(x, 0, 10))
        self.l_s = tf.constant(1.0, dtype='double')
        self.l_e = tf.constant(1.5, dtype='double')
        # self.l_e = tf.Variable(initial_value=lambda: 1.0, dtype='double', name='l_e',
        #     constraint=lambda x: tf.clip_by_value(x, 0, 10))
        # Assume that we start at the same point for each trial (i.e. in the center), and there's a single angle
        # used for this center position
        self.theta_initial = tf.Variable(initial_value=lambda: np.zeros((1, NUM_OUTPUTS)),
            dtype='double', name='theta_initial',
            constraint=lambda x: tf.clip_by_value(x, -math.pi, math.pi))

        # create a computed_cursor_velocities of size:
        # (num_trials, num_outputs, max(num_timesteps)
        # self.max_num_timesteps = max_num_timesteps
        # self.computed_cursor_velocities = tf.get_variable(
        #     name='computed_cursor_velocities',
        #     shape=(len(trials), NUM_OUTPUTS, max_num_timesteps),
        #     dtype='double')
        # self.real_cursor_velocities = tf.get_variable(
        #     name='real_cursor_velocities',
        #     shape=(len(trials), NUM_OUTPUTS, max_num_timesteps),
        #     dtype='double')
        # self.computed_cursor_velocities = np.empty(
        #     shape=(len(trials), NUM_OUTPUTS, max_num_timesteps),
        #     dtype='double')
        # self.real_cursor_velocities = np.empty(
        #     shape=(len(trials), NUM_OUTPUTS, max_num_timesteps),
        #     dtype='double')
        self.computed_cursor_velocities = []
        self.real_cursor_velocities = []

        self.spikes = tf.placeholder(dtype='double', shape=(BATCH_SIZE, NUM_CHANNELS, num_time_steps), name='spikes')
        self.real_data = tf.placeholder(dtype='double', shape=(BATCH_SIZE, NUM_OUTPUTS, num_time_steps), name='real_data')

        for batch_idx in range(BATCH_SIZE):
            theta = self.theta_initial
            for time_idx in range(num_time_steps):
                omega = DT * (tf.matmul(spikes[batch_idx, :, time_idx, None].T, self.A) + self.b)

                vx = tf.multiply(-self.l_s, tf.math.sin(theta[0, 0])) * omega[0, 0] - \
                     self.l_e * tf.math.sin(theta[0, 1]) * omega[0, 1]
                vy = tf.multiply(self.l_s, tf.math.cos(theta[0, 0])) * omega[0, 0] + \
                     self.l_e * tf.math.cos(theta[0, 1]) * omega[0, 1]
                # vx = tf.multiply(-self.l_s, pseudo_sin(theta[0, 0])) * omega[0, 0] - self.l_e * pseudo_sin(theta[0, 1]) * omega[0, 1]
                # vy = tf.multiply(self.l_s, pseudo_cos(theta[0, 0])) * omega[0, 0] + self.l_e * pseudo_cos(theta[0, 1]) * omega[0, 1]
                theta = omega + theta

                # self.computed_cursor_velocities[trial_idx, 0, time_idx] = vx
                # self.computed_cursor_velocities[trial_idx, 1, time_idx] = vy
                # self.real_cursor_velocities[trial_idx, 0, time_idx] = real_data[0]
                # self.real_cursor_velocities[trial_idx, 1, time_idx] = real_data[1]

                # self.computed_cursor_velocities[trial_idx][0][time_idx] = vx
                # self.computed_cursor_velocities[trial_idx][1][time_idx] = vy
                # self.real_cursor_velocities[trial_idx][0][time_idx] = real_data[0]
                # self.real_cursor_velocities[trial_idx][1][time_idx] = real_data[1]

                self.computed_cursor_velocities.append(vx)
                self.computed_cursor_velocities.append(vy)
                self.real_cursor_velocities.append(self.real_data[batch_idx, 0, time_idx])
                self.real_cursor_velocities.append(self.real_data[batch_idx, 1, time_idx])

        diff = tf.subtract(self.computed_cursor_velocities, self.real_cursor_velocities)
        self.error = tf.reduce_sum(tf.square(diff))
        # tvars = tf.get_collection(tf.GraphKeys.TRAINABLE_VARIABLES, scope=tf.get_variable_scope().name)

        # train_op = tf.train.GradientDescentOptimizer(0.000005).minimize(self.error)
        self.train_op = tf.train.AdamOptimizer(0.01).minimize(self.error)

        # Normal TensorFlow - initialize values, create a session and run the model
        self.model = tf.global_variables_initializer()

        tf.summary.scalar('error', self.error)
        tf.summary.scalar('l_s', self.l_s)
        tf.summary.scalar('l_e', self.l_e)
        tf.summary.scalar('theta_initial_s', self.theta_initial[0, 0])
        tf.summary.scalar('theta_initial_e', self.theta_initial[0, 1])

        self.merged = tf.summary.merge_all()

    def run(self, spikes, cursor_velocities):
        with tf.Session() as session:
            # [session.run(c) for c in computed_cursor_velocities_across_trials]
            writer = tf.summary.FileWriter('/tmp/logs', session.graph)

            print(session.run(self.model))

            # Train!
            i = 0
            current_error = sys.float_info.max
            feed_dict = self._feed_dict(spikes, cursor_velocities)
            while current_error > 5000.0:
                current_error, summary, _ = session.run([self.error, self.merged, self.train_op],
                    feed_dict=feed_dict)
                if i % 200 == 0:
                    writer.add_summary(summary, i)
                    print("Trial %d: Error is at %.2f" % (i, current_error))
                i += 1
            A, b, theta_initial = session.run([self.A, self.b, self.theta_initial])
            print("DONE! error %.2f, A %s, b %s, initial_theta %s" % (current_error, A, b, theta_initial))
            writer.close()

    def _feed_dict(self, spikes, cursor_velocities):
        indices = np.random.choice(range(len(spikes)), BATCH_SIZE, replace=False)
        feed_dict = {
            self.spikes: spikes[indices, :, :],
            self.real_data: cursor_velocities[indices, :, :]}
        return feed_dict


def generate_trials() -> [Trial]:
    l_s = 1.0
    l_e = 1.5
    A = np.random.normal(0, 1.0, size=(NUM_CHANNELS, 2))
    b = np.random.normal(0, 1.0, size=(2,))
    num_trials = 1000
    num_time_steps = 10

    initial_theta = np.random.uniform(-math.pi, math.pi, size=(NUM_OUTPUTS,))
    spikes = np.zeros((num_trials, NUM_CHANNELS, num_time_steps), dtype='double')

    # cursor velocity always zero at first
    cursor_velocities = np.zeros(shape=(num_trials, 2, num_time_steps), dtype='double')

    for trial_idx in range(num_trials):
        spike_data = np.random.poisson(2.0, size=(num_time_steps, NUM_CHANNELS))
        spikes[trial_idx, :, :] = spike_data.T

        thetas = np.zeros(shape=(num_time_steps, 2))
        thetas[0, :] = initial_theta

        for time_idx in range(num_time_steps - 1):
            omega = spike_data[time_idx] @ A + b
            thetas[time_idx + 1, :] = thetas[time_idx, :] + DT * omega
            cursor_velocities[trial_idx, :, time_idx + 1] = [
                -l_s * math.sin(thetas[time_idx, 0]) * omega[0] - l_e * math.sin(thetas[time_idx, 1]) * omega[1],
                l_s * math.cos(thetas[time_idx, 0]) * omega[0] + l_s * math.cos(thetas[time_idx, 1]) * omega[1]
            ]

    print(A)
    print(b)
    print(initial_theta)
    return spikes, cursor_velocities, A


if __name__ == '__main__':
    spikes, cursor_velocities, real_a = generate_trials()
    # numTrials x numChannels x numTimesteps
    Decoder(spikes.shape[2], real_a).run(spikes, cursor_velocities)
