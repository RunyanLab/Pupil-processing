# Pupil-processing
Code for intial processing of pupil movies of rodents with optional, possibly useful analysis of processing output, implemented in MATLAB. Works for grayscale and RGB .avis. Exmaple movies to test the code and its capabilities can be found [here](https://drive.google.com/drive/folders/1L4LqzA7hPC4DhDAlagq_gB9dk1eqcvuW). 

## Data acquisition info - good collection practices to ensure optimal and reliable processing
- Choose monitor brightness that constricts the pupil just enough so that changes can be monitored. If basline pupil size is too large (large enough to be occluded partially by the eyelids) dilations will not be detectable
- Once a reasonable monitor luminance is reached, keep this constant across all imaging sessions
- Ensure light blocking apparaturs is not covering the imaged or non-imaged eye
- Do not use maximum aperture. If the area surrounding the pupil is too bright, isolating the pupil ROI from other objection within the FOV will be more challenging
- Keep the angle of the camera relative to the eye as consistent as possible across imaging sessions, saccades can lead to false changes in pupil size if angle is too sharp

## How to use
NOTE: This code has been tested in MATLAB 2019a and later. Older versions may be compatible but have not been tested.

### Getting started
1. Clone directory to local computer
2. Make sure overhead directory and all subdirectories are added to your current MATLAB path 
3. Open 'mainPupilProcessing.m' and edit variables related to rawDataFolder, acqFolder, tseriesBaseFolder, saveBaseFolder
rawDataFolder: The path where your unprocessed AVIs for dataset are saved
acqFolder: The path where your wavesurfer/molecular devices files for dataset are saved (this is only relevant if performing tight alignment of pupil to neural data)
tseriesBaseFolder: The path where your tseries .tiff files for dataset are saved (this is only relevant if performing rouhg alignment of pupil to neural data)
saveBaseFolder: The location you would like your fully aligned output file to be saved

You may also wish to exclude some rows/columns of the frame matrix from pupil detection, if there are areas of the frame that are as bright as the pupil, you may choose to eliminate rows/columns that the pupil can never appear within so that these objects arent mistakenly identified as pupil. The code has a safeguard against this on a frame by frame basis by comparing the center position of the pupil identified in the last frame and selecting the object with the nearest position on the current frame, however if there are multiple objects the same brightness as pupil on the very first frame of the movie, the code may choose incorrectly, so implementing some spatial restriction for where the pupil object may appear will ensure accurate idenfication across frames.
To edit this, see lines 91 through 94 

Once all paths have been properly edited to suit your data, you may run code by typing 'mainPupilProcessing' or by hitting the RUN button in the Editing toolbar

### Running the code
After hitting run, in the command line you will be prompted to input the following:

Mouse ID: The name of the mouse exactly as it appears in your paths 

Date: Date of imaging session, exactly as it appears in your paths

Frame rate: Sampling rate of your pupil camera

Threshold: Threshold is the level used to generate BW pixel image. This code will turn each frame of your movie into a binary matrix of 0s and 1s related to each pixel's intesesity, and the assignment of 0 or 1 to each pixel is detemined by the set threshold value. We want pixels part of the pupil ROI to be set to 1 and all other pixels to be set to 0. So in simpler terms, the threshold is the unique value set to dictate which pixels will be included as part of the pupil ROI or excluded. 
                    Pixels with luminence > threshold value are set to 1 (white)
                    Pixels with luminance < threhsold value are set to 0 (black)
                    Therefore:
                    Higher threshold value --> fewer pixels get contained in pupil ROI
                    Lower thresold value --> more pixels get contained in pupil ROI
             You must test out different thresholds to find the value that works best for you data


Orientation:The orienation of the camera. If the camer is upright and pupil displays in natural orienation set this value to '0' (as it is on 2p+), if camera is rotated 90 degrees and the pupil displays rotated from its natrual orientation, set this value to '90'( as it is on 2P investigator). This is important because a circle is fit to the pupil by using only the 20% rightmost pixels and 20% leftmost pixels - this produces an accurately fit cirlce to frames where the mouse's eye is partially close and the eyelid covers top and bottom regions of the pupil (insert an image here for ease of understanding)

Unit: The units in which pupil area output will be given. Inputting 'm' will convert output to mm^2 (this is recommended if data was collected using investigator rig, coversion has been verified for this camera). Input of 'p' will keep the output in pix^2 (this is recommened if data was collected using 2p+, at the moment there is not a consistent conversion factor verified for this camera due to its adjustable zoom).

Alignment: The method for aligning pupil movies to all other simultaneous recordings (ie. 2P imaging, running signal, stimulus, etc). Input of 'r' means rought alighment will be executed. Rough alighment will rely on tseries .tiff files to count number of frames present in each imaging block and stretch/upsample the pupil signal in order to match this number. For recordings without wavesurfer recorded pupil camera signal this is the onyl option for alignment, however this is not the preferred option if tight alignment can be done, since this relies on the assumption that the camera frame rate is realiable and consistent.

km: Should kmeans clustering analysis be completed? This function will cluster the normalized pupil data into 3 clusters: high arousal, low arousal and transition state periods. Inputting 'y' will run this function and save all relevant variables into the file within tot_file_save_path. Inputting 'n' will skip running this function. Function uses pup_norm_30 to complete analysis

dilcon: should dilation/constriction detection analysis be completed? This function will . without constraint, constraints may be added to eliminate dilation/constriction events of small magnitudes or ones that occur within a larger event of interest. Inputting 'y' will run this function and save all relevant variables into the file within tot_file_save_path. Inputting 'n' will skip running this function.



Once all of these prompted inputs have been entered the code should run to completion.


## Output of processing
Saved to rawDataFolder separate files will be saved containing the information for each pupil movie, this is the raw pupil output without any tranformation to align to neural data. Within each will be a structure called 'pupil' containing all of the following fields:
  - center_position: sub-struct containing variable related to the pupil's position in the field of view
    - center_column: column vector containing column index where center of pupil is located. If your movie is not rotated this is analogous to x position, if movie                        is rotated 90 degrees this is analogous to y position 
    - center_row: vector containing row index where center of pupil is located. If your movie is not rotated this is analogous to y position, if movie                                     is rotated 90 degrees this is analogous to x position 
  - area: sub-struct containing variables related to the pupil area (note: all of these variables have been cut to only frames where 2P imaging is occurring)
    - corrected_areas: column vector of pupil areas after artifact correction (elimination of blink frames, saccades, physiologically impossible values and 
    - uncorrected_areas: column vecort of pupil areas without artifact correction
    - smoothed_30_timeframes:pupil areas after artifact correction gaussian smoothed over 30 frames
    - smoothed_10_timeframes: pupil area for each frame after artifact correction and smoothed by gaussian curve over 10 frames
  - radii: sub-struct containing variables related to the pupil radius for each frame (if conversion to area is not desired)
    -  uncut_uncorrected_radii: vector containing pupil radius measurement for each frame, not artifact corrected, not cut to galvo
    -  cut_uncorrected_radii: vector containing pupil radius measurement for each frame, not artifact corrected, cut to galvo
  -  blink: vector containing the indices of frames where pupil measurement is inaccurate due to a blink
  -  galvo_on: the frame of pupil movie where 2P imaging starts (the relative first frame of vectors that have been cut to galvo)
  -  galvo_off: the frame of pupil movie where 2P imaging ends (the relative last frame of vectors that have been cut to galvo)
  
Saved to saveBaseFolder:
- aligned_pupil_unsmoothed: unsmoothed pupil areas aligned to galvo frames, concatenated across all blocks and contexts (if applicable)
- aligned_pupil_smoothed_10: pupil areas smoothed over 10 time frames aligned to galvo frames, concatenated across all blocks and contexts (if applicable)
- aligned_pupil_smoothed_30: pupil areas smoothed over 30 time frames aligned to galvo frames, concatenated across all blocks and contexts (if applicable)
- pup_norm_unsmoothed: normalized unsmoothed pupil areas aligned to galvo frames, concatenated across all blocks. Calculed by (pupil areas - mean(pupil areas))/mean(pupil areas)
- pup_norm_10: normalized pupil areas smoothed over 10 timeframes aligned to galvo frames, concatenated across all blocks within the context. Calculated just as in pup_norm_unsmoothed but using areas smoothed by 10
- pup_norm_30: normalized pupil areas smoothed over 10 timeframes aligned to galvo frames, concatenated across all blocks within the context. Calculated just as in pup_norm_unsmoothed but using areas smoothed by 30
- aligned_x_position: pupil position on the x-axis within the FOV aligned to galo frames, concatenated across all blocks within the context 
- aligned_y_position: pupil position on the y-axis within the FOV aligned to galo frames, concatenated across all blocks within the context
- blockTransistions: indicies related to all block concatenated variables where there is an interface between two blocks


If you input 'y' for kmeans analysis the following variables will also be present in saveBaseFolder:
- C: value of the 2 centroids identified in the data ot be used to be used for classiication
- clusterlow: matrix where each column contains the value and index for each pupil frame that falls within the low cluster
- clusterhigh: matrix where each column contains the value and index for each pupil frame that falls within the high cluster
- transitionSmall: matrix where each column contains the value and index for each pupil frame that falls within the transistion cluster with transition being defined by datapoints where the difference between its distance from centroid high and centroid low isless than 0.05
- transitionLarge: matrix where each column contains the value and index for each pupil frame that falls within the transistion cluster with transition being defined by datapoints where the difference between its distance from centroid high and centroid low isless than 0.2
- classificationSmallTrans: row vector containing the assigned cluster for each pupil frame under the small transition paradigm
- classificationLargeTrans: row vector assigned cluster for each pupil frame under the large transition paradigm
- classificationNoTrans: row vector assigned cluster for each pupil frame where there is no transition group

If you input 'y' for dilcon analysis the following variables will also be present:
- ff: butterworth filtered pupil trace used for this analysis 
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
      
