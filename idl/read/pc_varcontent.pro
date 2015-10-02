;
;  $Id$
;
; VARCONTENT STRUCTURE DESCRIPTION
;
; variable (string)
;   Human readable name for the variable
;
; idlvar (string)
;   Name of the variable (usually in the IDL global namespace)
;   in which the variables data will be stored
;
; idlinit (string)
;   IDL command to initialise the storage variable ready for
;   reading in from a file
;
; idlvarloc (string)
;   As idlvar but used when two grid sizes are used eg. global mesh
;   and processor mesh (local -> loc). And used in processes such
;   as in rall.pro.  Eg. uses mesh sizes of (mxloc,myloc,mzloc)
;
; idlinitloc (string)
;   Again as idlinit but used when two mesh sizes are required at once.
;   see idlvarloc
;
function pc_varcontent, datadir=datadir, dim=dim, param=param, $
    run2D=run2D, scalar=scalar, noaux=noaux, quiet=quiet
COMPILE_OPT IDL2,HIDDEN
;
;  Read grid dimensions, input parameters and location of datadir.
;
if (n_elements(dim) eq 0) then pc_read_dim,obj=dim,datadir=datadir,quiet=quiet
if (n_elements(param) eq 0) then pc_read_param,obj=param,datadir=datadir, $
    dim=dim,quiet=quiet
if (not keyword_set(datadir)) then datadir=pc_get_datadir()
; 
;  Read the positions of variables in f.
;
cmd = 'perl -000 -ne '+"'"+'s/[ \t]+/ /g; print join(" & ",split(/\n/,$_)),"\n"'+"' "+datadir+'/index.pro'
spawn, cmd, result
res = flatten_strings(result) 
index=strsplit(res,'&',/extract)
nindex=n_elements(index)
for i=0,nindex-1 do begin
  if (execute(index[i]) ne 1) then $
  message, 'pc_varcontent: there was a problem with index.pro at line '+string(i+1)+'.', /info
endfor
;
;  The number of variables in the snapshot file depends on whether we
;  are writing auxiliary data or not. Auxiliary variables can be turned
;  off by hand by setting noaux=1, e.g. for reading derivative snapshots.
;
default, noaux, 0
totalvars=dim.mvar
if ((param.lwrite_aux ne 0) and (not noaux)) then totalvars=dim.mvar+dim.maux
;
;  Make an array of structures in which to store their descriptions.
;  Index zero is kept as a dummy entry.
;
varcontent=replicate({varcontent_all, $
    variable:'UNKNOWN', $ 
    idlvar:'dummy', $
    idlinit:'fltarr(mx,my,mz)*one', $
    idlvarloc:'dummy_loc', $
    idlinitloc:'fltarr(mxloc,myloc,mzloc)*one', $
    skip:0}, totalvars+1)
;
;  Predefine some variable types used regularly.
;
if (keyword_set(run2D)) then begin
;
;  For 2-D runs with lwrite_2d=T. Data has been written by the code without
;  ghost zones in the missing direction. We add ghost zones here anyway so
;  that the array can be treated exactly like 3-D data.
;  
  if (dim.nx eq 1) then begin
;  2-D run in (y,z) plane.
    INIT_3VECTOR     = 'fltarr(mx,my,mz,3)*one'
    INIT_3VECTOR_LOC = 'fltarr(myloc,mzloc,3)*one'
    INIT_SCALAR      = 'fltarr(mx,my,mz)*one'
    INIT_SCALAR_LOC  = 'fltarr(myloc,mzloc)*one'
  endif else if (dim.ny eq 1) then begin
;  2-D run in (x,z) plane.
    INIT_3VECTOR     = 'fltarr(mx,my,mz,3)*one'
    INIT_3VECTOR_LOC = 'fltarr(mxloc,mzloc,3)*one'
    INIT_SCALAR      = 'fltarr(mx,my,mz)*one'
    INIT_SCALAR_LOC  = 'fltarr(mxloc,mzloc)*one'
  endif else begin
;  2-D run in (x,y) plane.
    INIT_3VECTOR     = 'fltarr(mx,my,mz,3)*one'
    INIT_3VECTOR_LOC = 'fltarr(mxloc,myloc,3)*one'
    INIT_SCALAR      = 'fltarr(mx,my,mz)*one'
    INIT_SCALAR_LOC  = 'fltarr(mxloc,myloc)*one'
  endelse
endif else begin
;
;  Regular 3-D run.
;
  INIT_3VECTOR     = 'fltarr(mx,my,mz,3)*one'
  INIT_3VECTOR_LOC = 'fltarr(mxloc,myloc,mzloc,3)*one'
  INIT_SCALAR      = 'fltarr(mx,my,mz)*one'
  INIT_SCALAR_LOC  = 'fltarr(mxloc,myloc,mzloc)*one'
endelse
;
;  For EVERY POSSIBLE variable in a snapshot file, store a
;  description of the variable in an indexed array of structures
;  where the indexes line up with those in the saved f array.
;
;  Any variable not stored should have iXXXXXX set to zero
;  and will only update the dummy index zero entry.
;
default, iuu, 0
if (iuu gt 0) then begin
  varcontent[iuu].variable   = 'Velocity (uu)'
  varcontent[iuu].idlvar     = 'uu'
  varcontent[iuu].idlinit    = INIT_3VECTOR
  varcontent[iuu].idlvarloc  = 'uu_loc'
  varcontent[iuu].idlinitloc = INIT_3VECTOR_LOC
  varcontent[iuu].skip       = 2
endif
;
default, ipp, 0
if (ipp gt 0) then begin
  varcontent[ipp].variable   = 'Pressure (pp)'
  varcontent[ipp].idlvar     = 'pp'
  varcontent[ipp].idlinit    = INIT_SCALAR
  varcontent[ipp].idlvarloc  = 'pp_loc'
  varcontent[ipp].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ippp, 0
