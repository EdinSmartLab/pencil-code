; $Id$

;;;;;;;;;;;;;;;
;;;  r.pro  ;;;
;;;;;;;;;;;;;;;

;;; Read the data produced on one processor
;;; You should have run `start.pro' once before.
;;; $Id$

;
;  read data
;
if ((n_elements(started) le 0) or (n_elements(read_all) gt 0)) then begin
  message, "You need to run start.pro first: use `.rnew start'"
endif
undefine, read_all
;
if (n_elements(datadir) eq 0) then datadir=pc_get_datadir()
default, varfile, 'var.dat'
;
;  Read data
;
varcontent=pc_varcontent(QUIET=quiet)
totalvars=(size(varcontent))[1]
; Prepare for read
res=''
content=''
for iv=0L,totalvars-1L do begin
  res     = res + ',' + varcontent[iv].idlvar
  content = content + ', ' + varcontent[iv].variable
  ; Initialise variable
  if (varcontent[iv].variable eq 'UNKNOWN') then $
           message, 'Unknown variable at position ' + str(iv)  $
                    + ' needs declaring in pc_varcontent.pro', /INFO   
  cmd = varcontent[iv].idlvar + '='+varcontent[iv].idlinit
  if (execute(cmd) ne 1) then $
      message, 'Error initialising ' + varcontent[iv].variable $
                                     +' - '+ varcontent[iv].idlvar, /INFO
  ; For vector quantities skip the required number of elements
  iv=iv+varcontent[iv].skip
end

content = strmid(content,2)
if (quiet le 2) then print,'File '+varfile+' contains: ', content


;
;  Read run parameters
;
pc_read_param, obj=par2, dim=dim, datadir=datadir, /param2

  if (lhydro) then begin
    nu=par2.nu
  endif
  if (ldensity) then begin
    cs0=par2.cs0
  endif
  if (lentropy) then begin
    hcond0=par2.hcond0 & hcond1=par2.hcond1 & hcond2=par2.hcond2
    luminosity=par2.luminosity & wheat=par2.wheat
    cool=par2.cool & wcool=par2.wcool
    Fbot=par2.Fbot
  endif

;
;  Read data
;
@data/variables
  ;
if (lshear) then begin
  readu,1, t, x, y, z, dx, dy, dz, deltay
end else begin
  readu,1, t, x, y, z, dx, dy, dz
end
;
xx = spread(x, [1,2], [my,mz])
yy = spread(y, [0,2], [mx,mz])
zz = spread(z, [0,1], [mx,my])
rr = sqrt(xx^2+yy^2+zz^2)
;
;  Summarise data
;
print,' t     =',t
print,'----------------------'
;
xyz = ['x', 'y', 'z']
fmt = '(A,4G15.6)'
print, '  var            minval         maxval          mean           rms'
;AB:  does not work ok for kinematic case. I suggest to use only f.
;WD: Ought to work now (the namelist lphysics need to know about the
;    relevant logicals). What is f ?
;
if (lhydro) then $
    for j=0,2 do $
      print, FORMAT=fmt, 'uu_'+xyz[j]+'   =', $
      minmax(uu(*,*,*,j)), mean(uu(*,*,*,j),/DOUBLE), rms(uu(*,*,*,j),/DOUBLE)
if (ldensity) then $
    print, FORMAT=fmt, 'lnrho  =', $
    minmax(lnrho), mean(lnrho,/DOUBLE), rms(lnrho,/DOUBLE)
if (lentropy) then $
    print, FORMAT=fmt, 'ss     =', $
      minmax(ss), mean(ss,/DOUBLE), rms(ss,/DOUBLE)
if (lpscalar) then $
    print, FORMAT=fmt, 'lncc   =', $
      minmax(lncc), mean(lncc,/DOUBLE), rms(lncc,/DOUBLE)
if (lionization) then begin
    print, FORMAT=fmt, 'yH     =', $
      minmax(yH(*,*,*)),mean(yH(*,*,*),/DOUBLE),rms(yH(*,*,*),/DOUBLE)
    print, FORMAT=fmt, 'TT     =', $
      minmax(TT(*,*,*)),mean(TT(*,*,*),/DOUBLE),rms(TT(*,*,*),/DOUBLE)
end
if (lradiation_fld) then begin
    for j=0,2 do begin
      print, FORMAT=fmt, 'ff_'+xyz[j]+'   =', $
      minmax(ff(*,*,*,j)), mean(ff(*,*,*,j),/DOUBLE), rms(ff(*,*,*,j),/DOUBLE)
    end
    print, FORMAT=fmt, 'ee     =', $
    minmax(ee), mean(ee,/DOUBLE), rms(ee,/DOUBLE)
end
if (lradiation AND NOT lradiation_fld) then begin
    print, FORMAT=fmt, 'Qrad   =', $
      minmax(Qrad(*,*,*)),mean(Qrad(*,*,*),/DOUBLE),rms(Qrad(*,*,*),/DOUBLE)
end
if (lmagnetic) then begin
    for j=0,2 do $
      print, FORMAT=fmt, 'aa_'+xyz[j]+'   =', $
      minmax(aa(*,*,*,j)), mean(aa(*,*,*,j),/DOUBLE), rms(aa(*,*,*,j),/DOUBLE)
    if (cpar gt 0) then begin
      eta=par2.eta
    end
end
;
if (par.lvisc_shock ne 0) then begin
    nu_shock=fltarr(mx,my,mz)*one
    readu,1,nu_shock
endif
;
END

; End of file
