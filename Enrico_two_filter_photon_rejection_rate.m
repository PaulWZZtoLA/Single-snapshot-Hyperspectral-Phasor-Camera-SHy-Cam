%%
close all;
clear all;
%%
wavelength = [400:700];
COS = (cos(2*pi/301 * (wavelength - 400))/2)+0.5;
SIN = (sin(2*pi/301 * (wavelength - 400))/2)+0.5;
%%
sum_egfp = sum(EGFP);
G_egfp = COS'.*EGFP; G_egfp = sum(G_egfp)/sum_egfp; 
S_egfp = SIN'.*EGFP; S_egfp = sum(S_egfp)/sum_egfp; 
ave_egfp = (G_egfp+S_egfp) / 2;

sum_cfp = sum(CFP);
G_cfp = COS'.*CFP; G_cfp = sum(G_cfp)/sum_cfp; 
S_cfp = SIN'.*CFP; S_cfp = sum(S_cfp)/sum_cfp; 
ave_cfp = (G_cfp+S_cfp) / 2;

sum_rfp = sum(RFP);
G_rfp = COS'.*RFP; G_rfp = sum(G_rfp)/sum_rfp; 
S_rfp = SIN'.*RFP; S_rfp = sum(S_rfp)/sum_rfp; 
ave_rfp = (G_rfp+S_rfp) / 2;
