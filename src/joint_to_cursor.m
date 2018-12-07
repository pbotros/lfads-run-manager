% from hand_position_BMI.m
function [cursor_pos_x, cursor_pos_y, cursor_vel_x, cursor_vel_y] = joint_to_cursor(theta_s, theta_e, omega_s, omega_e)
    % theta_s: Angular position, shoulder
    % theta_e: Angular position, elbow
    % omega_s: Angular velocity, shoulder
    % omega_e: Angular velocity, elbow

    angle_GAIN = 2.5;
    %PLEX_GAIN=406;
    %PLEX_GAIN=408; %?????????? (% 409.5946 in another trial)
    angular_velocity_gain = 0.5;
    angular_velocity_gain = angle_GAIN/angular_velocity_gain; %*2;

    % Make sure to use the calibration data from Paco Right Hand, not calibration.m
    L1 = .10750; % shoulder to elbow
    L2 = .23685; %forearm legnth
    L2ptr = -.01198;
    sho_pos_x = .02502;
    sho_pos_y = -.13435;
    Offset_angle = 4/angle_GAIN; %Offset_angle = 2; %?? 4/2.5=1.6 rad or -91.67 degree offset per simulink 'External DAQ'

    THETAs = theta_s/angle_GAIN+Offset_angle; % in rads; link 1;
    THETAe = theta_e/angle_GAIN+Offset_angle;
    [elb_pos_x, elb_pos_y] = pol2cart(THETAs, L1);
    [hand_pos_x, hand_pos_y] = pol2cart(THETAe+THETAs, L2);
    [pointer_x, pointer_y] = pol2cart(THETAe+THETAs+pi/2,L2ptr);
    
    cursor_pos_x = hand_pos_x + elb_pos_x + pointer_x + sho_pos_x;
    cursor_pos_y = hand_pos_y + elb_pos_y + pointer_y + sho_pos_y;

    THETAs_velocity = omega_s/angle_GAIN*angular_velocity_gain;
    THETAe_velocity = omega_e/angle_GAIN*angular_velocity_gain;
    J11 = -L1*sin(THETAs)-L2*sin(THETAe+THETAs)-L2ptr*sin(THETAe+THETAs+pi/2);
    J12 = -L2*sin(THETAe+THETAs) - L2ptr*sin(THETAe+THETAs+pi/2);
    J21 = L1*cos(THETAs)+L2*cos(THETAe+THETAs)+ L2ptr*cos(THETAe+THETAs+pi/2);
    J22 = L2*cos(THETAe+THETAs) + L2ptr*cos(THETAe+THETAs+pi/2);
    temp  = [J11 J12;J21 J22]*[THETAs_velocity; THETAe_velocity];
    cursor_vel_x = temp(1);
    cursor_vel_y = temp(2);
end