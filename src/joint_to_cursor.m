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

    % 2009 Feb 28, see calibration.m
    L1 = 0.1818; % shoulder to elbow
    L2 = .2470; %forearm legnth
    L2ptr = 0.0237;
    sho_pos_x = .0283;
    sho_pos_y = -.1502;

    Offset_angle = 4/angle_GAIN; %Offset_angle = 2; %?? 4/2.5=1.6 rad or -91.67 degree offset per simulink 'External DAQ'

    THETAs = theta_s/angle_GAIN; 
    THETAs = [THETAs * (5000/2048)]/1000+Offset_angle;
    THETAe = theta_e/angle_GAIN; 
    THETAe = [THETAe * (5000/2048)]/1000+Offset_angle;

    THETApointer=pi/2;
    L1ang=THETAs;
    L2ang=THETAs+THETAe;
    L2_ptr_angle=THETAs+THETAe+THETApointer;
    epx=sho_pos_x +L1*cos(L1ang);
    epy=sho_pos_y +L1*sin(L1ang);
    cursor_pos_x = epx+L2*cos(L2ang);
    cursor_pos_y = epy+L2*sin(L2ang);

    THETAs_velocity = omega_s/angle_GAIN*angular_velocity_gain;
    THETAs_velocity = [THETAs_velocity * (5000/2048)]/1000;
    THETAe_velocity = omega_e/angle_GAIN*angular_velocity_gain;
    THETAe_velocity = [THETAe_velocity * (5000/2048)]/1000;

    J11 = -L1*sin(THETAs)-L2*sin(THETAe+THETAs)-L2ptr*sin(THETAe+THETAs+pi/2);
    J12 = -L2*sin(THETAe+THETAs) - L2ptr*sin(THETAe+THETAs+pi/2);
    J21 = L1*cos(THETAs)+L2*cos(THETAe+THETAs)+ L2ptr*cos(THETAe+THETAs+pi/2);
    J22 = L2*cos(THETAe+THETAs) + L2ptr*cos(THETAe+THETAs+pi/2);
    temp  = [J11 J12;J21 J22]*[THETAs_velocity; THETAe_velocity];
    cursor_vel_x = temp(1);
    cursor_vel_y = temp(2);
end