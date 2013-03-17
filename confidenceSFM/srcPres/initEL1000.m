function [] = initEL1000(filename);

% open link
if ~eyelink('isconnected');
    eyelink('initialize');
end


status = eyelink('openfile', filename);
if status~=0
	eyelink('Shutdown');
    clear mex;
	error(sprintf('Cannot create %s (error: %d)- eyelink shutdown', status,filename));
end


% send standard parameters
eyelink('command', ['add_file_preamble_text ','EL1000, visual search, wet, original name wet']);
eyelink('command', 'calibration_type = HV13');
eyelink('command', 'saccade_velocity_threshold = 35');
eyelink('command', 'saccade_acceleration_threshold = 9500');
eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,BUTTON');
eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,AREA');
eyelink('command', 'button_function 5 ''accept_target_fixation''');
