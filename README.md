# Overview 
This Github repository contains MATLAB demo codes for image processing and spectral linear unmixing
using SHy-Cam data.
![alt text](https://https://github.com/PaulWZZtoLA/Single-snapshot-Hyperspectral-Phasor-Camera-SHy-Cam/blob/main/misc/Picture1.jpg?raw=true)

## Image pre-processing and spectra linear unmixing

SHy-Cam image is saved in *OME.tif* format. In order to successfully
load and save data using MATALB, make sure you follow the instruction linked here
to setup MATLAB environment:
https://docs.openmicroscopy.org/bio-formats/5.7.1/developers/matlab-dev.html

#### registration.m

Image registration is split into three actions in this script:

*Cropping*

The script loads a target image containing four channels and allows user
to mannually draw four rectangular masks to define the ROIs of each channel.
After dragging and draw each mask, user can adjust the locating points on the 
mask to adjust its size.  A double click anywhere on the image will confirm
the mask area and prompt the scrit to the next drawing.

*Manual control point locating*

*cpselect* function is called to mannually apply control points that represent
the same location between the reference channel (SIN) and moving channels. We found
8-10 points on the hexagonal edge of each channel and 1-2 points at the center of
each channel are enough to achieve good registration result. *cpcorr* function is 
then called to fine tune each control point pair by using 2-D cross-correlation.

*Image Registering*
The script loads the image to be registered and uses the priviously defined ROIs
and control points to apply local weighted mean-based registration
*Goshtasby, Ardeshir, "Image registration by local approximation methods," Image and Vision Computing, Vol. 6, 1988, pp. 255-261.*

The registered result is save as *OME.tif* file.


* linearunmixing.m
 