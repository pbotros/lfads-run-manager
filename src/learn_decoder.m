function [model] = learn_decoder(V, X)
    % learn_decoder(decoder.real_outputs, decoder.inputs(:, 2:end))
    % V is the "real". Should be numTrials x numOutputs
    % X is the input. Should be numTrials x numInputs

    eta = 0.0001;
    num_iterations = 50;
    l_s = 1;
    l_e = 1;

    num_trials = size(V, 1);
    num_intermediates = 4;
    num_inputs = size(X, 2);
    num_outputs = size(V, 2);

    A = randn(num_inputs, 4);
    b = randn(1, 4);
    errs = zeros(num_iterations, num_outputs);
    figure;
    for iterationIdx = 1:num_iterations
        disp(iterationIdx);
        intermediate = X * A + b;
        theta_s = intermediate(:, 1);
        theta_e = intermediate(:, 2);
        omega_s = intermediate(:, 3);
        omega_e = intermediate(:, 4);
        output = [ ...
            -l_s * sin(theta_s) .* omega_s - l_e * sin(theta_e) .* omega_e, ...
            -l_s * cos(theta_s) .* omega_s + l_s * cos(theta_e) .* omega_e ...
        ];
        err = abs(V - output);
        errs(iterationIdx, :) = sum(abs(err), 1);
        de_daij = zeros(num_trials, size(A, 1), size(A, 2));
        de_db = zeros(num_trials, size(b, 2));
        for trialIdx = 1:num_trials
            gradt = [ ...
                    -l_s * omega_s(trialIdx) * cos(theta_s(trialIdx)), ...
                    -l_e * omega_e(trialIdx) * cos(theta_e(trialIdx)), ...
                    -l_s * sin(theta_s(trialIdx)), ...
                    -l_e * sin(theta_e(trialIdx)), ...
                ; ...
                    -l_s * omega_s(trialIdx) * sin(theta_s(trialIdx)), ...
                    -l_e * omega_e(trialIdx) * sin(theta_e(trialIdx)), ...
                    l_s * cos(theta_s(trialIdx)), ...
                    l_e * cos(theta_e(trialIdx)), ...
            ];

            for i = 1:size(A, 1)
                for j = 1:size(A, 2)
                    du_daij = zeros(4, 1);
                    du_daij(j) = X(trialIdx, i);

                    dt_daij = (gradt * du_daij);
                    de_daij(trialIdx, i, j) = err(trialIdx, :) * dt_daij;
                end
            end
            de_db(trialIdx, :) = err(trialIdx, :) * gradt;
        end
        summed_grad = squeeze(sum(de_daij, 1));
        A = A - eta * summed_grad;
        b = b - eta * sum(de_db, 1);
    end

    model = struct;
    model.A = A;
    model.b = b;
    plot(errs);
end