if (ippp gt 0) then begin
  varcontent[ippp].variable   = 'Pressure as auxiliary variable (ppp)'
  varcontent[ippp].idlvar     = 'ppp'
  varcontent[ippp].idlinit    = INIT_SCALAR
  varcontent[ippp].idlvarloc  = 'ppp_loc'
  varcontent[ippp].idlinitloc = INIT_SCALAR_LOC
endif
;
default, isss, 0
if (isss gt 0) then begin
  varcontent[isss].variable   = 'Entropy as auxiliary variable (sss)'
  varcontent[isss].idlvar     = 'sss'
  varcontent[isss].idlinit    = INIT_SCALAR
  varcontent[isss].idlvarloc  = 'sss_loc'
  varcontent[isss].idlinitloc = INIT_SCALAR_LOC
endif
;
default, icp, 0
if (icp gt 0) then begin
  varcontent[icp].variable   = 'Specific heat (cp) as auxiliary variable'
  varcontent[icp].idlvar     = 'cp'
  varcontent[icp].idlinit    = INIT_SCALAR
  varcontent[icp].idlvarloc  = 'cp_loc'
  varcontent[icp].idlinitloc = INIT_SCALAR_LOC
endif
;
default, icv, 0
if (icv gt 0) then begin
  varcontent[icv].variable   = 'Specific heat (cv) as auxiliary variable'
  varcontent[icv].idlvar     = 'cv'
  varcontent[icv].idlinit    = INIT_SCALAR
  varcontent[icv].idlvarloc  = 'cv_loc'
  varcontent[icv].idlinitloc = INIT_SCALAR_LOC
endif
;
default, igamma, 0
if (igamma gt 0) then begin
  varcontent[igamma].variable   = 'Ratio of specific heat (gamma) as auxiliary variable'
  varcontent[igamma].idlvar     = 'gamma'
  varcontent[igamma].idlinit    = INIT_SCALAR
  varcontent[igamma].idlvarloc  = 'gamma_loc'
  varcontent[igamma].idlinitloc = INIT_SCALAR_LOC
endif
;
default, inabad, 0
if (inabad gt 0) then begin
  varcontent[inabad].variable   = 'adiabatic logarithmic temperature gradient (nabad) as auxiliary variable'
  varcontent[inabad].idlvar     = 'nabad'
  varcontent[inabad].idlinit    = INIT_SCALAR
  varcontent[inabad].idlvarloc  = 'nabad_loc'
  varcontent[inabad].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ics, 0
if (ics gt 0) then begin
  varcontent[ics].variable   = 'Sound speed (cs) as auxiliary variable'
  varcontent[ics].idlvar     = 'cs'
  varcontent[ics].idlinit    = INIT_SCALAR
  varcontent[ics].idlvarloc  = 'cs_loc'
  varcontent[ics].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ilnrho, 0
if (ilnrho gt 0) then begin
  varcontent[ilnrho].variable   = 'Log density (lnrho)'
  varcontent[ilnrho].idlvar     = 'lnrho'
  varcontent[ilnrho].idlinit    = INIT_SCALAR
  varcontent[ilnrho].idlvarloc  = 'lnrho_loc'
  varcontent[ilnrho].idlinitloc = INIT_SCALAR_LOC
endif
;
default, irho, 0
if (irho gt 0) then begin
  varcontent[irho].variable   = 'Density (rho)'
  varcontent[irho].idlvar     = 'rho'
  varcontent[irho].idlinit    = INIT_SCALAR
  varcontent[irho].idlvarloc  = 'rho_loc'
  varcontent[irho].idlinitloc = INIT_SCALAR_LOC
endif
;
default, iss, 0
if (iss gt 0) then begin
  varcontent[iss].variable   = 'Entropy (ss)'
  varcontent[iss].idlvar     = 'ss'
  varcontent[iss].idlinit    = INIT_SCALAR
  varcontent[iss].idlvarloc  = 'ss_loc'
  varcontent[iss].idlinitloc = INIT_SCALAR_LOC
endif
;
default, irho_b, 0
if (irho_b gt 0) then begin
  varcontent[irho_b].variable   = 'Base density (rho_b)'
  varcontent[irho_b].idlvar     = 'rho_b'
  varcontent[irho_b].idlinit    = INIT_SCALAR
  varcontent[irho_b].idlvarloc  = 'rho_b_loc'
  varcontent[irho_b].idlinitloc = INIT_SCALAR_LOC
endif
;
default, irhs, 0
if (irhs gt 0) then begin
  varcontent[irhs].variable   = 'RHS (NS)'
  varcontent[irhs].idlvar     = 'rhs'
  varcontent[irhs].idlinit    = INIT_3VECTOR
  varcontent[irhs].idlvarloc  = 'rhs_loc'
  varcontent[irhs].idlinitloc = INIT_3VECTOR_LOC
  varcontent[irhs].skip       = 2
endif
;
default, iss_b, 0
if (iss_b gt 0) then begin
  varcontent[iss_b].variable   = 'Base Entropy (ss_b)'
  varcontent[iss_b].idlvar     = 'ss_b'
  varcontent[iss_b].idlinit    = INIT_SCALAR
  varcontent[iss_b].idlvarloc  = 'ss_b_loc'
  varcontent[iss_b].idlinitloc = INIT_SCALAR_LOC
endif
;
default, iaa, 0
if (iaa gt 0) then begin
  varcontent[iaa].variable   = 'Magnetic vector potential (aa)'
  varcontent[iaa].idlvar     = 'aa'
  varcontent[iaa].idlinit    = INIT_3VECTOR
  varcontent[iaa].idlvarloc  = 'aa_loc'
  varcontent[iaa].idlinitloc = INIT_3VECTOR_LOC
  varcontent[iaa].skip       = 2
endif
;
default, iaphi, 0
if (iaphi gt 0) then begin
  varcontent[iaphi].variable   = 'A_phi (aphi)'
  varcontent[iaphi].idlvar     = 'aphi'
  varcontent[iaphi].idlinit    = INIT_SCALAR
  varcontent[iaphi].idlvarloc  = 'aphi'
  varcontent[iaphi].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ibphi, 0
