# Overview 
This Github repository contains MATLAB demo codes for image processing and spectral linear unmixing
using SHy-Cam data.

## Image pre-processing and spectra linear unmixing
### Matlab script:

registration.m

Image registration is split into three actions in this script:

*Cropping*

The script loads a target image containing four channels and allows user
to mannually draw four rectangular masks to define the ROIs of each channel.
After dragging and draw each mask, user can adjust the locating points on the 
mask to adjust its size.  A double click anywhere on the image will confirm
the mask area and prompt the scrit to the next drawing.

* linearunmixing.m
 