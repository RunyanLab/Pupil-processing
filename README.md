# Pupil-processing
Code for intial processing of pupil movies of rodents with optional, possibly useful analysis of processing output, implemented in MATLAB. Works for grayscale and RGB .avis. Exmaple movies to test the code and its capabilities can be found [here](https://drive.google.com/drive/folders/1L4LqzA7hPC4DhDAlagq_gB9dk1eqcvuW). 

## Data acquisition info - good practices to ensure optimal and reliable processing
- Choose monitor brightness that constricts the pupil just enough to that changes cna be minotored. If basline pupil size is too large (large neough to be occluded partially by the eyelids) dilations will not be detectable
- Once a reasonable monitor luminance is reached, keep this constant across all imaging sessions
- Ensure light blocking apparaturs is not covering the imaged or non-imaged eye
- Do not use maximum aperture. If the area surrounding the pupil is too bright, isolating the pupil ROI from other objection within the FOV will be more challenging
- Keep the angle of the camera relative to the eye as consistent as possible across imaging sessions

## How to use
NOTE: This code has been tested in MATLAB 2019a and later. Older versions may be compatible but have not been tested.

### Getting started
1. Download the repository to a single directory
2. Make sure overhead directory and all subdirectories are added to your current MATLAB path 
3. Open 'forfitcircles.m' and edit variables related to base_path, base_path_wav, base_path_tseries, tot_file_save_path, save_path_pass, save_path_spont
base_path: the path where your unprocessed AVIs for dataset are saved
base_path_wav: the path where your wavesurfer files for dataset are saved
base_path_tseries: (optional) this will only be used by the code if you choose to do rough alignment rather than tight. The path where your tseries .tiff files for dataset are saved
tot_file_save_path: the location you would like final output file of processing to be saved. If you have context set to anything other than 'none' this is where the data for all contexts concatenated will be saved
save_path_pass: (optional) this will only be used if you input a context type other than 'none'. This is the location where the final output file for the passive context only will be saved
save_path_spont: (optional) this will only be used if you input a context tupe other than 'none'. This is the location nwhere the final output file for the spontaneous context only will be saved
NOTE: in these path names you should replace mouse ID in path name with mouse variable, date with date  variable and information about conext with cont variable, these will be variables you input once code is run

Once all paths have been properly edited to suit your data, you may run code with command 'forforcirles' or by hitting the RUN button in the Editing toolbar

### Running the code
In the command line you will be prompted to input:

Mouse ID: The name of the mosue exactly as it appears in your paths 

Date: Date of imaging session, exactly as it appears in your paths

Context: The experimental context of the data you are processing. If you data does not multiple contexts you would like to separate, set this variable to 'none'. Otherwise, input the current context 'pass' for passive or 'spont' for spontaneous.

Threshold: Threshold is the level used to generate BW pixel image. This code will turn each frame of your movie into a binary matrix of 0s and 1s related to each pixel's intesesity, and the assignment of 0 or 1 to each pixel is detemined by the set threshold value. We want pixels part of the pupil ROI to be set to 1 and all other pixels to be set to 0. So in simpler terms, the threshold is the unique value set to dictate which pixels will be included as part of the pupil ROI or excluded. 
                    Pixels with luminence > threshold value are set to 1 (white)
                    Pixels with luminance < threhsold value are set to 0 (black)
                    Therefore:
                    Higher threshold value --> fewer pixels get contained in pupil ROI
                    Lower thresold value --> more pixels get contained in pupil ROI
             You must test out different thresholds to find the value that works best for you data


Orientation:The orienation of the camera. If the camer is upright and pupil displays in natural orienation set this value to '0' (as it is on 2p+), if camera is rotated 180 degrees and the pupil displays rotated from its natrual orientation, set this value to '180'( as it is on 2P investigator). This is important because a circle is fit to the pupil by using only the 20% rightmost pixels and 20% leftmost pixels - this produces an accurately fit cirlce to frames where the mouse's eye is partially close and the eyelid covers top and bottom regions of the pupil (insert an image here for ease of understanding)

Unit: The units in which pupil area output will be given. Inputting 'm' will convert output to mm^2 (this is recommended if data was collected using investigator rig, coversion has been verified for this camera). Input of 'p' will keep the output in pix^2 (this is recommened if data was collected using 2p+, at the moment there is not a consistent conversion factor verified for this camera due to its adjustable zoom).

Alignment: The method for aligning pupil movies to all other simultaneous recordings (ie. 2P imaging, running signal, stimulus, etc). Input of 'r' means rought alighment will be executed. Rough alighment will rely on tseries .tiff files to count number of frames present in each imaging block and stretch/upsample the pupil signal in order to match this number. For recordings without wavesurfer recorded pupil camera signal this is the onyl option for alignment, however this is not the preferred option if tight alignment can be done, since this relies on the assumption that the camera frame rate is realiable and consistent.

km: Should kmeans clustering analysis be completed? This function will cluster the normalized pupil data into 3 clusters: high arousal, low arousal and transition state periods. Inputting 'y' will run this function and save all relevant variables into the file within tot_file_save_path. Inputting 'n' will skip running this function. Function uses pup_norm_30 to complete analysis

dilcon: should dilation/constriction detection analysis be completed? This function will . without constraint, constraints may be added to eliminate dilation/constriction events of small magnitudes or ones that occur within a larger event of interest. Inputting 'y' will run this function and save all relevant variables into the file within tot_file_save_path. Inputting 'n' will skip running this function.



Once all of these prompted inputs have been entered the code should run until completion.


## Output of processing
Individual files for each block will be saved in the base_path folder. Each file will contain the following:
- pupil: structure contating all pupil related fields below
  - center_position: sub-struct containing variable related to the pupil's position in the field of view
    - center_column: column vector containing column index where center of pupil is located. if your movie is not rotated this is analogous to x position, if movie                        is rotated 180 degrees this is analogous to y position 
    - center_row: vector containing row index where center of pupil is located.if your movie is not rotated this is analogous to y position, if movie                                     is rotated 180 degrees this is analogous to x position 
  - area: sub-struct containing variables related to the pupil area (note: all of these variables have been cut to only frames where 2P imaging is occurring)
    - corrected_areas: column vector of pupil areas after artifact correction (elimination of blink frames, saccades, physiologically impossible values and 
    - uncorrected_areas: column vecort of pupil areas without artifact correction
    - smoothed_30_timeframes:pupil areas after artifact correction gaussian smoothed over 30 frames
    - smoothed_10_timeframes: pupil area for each frame after artifact correction and smoothed by gaussian curve over 10 frames
  - radii: sub-struct containing variables related to the pupil radius for each frame (if conversion to area is not desired - could maybe add a blink corrected radii                          vector so that ppl wouldnt need to do this themselves
    -  uncut_uncorrected_radii: vector containing pupil radius measurement for each frame, not artifact corrected, not cut to galvo
    -  cut_uncorrected_radii: vector containing pupil radius measurement for each frame, not artifact corrected, cut to galvo
  -  blink: vector containing the indices of frames where pupil measurement is inaccurate due to a blink
  -  galvo_on: the frame of pupil movie where 2P imaging starts (the relative first frame of vectors that have been cut to galvo)
  -  galvo_off: the frame of pupil movie where 2P imaging ends (the relative last frame of vectors that have been cut to galvo)
  
 
 If you have different contexts and choose to save the indiviual contexts individually you will see files in the save paths for respective context with the following variables: 
 
- pupil_all: cell array where each cell is the pupil struct from an individual block (see above to definition of variables contained in individual 'pupil' structures). The following variables have been added to each block's pupil struct.
  - alignement:
    - galvo_temp: time points where peak of galvo signal occurred (in wavesufer units)
    - galvo_peaks: voltage value of each galvo frame peak
    - MatchedFrameInds: pupil frame identity assigned to each galvo frame 
    - MatchedFrameValsUnsmoothed: unsmoothed pupil area measurement at pupil frame assigned to each galvo frame
    - MatchedFrameValSmoothed10: pupil area measurement at pupil frame assigned to each galvo frame, smoothed over 10 timeframes
    - MatchedFrameValSmoothed30: pupil area measurement at pupil frame assigned to each galvo frame, smoothed over 30 timeframes 
- aligned_pupil_unsmoothed: unsmoothed pupil areas aligned to galvo frames, concatenated across all blocks and contexts (if applicable)
- aligned_pupil_smoothed_10: pupil areas smoothed over 10 time frames aligned to galvo frames, concatenated across all blocks and contexts (if applicable)
- aligned_pupil_smoothed_30: pupil areas smoothed over 30 time frames aligned to galvo frames, concatenated across all blocks and contexts (if applicable)
- pup_norm: normalized unsmoothed pupil areas aligned to galvo frames, concatenated across all blocks. Calculed by (pupil areas - mean(pupil areas))/mean(pupil areas)
- pup_norm_10: normalized pupil areas smoothed over 10 timeframes aligned to galvo frames, concatenated across all blocks within the context. Calculated just as in pup_norm but using areas smoothed by 10
- pup_norm_30: normalized pupil areas smoothed over 10 timeframes aligned to galvo frames, concatenated across all blocks within the context. Calculated just as in pup_norm but using areas smoothed by 30
- aligned_pupil_x_position: pupil position on the x-axis within the FOV aligned to galo frames, concatenated across all blocks within the context 
- aligned_pupil_y_position: pupil position on the y-axis within the FOV aligned to galo frames, concatenated across all blocks within the context
- x_velocity: running velocity in x aligned to galvo frames, concatenated across all blocks within the context. Not absolute value
- y_velocity: running velocity in y aligned to galvo frames, concatenated across all blocks within the context
- loco_sum: squared sum of the absolute value of x and y velocities
- loco_sum_smooth: loco_sum gaussian smoothed over 100 timeframes
- blockTransistions: indicies related to all block concatenated variables where there is an interface between two blocks

If you set cont to 'none' all of the above variables will be saved to file in the tot_file_save_path. If you do have multiple contexts, additional code will be run to concatenate across the two contexts, and those variables (following the same names) will be saved into tot_file_save_path.

If you input 'y' for kmeans analysis the following variables will also be present:
- C: value of the 2 centroids identified in the data ot be used to be used for classiication
- clusterlow: matrix where each column contains the value and index for each pupil frame that falls within the low cluster
- clusterhigh: matrix where each column contains the value and index for each pupil frame that falls within the high cluster
- transitionSmall: matrix where each column contains the value and index for each pupil frame that falls within the transistion cluster with transition being defined by datapoints where the difference between its distance from centroid high and centroid low isless than 0.05
- transitionLarge: matrix where each column contains the value and index for each pupil frame that falls within the transistion cluster with transition being defined by datapoints where the difference between its distance from centroid high and centroid low isless than 0.2
- classificationSmallTrans: row vector containing the assigned cluster for each pupil frame under the small transition paradigm
- classificationLargeTrans: row vector assigned cluster for each pupil frame under the large transition paradigm
- classificationNoTrans: row vector assigned cluster for each pupil frame where there is no transition group

If you input 'y' for dilcon analysis the following variables will also be present:
- ff: butterworth filtered aligned_pupil_smoothed_30 used for this analysis 
- Cpt: row vector containing the all indices that are considered constricted points (the minima of pupil changes)
- Dpts: row vector containing the all indices that are considered constricted points (the minima of pupil changes)
- cEvents: 2 row cell array where each column contains information on an indiviual constriction event. Constriction events are defined by period from a Cpt to a Dpt. The first row containes the value of pupil for all points during the event, the second row contains the indices over which the event took place
- dEvents: 2 row cell array where each column contains information on an indiviual dilation event. Dilaton events are defined by period from a Dpt to a Cpt. The first row containes the value of pupil for all points during the event, the second row contains the indices over which the event took place
- cDuration: for each cEvent, the length of time in seconds of event 
- dDuration:for each dEvent, the length of time in seconds of event 
- cMagnitude: for each cEvent, the the mean magnitude of change across an event. The average absolute rate of change for a given event
- dMagnitudefor each dEvent, the the mean magnitude of change across an event. The average absolute rate of change for a given event
- AVG_cDuration: across all cEvents, the average duration of an event 
- AVG_dDuration: across all dEvents, the average duration of an event 
- AVG_cMagnitude: across all cEvents, the average magnitude of change of an event
- AVG_dMagnitude: across all dEvents, the average magnitude of change of an event 
      