if (ibphi gt 0) then begin
  varcontent[ibphi].variable   = 'B_phi (bphi)'
  varcontent[ibphi].idlvar     = 'bphi'
  varcontent[ibphi].idlinit    = INIT_SCALAR
  varcontent[ibphi].idlvarloc  = 'bphi'
  varcontent[ibphi].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ibb, 0
if (ibb gt 0) then begin
  varcontent[ibb].variable   = 'Magnetic field (bb)'
  varcontent[ibb].idlvar     = 'bb'
  varcontent[ibb].idlinit    = INIT_3VECTOR
  varcontent[ibb].idlvarloc  = 'bb_loc'
  varcontent[ibb].idlinitloc = INIT_3VECTOR_LOC
  varcontent[ibb].skip       = 2
endif
;
default, ijj, 0
if (ijj gt 0) then begin
  varcontent[ijj].variable   = 'Current density (jj)'
  varcontent[ijj].idlvar     = 'jj'
  varcontent[ijj].idlinit    = INIT_3VECTOR
  varcontent[ijj].idlvarloc  = 'jj_loc'
  varcontent[ijj].idlinitloc = INIT_3VECTOR_LOC
  varcontent[ijj].skip       = 2
endif
;
default, iemf, 0
if (iemf gt 0) then begin
  varcontent[iemf].variable   = 'Current density (emf)'
  varcontent[iemf].idlvar     = 'emf'
  varcontent[iemf].idlinit    = INIT_3VECTOR
  varcontent[iemf].idlvarloc  = 'emf_loc'
  varcontent[iemf].idlinitloc = INIT_3VECTOR_LOC
  varcontent[iemf].skip       = 2
endif
;
default, ip11, 0
if (ip11 gt 0) then begin
  varcontent[ip11].variable   = 'Polymer Tensor 11 (p11)'
  varcontent[ip11].idlvar     = 'p11'
  varcontent[ip11].idlinit    = INIT_SCALAR
  varcontent[ip11].idlvarloc  = 'p11_loc'
  varcontent[ip11].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ip12, 0
if (ip12 gt 0) then begin
  varcontent[ip12].variable   = 'Polymer Tensor 12 (p11)'
  varcontent[ip12].idlvar     = 'p12'
  varcontent[ip12].idlinit    = INIT_SCALAR
  varcontent[ip12].idlvarloc  = 'p12_loc'
  varcontent[ip12].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ip13, 0
if (ip13 gt 0) then begin
  varcontent[ip13].variable   = 'Polymer Tensor 13 (p13)'
  varcontent[ip13].idlvar     = 'p13'
  varcontent[ip13].idlinit    = INIT_SCALAR
  varcontent[ip13].idlvarloc  = 'p13_loc'
  varcontent[ip13].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ip22, 0
if (ip22 gt 0) then begin
  varcontent[ip22].variable   = 'Polymer Tensor 22 (p22)'
  varcontent[ip22].idlvar     = 'p22'
  varcontent[ip22].idlinit    = INIT_SCALAR
  varcontent[ip22].idlvarloc  = 'p22_loc'
  varcontent[ip22].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ip23, 0
if (ip23 gt 0) then begin
  varcontent[ip23].variable   = 'Polymer Tensor 23 (p23)'
  varcontent[ip23].idlvar     = 'p23'
  varcontent[ip23].idlinit    = INIT_SCALAR
  varcontent[ip23].idlvarloc  = 'p23_loc'
  varcontent[ip23].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ip33, 0
if (ip33 gt 0) then begin
  varcontent[ip33].variable   = 'Polymer Tensor 23 (p33)'
  varcontent[ip33].idlvar     = 'p33'
  varcontent[ip33].idlinit    = INIT_SCALAR
  varcontent[ip33].idlvarloc  = 'p33_loc'
  varcontent[ip33].idlinitloc = INIT_SCALAR_LOC
endif
;
default, igij, 0
if (igij gt 0) then begin
  varcontent[igij].variable   = 'Gravitational Metric (gij)'
  varcontent[igij].idlvar     = 'gij'
  varcontent[igij].idlinit    = INIT_3VECTOR
  varcontent[igij].idlvarloc  = 'gij_loc'
  varcontent[igij].idlinitloc = INIT_3VECTOR_LOC
  varcontent[igij].skip       = 2
endif
;
default, iuut, 0
if (iuut gt 0) then begin
  varcontent[iuut].variable   = 'Integrated velocity (uut)'
  varcontent[iuut].idlvar     = 'uut'
  varcontent[iuut].idlinit    = INIT_3VECTOR
  varcontent[iuut].idlvarloc  = 'uut_loc'
  varcontent[iuut].idlinitloc = INIT_3VECTOR_LOC
  varcontent[iuut].skip       = 2
endif
;
default, iaatest, 0
if (iaatest gt 0) then begin
  default, ntestfield, 0
  varcontent[iaatest].variable   = 'Testfield vector potential (aatest)'
  varcontent[iaatest].idlvar     = 'aatest'
  ; This allows pc_read_var to read var.dat without giving initialising errors
  varcontent[iaatest].idlinit    = 'fltarr(mx,my,mz,'+str(ntestfield)+')*one'
  ;varcontent[iaatest].idlinit    = INIT_3VECTOR
  varcontent[iaatest].idlvarloc  = 'aatest_loc'
  varcontent[iaatest].idlinitloc = 'fltarr(mxloc,myloc,mzloc,'+str(ntestfield)+')*one'
  ;varcontent[iaatest].idlinitloc = INIT_3VECTOR_LOC
  varcontent[iaatest].skip       = ntestfield-1
