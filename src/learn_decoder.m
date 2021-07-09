function [model] = learn_decoder(V, X)
    % learn_decoder(decoder.real_outputs, decoder.inputs(:, 2:end))
    % V is the "real". Should be numTrials x numOutputs
    % X is the input. Should be numTrials x numInputs

    num_iterations = 1000;
    l_s = 1;
    l_e = 1;

    num_trials = size(V, 1);
    num_intermediates = 4;
    num_inputs = size(X, 2);
    num_outputs = size(V, 2);

    A = randn(num_inputs, 4);
    b = randn(1, 4);
    errs = zeros(num_iterations, num_outputs);

    function [theta_s, theta_e, omega_s, omega_e, output] = go_forward(X, A, b)
        intermediate = X * A + b;
        theta_s = intermediate(:, 1);
        theta_e = intermediate(:, 2);
        omega_s = intermediate(:, 3);
        omega_e = intermediate(:, 4);
        output = [ ...
            -l_s * sin(theta_s) .* omega_s - l_e * sin(theta_e) .* omega_e, ...
             l_s * cos(theta_s) .* omega_s + l_s * cos(theta_e) .* omega_e ...
        ];
    end

    for iterationIdx = 1:num_iterations
        [theta_s, theta_e, omega_s, omega_e, output] = go_forward(X, A, b);

        cost = sum(0.5 * (V - output).^2);
        disp(sprintf('Iteration %d: Cost %.8f \n', iterationIdx, cost(1) + cost(2)));
        drawnow('update');

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
                    du_daij = zeros(1, 4);
                    du_daij(j) = X(trialIdx, i);

                    dt_daij = gradt * du_daij';
                    de_daij(trialIdx, i, j) = err(trialIdx, :) * dt_daij;
                end
            end
            de_db(trialIdx, :) = err(trialIdx, :) * gradt;
        end
        summed_grad = zeros(size(de_daij, 2), size(de_daij, 3));
        for trialIdx = 1:num_trials
            summed_grad = summed_grad + squeeze(de_daij(trialIdx, :, :));
        end
        summed_grad_b = sum(de_db, 1);

        x = [];
        eta = 1;
        while 1
            new_A = A + eta * summed_grad;
            new_b = b + eta * summed_grad_b;
            [~, ~, ~, ~, output] = go_forward(X, new_A, new_b);
            new_cost = sum(0.5 * (V - output).^2);
            if new_cost(1) >= cost(1) || new_cost(2) >= cost(2)
                if eta < 1e-10
                    A = new_A;
                    b = new_b;
                    break
                end
                eta = eta/(1 + 1e-3);
            else
                A = new_A;
                b = new_b;
                break
            end
        end
    end

    model = struct;
    model.A = A;
    model.b = b;
    plot(errs);
end
