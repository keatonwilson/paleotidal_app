--%% Sophie Ward 21/6/23 %%--

-All saved as lon*lat*variable
-Should all be the same length and dimensions
-Saved as tab delimited ascii files, without headers, file extensions can just changed to .xyz

--------------
RSL
-files "rsl_00.ascii" through "rsl_21.ascii"
-relative sea levels (the 'GIA', depends how it was phrased in the last GUI - it's the sea level relative to present-day)
-rsl_00.ascii is all zeros, as it is just the present-day water depth

mask_water
-files "mask_water_00.ascii" through "mask_water_21.ascii"
- Binary mask, 1=water, 0=land or ice

Water_depth
-files "h_00.ascii" through "h_21.ascii"
- Water depth in meters

ampM2
- this is the elevation amplitude of the M2 tidal constituent, in meters

bss
- this is the peak near-bed bed shear stress, based on M2+S2+N2+M4 tidal constituents, as output by the model
- units N m^{-2}
- u-components (peakbss_u_*) and v-components (peakbss_v_*) of the bss, for vector visualisation [u=west-east +ve, v=south-north +ve], so u=1 N m-2 and v=1 N m-2 would give uv=1.4 N m-2, with arrow orientated @1:30 on a clock!
- peakbss_uv* are the absolute magnitudes of the u- and v- components of bss, same units

----------------
Velocity and stratification files still processing (21/6/23)