endif
;
default, iuutest, 0
if (iuutest gt 0) then begin
  default, ntestflow, 0
  varcontent[iuutest].variable   = 'Testflow (uutest)'
  varcontent[iuutest].idlvar     = 'uutest'
  varcontent[iuutest].idlinit    = 'fltarr(mx,my,mz,'+str(ntestflow)+')*one'
  varcontent[iuutest].idlvarloc  = 'uutest_loc'
  varcontent[iuutest].idlinitloc = 'fltarr(mxloc,myloc,mzloc,'+str(ntestflow)+')*one'
  varcontent[iuutest].skip       = ntestflow-1
endif
;
default, icctest, 0
if (icctest gt 0) then begin
default, ntestscalar, 0
if ntestscalar ne 0 then print, '====> ntestscalar=', ntestscalar
  varcontent[icctest].variable   = 'Testflow (cctest)'
  varcontent[icctest].idlvar     = 'cctest'
  varcontent[icctest].idlinit    = 'fltarr(mx,my,mz,'+str(ntestscalar)+')*one'
  varcontent[icctest].idlvarloc  = 'cctest_loc'
  varcontent[icctest].idlinitloc = 'fltarr(mxloc,myloc,mzloc,'+str(ntestscalar)+')*one'
  varcontent[icctest].skip       = ntestscalar-1
endif
;
;default, iuxb, 0
;if (iuxb gt 0) then begin
;  varcontent[iuxb].variable   = 'Testfield vector potential (uxb)'
;  varcontent[iuxb].idlvar     = 'uxb'
;  varcontent[iuxb].idlinit    = 'fltarr(mx,my,mz,ntestfield)*one'
;  varcontent[iuxb].idlvarloc  = 'uxb_loc'
;  varcontent[iuxb].idlinitloc = 'fltarr(mxloc,myloc,mzloc,ntestfield)*one'
;  varcontent[iuxb].skip       = ntestfield-1
;endif
;
default, iuun, 0
if (iuun gt 0) then begin
  varcontent[iuun].variable   = 'Velocity of neutrals (uun)'
  varcontent[iuun].idlvar     = 'uun'
  varcontent[iuun].idlinit    = INIT_3VECTOR
  varcontent[iuun].idlvarloc  = 'uun_loc'
  varcontent[iuun].idlinitloc = INIT_3VECTOR_LOC
  varcontent[iuun].skip       = 2
endif
;
default, ispitzer, 0
if (ispitzer gt 0) then begin
  varcontent[ispitzer].variable   = 'Heat flux vector according to Spitzer'
  varcontent[ispitzer].idlvar     = 'spitzer'
  varcontent[ispitzer].idlinit    = INIT_3VECTOR
  varcontent[ispitzer].idlvarloc  = 'spitzer_loc'
  varcontent[ispitzer].idlinitloc = INIT_3VECTOR_LOC
  varcontent[ispitzer].skip       = 2
endif
;
default, ilnrhon, 0
if (ilnrhon gt 0) then begin
  varcontent[ilnrhon].variable   = 'Log density of neutrals (lnrhon)'
  varcontent[ilnrhon].idlvar     = 'lnrhon'
  varcontent[ilnrhon].idlinit    = INIT_SCALAR
  varcontent[ilnrhon].idlvarloc  = 'lnrhon_loc'
  varcontent[ilnrhon].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ifx, 0
if (ifx gt 0) then begin
  varcontent[ifx].variable   = 'Radiation vector ?something? (ff)'
  varcontent[ifx].idlvar     = 'ff'
  varcontent[ifx].idlinit    = INIT_3VECTOR
  varcontent[ifx].idlvarloc  = 'ff_loc'
  varcontent[ifx].idlinitloc = INIT_3VECTOR_LOC
  varcontent[ifx].skip       = 2
endif
;
default, ie, 0
if (ie gt 0) then begin
  varcontent[ie].variable   = 'Radiation scalar ?something? (ee)'
  varcontent[ie].idlvar     = 'ee'
  varcontent[ie].idlinit    = INIT_SCALAR
  varcontent[ie].idlvarloc  = 'ee_loc'
  varcontent[ie].idlinitloc = INIT_SCALAR_LOC
endif
;
default, icc, 0
if (icc[0] gt 0) then begin
  npscalar = n_elements(icc)
  if (npscalar gt 1) then begin
    for i = 0, npscalar - 1 do begin
      istr = strcompress(string(i+1),/remove_all) ;(the +1 so we start with CC1)
      varcontent[icc[i]].variable   = 'Passive Scalar (CC' + istr + ')'
      varcontent[icc[i]].idlvar     = 'CC' + istr
      varcontent[icc[i]].idlinit    = INIT_SCALAR
      varcontent[icc[i]].idlvarloc  = 'CC' + istr + '_loc'
      varcontent[icc[i]].idlinitloc = INIT_SCALAR_LOC
    endfor
  endif else begin
    varcontent[icc].variable   = 'Passive scalar (cc)'
    varcontent[icc].idlvar     = 'cc'
    varcontent[icc].idlinit    = INIT_SCALAR
    varcontent[icc].idlvarloc  = 'cc_loc'
    varcontent[icc].idlinitloc = INIT_SCALAR_LOC
  endelse
endif
;
default, ilncc, 0
if (ilncc gt 0) then begin
  varcontent[ilncc].variable   = 'Log passive scalar (lncc)'
  varcontent[ilncc].idlvar     = 'lncc'
  varcontent[ilncc].idlinit    = INIT_SCALAR
  varcontent[ilncc].idlvarloc  = 'lncc_loc'
  varcontent[ilncc].idlinitloc = INIT_SCALAR_LOC
endif
;
default, iXX_chiral, 0
if (iXX_chiral gt 0) then begin
  varcontent[iXX_chiral].variable   = 'XX_chiral'
  varcontent[iXX_chiral].idlvar     = 'XX_chiral'
  varcontent[iXX_chiral].idlinit    = INIT_SCALAR
  varcontent[iXX_chiral].idlvarloc  = 'XX_chiral_loc'
  varcontent[iXX_chiral].idlinitloc = INIT_SCALAR_LOC
