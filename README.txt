###########################
Structure from Motion (SFM)
###########################

dataRaw/ -> contains the behavioural results of the experiment

iViewXNao -> files that are used for the communication with the eye tracker. 

notes_meetings/  -> contains the parameters and ideas discussed in the meetigns with Megan and Nao.

srcPres/ -> SCRIPTS TO RUN THE EXPERIMENT:

		- 'initializeScreen.m': sets the default parameters to open the main window for the experiment.
		- 'setConstants.m' & 'setParamsSFM.m': adjust experimental parameters.
		- 'run_SFM.m': MAIN FILE. Runs the experiment.

scrPres/analysis/

		1- analysis_collect_eyeData: gets the raw data and read all trials for all sunjects into a matrix
		2- analysis_eyeData: collects all runs for each subject, collects all data across subjects, Analyze and plot behavioral and eye data 
		

%% To Do

Then adjust analysis_eyeData and run the graphs. Create the matrix for Megan