endif
;
default, iYY_chiral, 0
if (iYY_chiral gt 0) then begin
  varcontent[iYY_chiral].variable   = 'YY_chiral'
  varcontent[iYY_chiral].idlvar     = 'YY_chiral'
  varcontent[iYY_chiral].idlinit    = INIT_SCALAR
  varcontent[iYY_chiral].idlvarloc  = 'YY_chiral_loc'
  varcontent[iYY_chiral].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ispecial, 0
if (ispecial gt 0) then begin
  varcontent[ispecial].variable   = 'Special'
  varcontent[ispecial].idlvar     = 'special'
  varcontent[ispecial].idlinit    = INIT_SCALAR
  varcontent[ispecial].idlvarloc  = 'special_loc'
  varcontent[ispecial].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ispec_3vec, 0
if (ispec_3vec gt 0) then begin
  varcontent[ispec_3vec].variable   = 'Special_3vector'
  varcontent[ispec_3vec].idlvar     = 'spec_3vec'
  varcontent[ispec_3vec].idlinit    = INIT_3VECTOR
  varcontent[ispec_3vec].idlvarloc  = 'spec_3vec_loc'
  varcontent[ispec_3vec].idlinitloc = INIT_3VECTOR_LOC
  varcontent[ispec_3vec].skip       = 2
endif
;
default, iphi, 0
if (iphi gt 0) then begin
  varcontent[iphi].variable   = 'Electric potential (phi)'
  varcontent[iphi].idlvar     = 'phi'
  varcontent[iphi].idlinit    = INIT_SCALAR
  varcontent[iphi].idlvarloc  = 'phi_loc'
  varcontent[iphi].idlinitloc = INIT_SCALAR_LOC
endif
;
default, iLam, 0
if (iLam gt 0) then begin
  varcontent[iLam].variable   = 'Gauge potential (Lam)'
  varcontent[iLam].idlvar     = 'Lam'
  varcontent[iLam].idlinit    = INIT_SCALAR
  varcontent[iLam].idlvarloc  = 'Lam_loc'
  varcontent[iLam].idlinitloc = INIT_SCALAR_LOC
endif
;
default, iecr, 0
if (iecr gt 0) then begin
  varcontent[iecr].variable   = 'Cosmic ray energy density (ecr)'
  varcontent[iecr].idlvar     = 'ecr'
  varcontent[iecr].idlinit    = INIT_SCALAR
  varcontent[iecr].idlvarloc  = 'ecr_loc'
  varcontent[iecr].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ifcr, 0
if (ifcr gt 0) then begin
  varcontent[ifcr].variable   = 'Cosmic ray energy flux (fcr)'
  varcontent[ifcr].idlvar     = 'fcr'
  varcontent[ifcr].idlinit    = INIT_3VECTOR
  varcontent[ifcr].idlvarloc  = 'fcr_loc'
  varcontent[ifcr].idlinitloc = INIT_3VECTOR_LOC
  varcontent[ifcr].skip       = 2
endif
;
default, itheta5, 0
if (itheta5 gt 0) then begin
  varcontent[itheta5].variable   = 'chem potential (theta5)'
  varcontent[itheta5].idlvar     = 'theta5'
  varcontent[itheta5].idlinit    = INIT_SCALAR
  varcontent[itheta5].idlvarloc  = 'theta5_loc'
  varcontent[itheta5].idlinitloc = INIT_SCALAR_LOC
endif
;
default, imu5, 0
if (imu5 gt 0) then begin
  varcontent[imu5].variable   = 'Cosmic ray energy density (ecr)'
  varcontent[imu5].idlvar     = 'mu5'
  varcontent[imu5].idlinit    = INIT_SCALAR
  varcontent[imu5].idlvarloc  = 'mu5_loc'
  varcontent[imu5].idlinitloc = INIT_SCALAR_LOC
endif
;
default, iam, 0
if (iam gt 0) then begin
  varcontent[iam].variable   = 'meanfield_dynamo_z (Am)'
  varcontent[iam].idlvar     = 'Am'
  varcontent[iam].idlinit    = INIT_3VECTOR
  varcontent[iam].idlvarloc  = 'Am_loc'
  varcontent[iam].idlinitloc = INIT_3VECTOR_LOC
  varcontent[iam].skip       = 2
endif
;
default, ipsi_real, 0
if (ipsi_real gt 0) then begin
  varcontent[ipsi_real].variable   = 'Wave function (real part)'
  varcontent[ipsi_real].idlvar     = 'psi_real'
  varcontent[ipsi_real].idlinit    = INIT_SCALAR
  varcontent[ipsi_real].idlvarloc  = 'psi_real_loc'
  varcontent[ipsi_real].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ipsi_imag, 0
if (ipsi_imag gt 0) then begin
  varcontent[ipsi_imag].variable   = 'Wave function (imaginary part)'
  varcontent[ipsi_imag].idlvar     = 'psi_imag'
  varcontent[ipsi_imag].idlinit    = INIT_SCALAR
  varcontent[ipsi_imag].idlvarloc  = 'psi_imag_loc'
  varcontent[ipsi_imag].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ialpm, 0
if (ialpm gt 0) then begin
  varcontent[ialpm].variable   = 'alpm'
  varcontent[ialpm].idlvar     = 'alpm'
  varcontent[ialpm].idlinit    = INIT_SCALAR
  varcontent[ialpm].idlvarloc  = 'alpm_loc'
  varcontent[ialpm].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ietat, 0
if (ietat gt 0) then begin
  varcontent[ietat].variable   = 'etat'
  varcontent[ietat].idlvar     = 'etat'
  varcontent[ietat].idlinit    = INIT_SCALAR
  varcontent[ietat].idlvarloc  = 'etat_loc'
  varcontent[ietat].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ieta, 0
if (ieta gt 0) then begin
  varcontent[ieta].variable   = 'Dust resistivity'
  varcontent[ieta].idlvar     = 'eta'
  varcontent[ieta].idlinit    = INIT_SCALAR
  varcontent[ieta].idlvarloc  = 'eta_loc'
  varcontent[ieta].idlinitloc = INIT_SCALAR_LOC
endif
;
default, izeta, 0
if (izeta gt 0) then begin
  varcontent[izeta].variable   = 'Ionization rate'
  varcontent[izeta].idlvar     = 'zeta'
  varcontent[izeta].idlinit    = INIT_SCALAR
  varcontent[izeta].idlvarloc  = 'zeta_loc'
  varcontent[izeta].idlinitloc = INIT_SCALAR_LOC
endif
;
default, ichemspec, 0
if (max(ichemspec) gt 0) then begin
  chemcount=n_elements(ichemspec)
  if (chemcount gt 0L) then begin
    for i=0,chemcount-1 do begin
      istr=strcompress(string(i+1),/remove_all) ;(the +1 so we start with YY1)
      varcontent[ichemspec[i]].variable   = 'Chemical species mass fraction (YY'+istr+')'
      varcontent[ichemspec[i]].idlvar     = 'YY'+istr
      varcontent[ichemspec[i]].idlinit    = 'fltarr(mx,my,mz)*one'
      varcontent[ichemspec[i]].idlvarloc  = 'YY'+istr+'_loc'
      varcontent[ichemspec[i]].idlinitloc = 'fltarr(mxloc,myloc,mzloc)*one'
    endfor
  endif
endif
;
default, iuud, 0
if (iuud[0] gt 0) then begin
  dustcount=n_elements(iuud) 
  if (dustcount gt 0L) then begin
    varcontent[iuud[0]].variable   = 'Dust velocity  (uud)'
    varcontent[iuud[0]].idlvar     = 'uud'
    varcontent[iuud[0]].idlinit    = 'fltarr(mx,my,mz,3,'+str(dustcount)+')*one' 
    varcontent[iuud[0]].idlvarloc  = 'uud_loc'
    varcontent[iuud[0]].idlinitloc = 'fltarr(mxloc,myloc,mzloc,3,'+str(dustcount)+')*one'
    varcontent[iuud[0]].skip       = (dustcount * 3) - 1
  endif
endif
;
default, ind, 0
if (ind[0] gt 0) then begin
  dustcount=n_elements(ind)
  if (dustcount gt 0L) then begin
    varcontent[ind[0]].variable   = 'Dust number density (nd)'
    varcontent[ind[0]].idlvar     = 'nd'
    varcontent[ind[0]].idlinit    = 'fltarr(mx,my,mz,'+str(dustcount)+')*one' 
    varcontent[ind[0]].idlvarloc  = 'nd_loc'
    varcontent[ind[0]].idlinitloc = 'fltarr(mxloc,myloc,mzloc,'+str(dustcount)+')*one'
    varcontent[ind[0]].skip       = dustcount - 1
  endif
endif
;
default, imd, 0
if (imd[0] gt 0) then begin
  dustcount=n_elements(imd)
  if (dustcount gt 0L) then begin
    varcontent[imd[0]].variable   = 'Dust density (md)'
    varcontent[imd[0]].idlvar     = 'md'
    varcontent[imd[0]].idlinit    = 'fltarr(mx,my,mz,'+str(dustcount)+')*one' 
    varcontent[imd[0]].idlvarloc  = 'md_loc'
    varcontent[imd[0]].idlinitloc = 'fltarr(mxloc,myloc,mzloc,'+str(dustcount)+')*one'
    varcontent[imd[0]].skip       = dustcount - 1
  endif
endif
;
default, imi, 0
if (imi gt 0) then begin
  dustcount=n_elements(imi)
  if (dustcount gt 0L) then begin
    varcontent[imi[0]].idlvar   = 'mi'
    varcontent[imi[0]].idlinit  = 'fltarr(mx,my,mz,'+str(dustcount)+')*one' 
    varcontent[imi[0]].idlvarloc= 'mi_loc'
    varcontent[imi[0]].idlinitloc = 'fltarr(mxloc,myloc,mzloc,'+str(dustcount)+')*one'
    varcontent[imi[0]].skip     = dustcount - 1
  endif
endif
;
; Special condition as can be maux or mvar variable
;
default, ilnTT, 0
if (ilnTT gt 0) then begin
  if ((ilnTT le dim.mvar) or (param.lwrite_aux ne 0)) then begin
    varcontent[ilnTT].variable   = 'Log temperature (lnTT)'
    varcontent[ilnTT].idlvar     = 'lnTT'
    varcontent[ilnTT].idlinit    = INIT_SCALAR
    varcontent[ilnTT].idlvarloc  = 'lnTT_loc'
    varcontent[ilnTT].idlinitloc = INIT_SCALAR_LOC
  endif
endif
;
default, iTT, 0
if (iTT gt 0) then begin
  if ((iTT le dim.mvar) or (param.lwrite_aux ne 0)) then begin
    varcontent[iTT].variable   = 'Temperature (TT)'
    varcontent[iTT].idlvar     = 'TT'
    varcontent[iTT].idlinit    = INIT_SCALAR
    varcontent[iTT].idlvarloc  = 'TT_loc'
    varcontent[iTT].idlinitloc = INIT_SCALAR_LOC
  endif
endif
;
default, ieth, 0
if (ieth gt 0) then begin
  varcontent[ieth].variable   = 'Thermal energy (eth)'
  varcontent[ieth].idlvar     = 'eth'
  varcontent[ieth].idlinit    = INIT_SCALAR
  varcontent[ieth].idlvarloc  = 'eth_loc'
  varcontent[ieth].idlinitloc = INIT_SCALAR_LOC
endif
;
;  Auxiliary variables (only if they have been saved).
;
if ((param.lwrite_aux ne 0) and (not noaux)) then begin
;
  default, iEE, 0
  if (iEE gt 0) then begin
    varcontent[iEE].variable   = 'Electric field (EE)'
    varcontent[iEE].idlvar     = 'EE'
    varcontent[iEE].idlinit    = INIT_3VECTOR
    varcontent[iEE].idlvarloc  = 'EE_loc'
    varcontent[iEE].idlinitloc = INIT_3VECTOR_LOC
    varcontent[iEE].skip       = 2
  endif
;
  default, iQrad, 0
  if (iQrad gt 0) then begin
    varcontent[iQrad].variable   = 'Radiative heating rate (Qrad)'
    varcontent[iQrad].idlvar     = 'Qrad'
    varcontent[iQrad].idlinit    = INIT_SCALAR
    varcontent[iQrad].idlvarloc  = 'Qrad_loc'
    varcontent[iQrad].idlinitloc = INIT_SCALAR_LOC
  endif
;
  default, ikapparho, 0
  if (ikapparho gt 0) then begin
    varcontent[ikapparho].variable   = 'Opacity (kapparho)'
    varcontent[ikapparho].idlvar     = 'kapparho'
    varcontent[ikapparho].idlinit    = INIT_SCALAR
    varcontent[ikapparho].idlvarloc  = 'kapparho_loc'
    varcontent[ikapparho].idlinitloc = INIT_SCALAR_LOC
  endif
;
  default, iKR_Frad, 0
  if (iKR_Frad gt 0) then begin
    varcontent[iKR_Frad].variable   = 'Radiative flux scaled with kappa*rho (KR_Frad)'
    varcontent[iKR_Frad].idlvar     = 'KR_Frad'
    varcontent[iKR_Frad].idlinit    = INIT_3VECTOR
    varcontent[iKR_Frad].idlvarloc  = 'KR_Frad_loc'
    varcontent[iKR_Frad].idlinitloc = INIT_3VECTOR_LOC
    varcontent[iKR_Frad].skip       = 2
  endif
;
  default, iyH, 0
  if (iyH gt 0) then begin
    varcontent[iyH].variable   = 'Hydrogen ionization fraction (yH)'
    varcontent[iyH].idlvar     = 'yH'
    varcontent[iyH].idlinit    = INIT_SCALAR
    varcontent[iyH].idlvarloc  = 'yH_loc'
    varcontent[iyH].idlinitloc = INIT_SCALAR_LOC
  endif
;
  default, ishock, 0
  if (ishock gt 0) then begin
    varcontent[ishock].variable   = 'Shock Profile (shock)'
    varcontent[ishock].idlvar     = 'shock'
    varcontent[ishock].idlinit    = INIT_SCALAR
    varcontent[ishock].idlvarloc  = 'shock_loc'
    varcontent[ishock].idlinitloc = INIT_SCALAR_LOC
  endif
;
  default, ishock_perp, 0
  if (ishock_perp gt 0) then begin
    varcontent[ishock_perp].variable   = 'B-Perp Shock Profile (shock_perp)'
    varcontent[ishock_perp].idlvar     = 'shock_perp'
    varcontent[ishock_perp].idlinit    = INIT_SCALAR
    varcontent[ishock_perp].idlvarloc  = 'shock_perp_loc'
    varcontent[ishock_perp].idlinitloc = INIT_SCALAR_LOC
  endif
;
  default, icooling, 0
  if (icooling gt 0) then begin
    varcontent[icooling].variable   = 'Cooling Term (cooling)'
    varcontent[icooling].idlvar     = 'cooling'
    varcontent[icooling].idlinit    = INIT_SCALAR
    varcontent[icooling].idlvarloc  = 'cooling_loc'
    varcontent[icooling].idlinitloc = INIT_SCALAR_LOC
  endif
;
  default, icooling2, 0
  if (icooling2 gt 0) then begin
    varcontent[icooling2].variable   = 'Applied Cooling Term (cooling)'
    varcontent[icooling2].idlvar     = 'cooling2'
    varcontent[icooling2].idlinit    = INIT_SCALAR
    varcontent[icooling2].idlvarloc  = 'cooling2_loc'
    varcontent[icooling2].idlinitloc = INIT_SCALAR_LOC
  endif
;
  default, idetonate, 0
  if (idetonate gt 0) then begin
    varcontent[idetonate].variable   = 'Detonation Energy'
    varcontent[idetonate].idlvar     = 'det'
    varcontent[idetonate].idlinit    = INIT_SCALAR
    varcontent[idetonate].idlvarloc  = 'det_loc'
    varcontent[idetonate].idlinitloc = INIT_SCALAR_LOC
  endif
;
  default, inp, 0
  if (inp gt 0) then begin
    varcontent[inp].variable   = 'Particle number (np)'
    varcontent[inp].idlvar     = 'np'
    varcontent[inp].idlinit    = INIT_SCALAR
    varcontent[inp].idlvarloc  = 'np_loc'
    varcontent[inp].idlinitloc = INIT_SCALAR_LOC
  endif
;
  default, irhop, 0
  if (irhop gt 0) then begin
    varcontent[irhop].variable   = 'Particle mass density (rhop)'
    varcontent[irhop].idlvar     = 'rhop'
    varcontent[irhop].idlinit    = INIT_SCALAR
    varcontent[irhop].idlvarloc  = 'rhop_loc'
    varcontent[irhop].idlinitloc = INIT_SCALAR_LOC
  endif
;
  default, iupx, 0
  if (iupx gt 0) then begin
    varcontent[iupx].variable   = 'Particle velocity field (uup)'
    varcontent[iupx].idlvar     = 'uup'
    varcontent[iupx].idlinit    = INIT_3VECTOR
    varcontent[iupx].idlvarloc  = 'uup_loc'
    varcontent[iupx].idlinitloc = INIT_3VECTOR_LOC
    varcontent[iupx].skip       = 2
  endif
;
  default, ifgx, 0
  if (ifgx gt 0) then begin
    varcontent[ifgx].variable   = 'Gas terms for stiff drag forces (ffg)'
    varcontent[ifgx].idlvar     = 'ffg'
    varcontent[ifgx].idlinit    = INIT_3VECTOR
    varcontent[ifgx].idlvarloc  = 'ffg_loc'
    varcontent[ifgx].idlinitloc = INIT_3VECTOR_LOC
    varcontent[ifgx].skip       = 2
  endif
;
  default, ipviscx, 0
  if (ipviscx gt 0) then begin
    varcontent[ipviscx].variable   = 'Particle viscosity field (pvisc)'
    varcontent[ipviscx].idlvar     = 'pvisc'
    varcontent[ipviscx].idlinit    = INIT_3VECTOR
    varcontent[ipviscx].idlvarloc  = 'pvisc_loc'
    varcontent[ipviscx].idlinitloc = INIT_3VECTOR_LOC
    varcontent[ipviscx].skip       = 2
  endif
;
  default, ipotself, 0
  if (ipotself gt 0) then begin
    varcontent[ipotself].variable   = 'Self gravity potential'
    varcontent[ipotself].idlvar     = 'potself'
    varcontent[ipotself].idlinit    = INIT_SCALAR
    varcontent[ipotself].idlvarloc  = 'potself_loc'
    varcontent[ipotself].idlinitloc = INIT_SCALAR_LOC
  endif
;
  default, igpotselfx, 0
  if (igpotselfx gt 0) then begin
    varcontent[igpotselfx].variable   = 'Gradient of self gravity potential'
    varcontent[igpotselfx].idlvar     = 'gpotself'
    varcontent[igpotselfx].idlinit    = INIT_3VECTOR
    varcontent[igpotselfx].idlvarloc  = 'gpotself_loc'
    varcontent[igpotselfx].idlinitloc = INIT_3VECTOR_LOC
    varcontent[igpotselfx].skip       = 2
  endif
;
  default, ivisc_heat, 0
  if (ivisc_heat gt 0) then begin
  varcontent[ivisc_heat].variable  = 'viscous dissipation'
  varcontent[ivisc_heat].idlvar    = 'visc_heat'
  varcontent[ivisc_heat].idlinit   = INIT_SCALAR
  varcontent[ivisc_heat].idlvarloc = 'visc_heat_loc'
  endif
;
  default, ihypvis, 0
  if (ihypvis gt 0) then begin
    varcontent[ihypvis].variable   = 'Hyperviscosity (hyv)'
    varcontent[ihypvis].idlvar     = 'hyv'
    varcontent[ihypvis].idlinit    = INIT_3VECTOR
    varcontent[ihypvis].idlvarloc  = 'hyv_loc'
    varcontent[ihypvis].idlinitloc = INIT_3VECTOR_LOC
    varcontent[ihypvis].skip       = 2
  endif
;
  default, ihypres, 0
  if (ihypres gt 0) then begin
    varcontent[ihypres].variable   = 'Hyperresistivity (hyr)'
    varcontent[ihypres].idlvar     = 'hyr'
    varcontent[ihypres].idlinit    = INIT_3VECTOR
    varcontent[ihypres].idlvarloc  = 'hyr_loc'
    varcontent[ihypres].idlinitloc = INIT_3VECTOR_LOC
    varcontent[ihypres].skip       = 2
  endif
;
  default, ippaux, 0
  if (ippaux gt 0) then begin
    varcontent[ippaux].variable   = 'Auxiliary pressure (ppaux)'
    varcontent[ippaux].idlvar     = 'ppaux'
    varcontent[ippaux].idlinit    = INIT_SCALAR
    varcontent[ippaux].idlvarloc  = 'ppaux_loc'
    varcontent[ippaux].idlinitloc = INIT_SCALAR_LOC
  endif
;
  default, ispecaux, 0
  if (ispecaux gt 0) then begin
    varcontent[ispecaux].variable   = 'Special aux'
    varcontent[ispecaux].idlvar     = 'specaux'
    varcontent[ispecaux].idlinit    = INIT_SCALAR
    varcontent[ispecaux].idlvarloc  = 'specaux_loc'
    varcontent[ispecaux].idlinitloc = INIT_SCALAR_LOC
  endif
endif
;
;  Check if there is other var data written by the special module. 
;
file_special=datadir+'/index_special.pro'
exist_specialvar=file_test(file_special)
if (exist_specialvar eq 1) then begin
  openr, 1, file_special
  line=''
  while (not eof(1)) do begin
    readf, 1, line
    str_tmp=strsplit(line," ",/extract)
    str=str_tmp[0] & istr=fix(str_tmp[1])
    if (istr gt 0) then begin
      varcontent[istr].variable   = 'Special ('+strtrim(str,2)+')'
      varcontent[istr].idlvar     = strtrim(str,2)
      varcontent[istr].idlinit    = INIT_SCALAR
      varcontent[istr].idlvarloc  = strtrim(str,2)+'_loc'
      varcontent[istr].idlinitloc = INIT_SCALAR_LOC
    endif
  endwhile
  close, 1
endif
;
;  Remove empty entry at position 0:
;
varcontent=varcontent[1:*]
;
;  Turn vector quantities into scalars if requested.
;
if (keyword_set(scalar)) then begin
  for i=0L,totalvars-1L do begin
    if (varcontent[i].skip eq 2) then begin
      varcontent[i+2].variable  = varcontent[i].variable + ' 3rd component' 
      varcontent[i+1].variable  = varcontent[i].variable + ' 2nd component' 
      varcontent[i  ].variable  = varcontent[i].variable + ' 1st component' 
      varcontent[i+2].idlvar    = varcontent[i].idlvar + '3' 
      varcontent[i+1].idlvar    = varcontent[i].idlvar + '2' 
      varcontent[i  ].idlvar    = varcontent[i].idlvar + '1' 
      varcontent[i+2].idlvarloc = varcontent[i].idlvarloc + '3' 
      varcontent[i+1].idlvarloc = varcontent[i].idlvarloc + '2' 
      varcontent[i  ].idlvarloc = varcontent[i].idlvarloc + '1' 
      varcontent[i:i+2].idlinit    = INIT_SCALAR
      varcontent[i:i+2].idlinitloc = INIT_SCALAR_LOC
      varcontent[i:i+2].skip       = 0
      i=i+2
    endif   
  endfor
endif
;
return, varcontent
;
end
