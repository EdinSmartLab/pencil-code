;
; $Id$
;
;   Read y-averages from file.
;
;   Default is to only plot the data (with tvscl), not to save it in memory.
;   The user can get the data returned in an object by specifying nit, the
;   number of snapshots to save.
;
;  We start with a script for plotting data plane - the main program follows
;  below.
;
;;; 18-Sep-2015/PABourdin:
;;; FIXME: Please remove the replicated code and put into 'pc_read_2d_aver'.
;
pro plot_plane, array_plot=array_plot, nxg=nxg, nzg=nzg, $
    min=min, max=max, zoom=zoom, xax=xax, zax=zax, $
    xtitle=xtitle, ztitle=ztitle, title=title, $
    subbox=subbox, subcen=subcen, $
    subpos=subpos, rsubbox=rsubbox, subcolor=subcolor, tsubbox=tsubbox,$
    submin=submin, submax=submax, sublog=sublog, $
    noaxes=noaxes, thick=thick, charsize=charsize, $
    loge=loge, log10=log10, $
    t_title=t_title, t_scale=t_scale, t_zero=t_zero, interp=interp, $
    ceiling=ceiling, position=position, fillwindow=fillwindow, $
    tformat=tformat, xxstalk=xxstalk, zzstalk=zzstalk, $
    tmin=tmin, ps=ps, png=png, imgdir=imgdir, noerase=noerase, $
    xsize=xsize, zsize=zsize, lwindow_opened=lwindow_opened, $
    colorbar=colorbar, bartitle=bartitle, quiet=quiet, $
    x0=x0, x1=x1, z0=z0, z1=z1, Lx=Lx, Lz=Lz, time=time, itimg=itimg
;
;  Define line and character thickness (will revert to old settings later).
;
oldthick=thick
!p.charthick=thick
!p.thick=thick
!x.thick=thick
!y.thick=thick
;
if (fillwindow) then position=[0.1,0.1,0.9,0.9]
;
;  Possible to zoom.
;
if (zoom ne 1.0) then begin
  array_plot=congrid(array_plot,zoom*nxg,zoom*nzg,interp=interp,/center)
  xax=congrid(xax,zoom*nxg,interp=interp,/center)
  zax=congrid(zax,zoom*nzg,interp=interp,/center)
endif
;
;  Take logarithm.
;
if (loge)  then array_plot=alog(array_plot)
if (log10) then array_plot=alog10(array_plot)
;
;  Set the maximum value of the array.
;
if (ceiling) then begin
  ii=where(array_plot gt ceiling)
  if (max(ii) ne -1) then array_plot[ii]=ceiling
endif
;  Plot to post script (eps).
if (ps) then begin
  set_plot, 'ps'
  imgname='img_'+strtrim(string(itimg,'(i20.4)'),2)+'.eps'
  device, filename=imgdir+'/'+imgname, xsize=xsize, ysize=zsize, $
      color=1, /encapsulated, bits_per_pixel=8
  ps_fonts
  !p.font=0
endif else if (png) then begin
;  Plot to png.
endif else begin
;  Plot to X.
  if (not noerase) then begin
    window, retain=2, xsize=zoom*nxg, ysize=zoom*nzg
  endif else begin
    if (not lwindow_opened) then $
        window, retain=2, xsize=zoom*nxg, ysize=zoom*nzg
    lwindow_opened=1
  endelse
endelse
sym=texsyms()
;  Put current time in title if requested.
if (t_title) then $
    title='t='+strtrim(string(time/t_scale-t_zero,format=tformat),2)
;  tvscl-type plot with axes.
plotimage, array_plot, $
    range=[min, max], imgxrange=[x0,x1], imgyrange=[z0,z1], $
    xtitle=xtitle, ytitle=ztitle, title=title, $
    position=position, noerase=noerase, noaxes=noaxes, $
    interp=interp, charsize=charsize, thick=thick
;
;  Enlargement of ``densest'' point.
;
if ( subbox and (time ge tsubbox) ) then begin
  if (subcen[0] eq -1) then begin
    isub=where(array_plot eq max(array_plot))
    isub=array_indices(array_plot,isub)
  endif else begin
    isub=subcen
  endelse
;  Plot box indicating enlarged region.
  oplot, [xax[isub[0]]-rsubbox,xax[isub[0]]+rsubbox, $
          xax[isub[0]]+rsubbox,xax[isub[0]]-rsubbox, $
          xax[isub[0]]-rsubbox], $
         [zax[isub[1]]-rsubbox,zax[isub[1]]-rsubbox, $
          zax[isub[1]]+rsubbox,zax[isub[1]]+rsubbox, $
          zax[isub[1]]-rsubbox], color=subcolor, thick=thick
;  Box crosses lower boundary.
  if (zax[isub[1]]-rsubbox lt z0) then begin
    oplot, [xax[isub[0]]-rsubbox,xax[isub[0]]+rsubbox, $
            xax[isub[0]]+rsubbox,xax[isub[0]]-rsubbox, $
            xax[isub[0]]-rsubbox], $
           [zax[isub[1]]+Lz-rsubbox,zax[isub[1]]+Lz-rsubbox, $
            zax[isub[1]]+Lz+rsubbox,zax[isub[1]]+Lz+rsubbox, $
            zax[isub[1]]+Lz-rsubbox], color=subcolor, thick=thick
  endif
;  Box crosses upper boundary.
  if (zax[isub[1]]+rsubbox gt z1) then begin
    oplot, [xax[isub[0]]-rsubbox,xax[isub[0]]+rsubbox, $
            xax[isub[0]]+rsubbox,xax[isub[0]]-rsubbox, $
            xax[isub[0]]-rsubbox], $
           [zax[isub[1]]-Lz-rsubbox,zax[isub[1]]-Lz-rsubbox, $
            zax[isub[1]]-Lz+rsubbox,zax[isub[1]]-Lz+rsubbox, $
            zax[isub[1]]-Lz-rsubbox], thick=thick
  endif
;  Subplot and box.
  if ( (xax[isub[0]]-rsubbox lt x0) or $
       (xax[isub[0]]+rsubbox gt x1) ) then begin
    array_plot=shift(array_plot,[nxg/2,0])
    if (xax[isub[0]]-rsubbox lt x0) then isub[0]=isub[0]+nxg/2
    if (xax[isub[0]]+rsubbox gt x1) then isub[0]=isub[0]-nxg/2
  endif
  if ( (zax[isub[1]]-rsubbox lt z0) or $
       (zax[isub[1]]+rsubbox gt z1) ) then begin
    array_plot=shift(array_plot,[0,nzg/2])
    if (zax[isub[1]]-rsubbox lt z0) then isub[1]=isub[1]+nzg/2
    if (zax[isub[1]]+rsubbox gt z1) then isub[1]=isub[1]-nzg/2
  endif
  if (sublog) then array_plot=alog10(array_plot)
  plotimage, array_plot, $
      xrange=xax[isub[0]]+[-rsubbox,rsubbox], $
      yrange=zax[isub[1]]+[-rsubbox,rsubbox], $
      range=[submin,submax], imgxrange=[x0,x1], imgyrange=[z0,z1], $
      position=subpos, /noerase, /noaxes, $
      interp=interp, charsize=charsize, thick=thick
  plots, [subpos[0],subpos[2],subpos[2],subpos[0],subpos[0]], $
         [subpos[1],subpos[1],subpos[3],subpos[3],subpos[1]], /normal, $
         thick=thick, color=subcolor
endif
;  Overplot stalked particles.
if (n_elements(xxstalk) ne 0) then oplot, [xxstalk], [zzstalk], $
        ps=1, color=255, thick=2.0
;  Colorbar indicating range.
if (colorbar) then begin
  colorbar_co, range=[min,max], pos=[0.89,0.15,0.91,0.35], divisions=1, $
      title=bartitle, /normal, /vertical
endif
;  For png output, take image from z-buffer.
if (png) then begin
  image = tvrd()
  tvlct, red, green, blue, /get
  imgname='img_'+strtrim(string(itimg,'(i20.4)'),2)+'.png'
  write_png, imgdir+'/'+imgname, image, red, green, blue
endif
;  Close postscript device.
if (ps) then device, /close
itimg=itimg+1
if (ps or png and not quiet) then print, 'Written image '+imgdir+'/'+imgname
;
;  Revert to old settings for line and character thickness.
;
  thick=oldthick
  !p.charthick=thick
  !p.thick=thick
  !x.thick=thick
  !y.thick=thick
;
end
;
;  Main program.
;
pro pc_read_yaver, object=object, varfile=varfile, datadir=datadir, $
    nit=nit, iplot=iplot, min=min, max=max, zoom=zoom, xax=xax, zax=zax, $
    ipxread=ipxread, ipzread=ipzread, $
    xtitle=xtitle, ztitle=ztitle, title=title, subbox=subbox, subcen=subcen, $
    subpos=subpos, rsubbox=rsubbox, subcolor=subcolor, tsubbox=tsubbox,$
    submin=submin, submax=submax, sublog=sublog, $
    noaxes=noaxes, thick=thick, charsize=charsize, loge=loge, log10=log10, $
    t_title=t_title, t_scale=t_scale, t_zero=t_zero, interp=interp, $
    ceiling=ceiling, position=position, fillwindow=fillwindow, $
    tformat=tformat, stalk=stalk, nstalk=nstalk, swap_endian=swap_endian, $
    tmin=tmin, njump=njump, ps=ps, png=png, imgdir=imgdir, noerase=noerase, $
    xsize=xsize, zsize=zsize, it1=it1, variables=variables, $
    colorbar=colorbar, bartitle=bartitle, xshift=xshift, timefix=timefix, $
    readpar=readpar, readgrid=readgrid, debug=debug, quiet=quiet
COMPILE_OPT IDL2,HIDDEN
COMMON pc_precision, zero, one
forward_function plot_plane
;
;  Default values.
;
if (not keyword_set(datadir)) then datadir=pc_get_datadir()
default, varfile, 'yaverages.dat'
default, nit, 0
default, ipxread, -1
default, ipzread, -1
default, iplot, -1
default, zoom, 1
default, min, 0.0
default, max, 1.0
default, tmin, 0.0
default, njump, 1
default, ps, 0
default, png, 0
default, noerase, 0
default, imgdir, '.'
default, xsize, 10.0
default, zsize, 10.0
default, title, ''
default, t_title, 0
default, t_scale, 1.0
default, t_zero, 0.0
default, stalk, 0
default, interp, 0
default, ceiling, 0.0
default, subbox, 0
default, subcen, -1
default, subpos, [0.7,0.7,0.9,0.9]
default, submin, min
default, submax, max
default, sublog, 0
default, rsubbox, 5.0
default, subcolor, 255
default, tsubbox, 0.0
default, thick, 1.0
default, charsize, 1.0
default, loge, 0
default, log10, 0
default, fillwindow, 0
default, tformat, '(f5.1)'
default, swap_endian, 0
default, it1, 10
default, variables, ''
default, colorbar, 0
default, bartitle, ''
default, xshift, 0
default, timefix, 0
default, readpar, 0
default, readgrid, 0
default, debug, 0
default, quiet, 0
default, in_file, 'yaver.in'
;
;  Read additional information.
;
pc_read_dim, obj=dim, datadir=datadir, /quiet
pc_read_dim, obj=locdim, datadir=datadir+'/proc0', /quiet
if (stalk) then begin
  pc_read_pstalk, obj=pst, datadir=datadir, /quiet
  default, nstalk, n_elements(pst.ipar)
endif
pc_set_precision, dim=dim, /quiet
;
;  Need to know box size for proper axes and for shifting the shearing
;  frame.
;
if (readpar) then pc_read_param, obj=par, datadir=datadir, /quiet
if (readgrid) then begin
  pc_read_grid, obj=grid, /trim, datadir=datadir, /quiet
  xax=grid.x
  zax=grid.z
endif
if (xshift ne 0) then begin
  if (not readpar) then pc_read_param, obj=par, datadir=datadir, /quiet
  if (not readgrid) then begin
    pc_read_grid, obj=grid, /trim, datadir=datadir, /quiet
    xax=grid.x
    yax=grid.y
  endif
endif
;
;;; FIXME: Does this also apply to y-averages? If not, delete the following line of code. [PABourdin]
;  Some z-averages are erroneously calculated together with time series
;  diagnostics. The proper time is thus found in time_series.dat.
;
if (timefix) then pc_read_ts, obj=ts, datadir=datadir, /quiet
;
;  Derived dimensions.
;
nx=locdim.nx
nz=locdim.nz
nxgrid=dim.nx
nzgrid=dim.nz
nprocx=dim.nprocx
nprocy=dim.nprocy
nprocz=dim.nprocz
;
;  Read variables from '*aver.in' file
;
run_dir = stregex ('./'+datadir, '^(.*)data\/', /extract)
variables_all = strarr(file_lines(run_dir+in_file))
openr, lun, run_dir+in_file, /get_lun
readf, lun, variables_all
close, lun
free_lun, lun
;
; Remove commented and empty elements from variables_all
;
variables_all = strtrim (variables_all, 2)
inds = where (stregex (variables_all, '^[a-zA-Z]', /boolean), nvar_all)
if (nvar_all le 0) then message, "ERROR: there are no variables found."
variables_all = variables_all[inds]
;
if (variables[0] eq '') then begin
  variables = variables_all
  nvar = nvar_all
  ivarpos = indgen(nvar)
endif else begin
  nvar=n_elements(variables)
  ivarpos=intarr(nvar)
;
;  Find the position of the requested variables in the list of all
;  variables.
;
  for ivar=0,nvar-1 do begin
    ivarpos_est=where(variables[ivar] eq variables_all)
    if (ivarpos_est[0] eq -1) then $
        message, 'ERROR: can not find the variable '''+variables[ivar]+'''' + $
                 ' in '+arraytostring(variables_all,/noleader)
    ivarpos[ivar]=ivarpos_est[0]
  endfor
endelse
;  Die if attempt to plot a variable that does not exist.
if (iplot gt nvar-1) then message, 'iplot must not be greater than nvar-1!'
;
;  Define filenames to read data from - either from a single processor or
;  from all of them.
;
if ( (ipxread eq -1) and (ipzread eq -1) ) then begin
  ipxarray = indgen(nprocx*nprocz) mod nprocx
  ipzarray = (indgen(nprocx*nprocz)/nprocx) mod nprocz
  filename = datadir+'/proc'+strtrim(ipxarray+ipzarray*nprocx*nprocy,2)+'/'+varfile
  nxg = nxgrid
  nzg = nzgrid
endif else begin
  if (ipxread lt 0 or ipxread gt nprocx-1) then begin
    print, 'ERROR: ipx is not within the proper bounds'
    print, '       ipx, nprocx', ipxread, nprocx
    stop
  endif
  if (ipzread lt 0 or ipzread gt nprocz-1) then begin
    print, 'ERROR: ipz is not within the proper bounds'
    print, '       ipz, nprocz', ipzread, nprocz
    stop
  endif
  filename = datadir+'/proc'+strtrim(ipxread+ipzread*nprocx*nprocy,2)+'/'+varfile
  ipxarray = intarr(1)
  ipzarray = intarr(1)
  nxg = nx
  nzg = nz
endelse
;
;  Define arrays to put data in. The user may supply the length of
;  the time dimension (nit). Otherwise nit will be read from the
;  file data/t2davg.dat.
;
if (not keyword_set(nit)) then begin
;
;  Test if the file that stores the time and number of 2d-averages, t2davg,
;  exists.
;
  file_t2davg=datadir+'/t2davg.dat'
  if (not file_test(file_t2davg)) then begin
    print, 'ERROR: cannot find file '+ file_t2davg
    stop
  endif
  openr, lun, file_t2davg, /get_lun
  dummy_real=0.0d0
  dummy_int=0L
  readf, lun, dummy_real, dummy_int
  close, lun
  free_lun, lun
  nit=dummy_int-1
endif
;
if (nit gt 0) then begin
;
  if (not quiet) then begin
    if (njump eq 1) then begin
      print, 'Returning averages at '+strtrim(nit,2)+' times'
    endif else begin
      print, 'Returning averages at '+strtrim(nit,2)+' times'+ $
          ' at an interval of '+strtrim(njump,2)+' steps'
    endelse
  endif
;
  tt=fltarr(ceil(nit/double(njump)))*one
  for i=0,nvar-1 do begin
    cmd=variables[i]+'=fltarr(nxg,nzg,ceil(nit/double(njump)))*one'
    if (execute(cmd,0) ne 1) then message, 'Error defining data arrays'
  endfor
;
endif
;
;  Define axes (default to indices if no axes are supplied).
;
if (n_elements(xax) eq 0) then xax=findgen(nxg)
if (n_elements(zax) eq 0) then zax=findgen(nzg)
if (n_elements(par) ne 0) then begin
  x0=par.xyz0[0]
  x1=par.xyz1[0]
  z0=par.xyz0[2]
  z1=par.xyz1[2]
  Lx=par.Lxyz[0]
  Lz=par.Lxyz[2]
endif else begin
  x0=xax[0]
  x1=xax[nxg-1]
  z0=zax[0]
  z1=zax[nzg-1]
  Lx=xax[nxg-1]-xax[0]
  Lz=zax[nzg-1]-zax[0]
endelse
;
;  Prepare for read.
;
if (not quiet) then print, 'Preparing to read y-averages ', $
    arraytostring(variables,quote="'",/noleader)
;
num_files = n_elements(filename)
for ip=0, num_files-1 do begin
  if (not file_test(filename[ip])) then begin
    print, 'ERROR: cannot find file '+ filename[ip]
    stop
  endif
endfor
;
;  Method 1: Read in full data processor by processor. Does not allow plotting.
;
if (iplot eq -1) then begin
  array_local=fltarr(nx,nz,nvar_all)*one
  array_global=fltarr(nxg,nzg,ceil(nit/double(njump)),nvar_all)*one
  t=zero
;
  for ip=0, num_files-1 do begin
    if (not quiet) then print, 'Loading chunk ', strtrim(ip+1,2), ' of ', $
        strtrim(num_files,2), ' (', filename[ip], ')'
    ipx=ipxarray[ip]
    ipz=ipzarray[ip]
    openr, lun, filename[ip], /f77, swap_endian=swap_endian, /get_lun
    it=0
    while ( not eof(lun) and ((nit eq 0) or (it lt nit)) ) do begin
;
;  Read time.
;
      readu, lun, t
      if (it eq 0) then t0=t
;
;  Read full data, close and free lun after endwhile.
;
      if ( (t ge tmin) and (it mod njump eq 0) ) then begin
        readu, lun, array_local
        array_global[ipx*nx:(ipx+1)*nx-1,ipz*nz:(ipz+1)*nz-1,it/njump,*]= $
            array_local
        tt[it/njump]=t
      endif else begin
        dummy=zero
        readu, lun, dummy
      endelse
      it=it+1
    endwhile
    close, lun
    free_lun, lun
;
  endfor
;
;  Diagnostics.
;
  if (not quiet) then begin
    for it=0,ceil(nit/double(njump))-1 do begin
      if (it mod it1 eq 0) then begin
        if (it eq 0 ) then $
          print, '  ------ it -------- t ---------- var ----- min(var) ------- max(var) ------'
        for ivar=0,nvar-1 do begin
            print, it, tt[it], variables[ivar], $
                min(array_global[*,*,it,ivarpos[ivar]]), $
                max(array_global[*,*,it,ivarpos[ivar]]), $
                format='(i11,e17.7,A12,2e17.7)'
        endfor
      endif
    endfor
  endif
;
;  Possible to shift data in the x-direction.
;
  if (xshift ne 0) then begin
    for it=0, nit/njump-1 do begin
      pc_read_aver_shift_plane, nvar_all, array_global[*,*,it,*], xshift, par, timefix, ts, t, t0
    endfor
  endif
;
;  Split read data into named arrays.
;
  for ivar=0,nvar-1 do begin
    cmd=variables[ivar]+'=array_global[*,*,*,ivarpos[ivar]]'
    if (execute(cmd,0) ne 1) then message, 'Error putting data in array'
  endfor
;
endif else begin
;
;  Method 2: Read in data slice by slice and plot the results.
;
  if (png) then begin
    set_plot, 'z'
    device, set_resolution=[zoom*nx,zoom*nzg]
    print, 'Deleting old png files in the directory ', imgdir
    spawn, '\rm -f '+imgdir+'/img_*.png'
  endif
;
;  Open all ipz=0 processor directories.
;
  luns = intarr(num_files)
  for ip=0, num_files-1 do begin
    openr, lun, filename[ip], /f77, swap_endian=swap_endian, /get_lun
    luns[ip] = lun
  endfor
;
;  Variables to put single time snapshot in.
;
  array=fltarr(nxg,nzg,nvar_all)*one
  array_local=fltarr(nx,nz,nvar_all)*one
  tt_local=fltarr(num_files)*one
;
;  Read y-averages and put in arrays if requested.
;
  it=0
  itimg=0
  lwindow_opened=0
  while ( not eof(luns[0]) and ((nit eq 0) or (it lt nit)) ) do begin
;
;  Read time.
;
    for ip=0, num_files-1 do begin
      tt_tmp=zero
      readu, luns[ip], tt_tmp
      tt_local[ip]=tt_tmp
      if (ip ge 1) then begin
        if (max(tt_local[ip]-tt_local[0:ip-1])) then begin
          print, 'Inconsistent times between processors!'
          print, tt_local
          stop
        endif
      endif
    endfor
    t=tt_local[0]
    if (it eq 0) then t0=t
;
;  Read data one slice at a time.
;
    if ( (t ge tmin) and (it mod njump eq 0) ) then begin
      for ip=0, num_files-1 do begin
        readu, luns[ip], array_local
        ipx=ipxarray[ip]
        ipz=ipzarray[ip]
        array[ipx*nx:(ipx+1)*nx-1,ipz*nz:(ipz+1)*nz-1,*]=array_local
      endfor
;
;  Shift plane in the radial direction.
;
      if (xshift ne 0) then $
          pc_read_aver_shift_plane, nvar_all, array, xshift, par, timefix, ts, t
;
;  Interpolate position of stalked particles to time of snapshot.
;
      if (stalk) then begin
        ist=where( abs(pst.t-t) eq min(abs(pst.t-t)))
        ist=ist[0]
        if (max(tag_names(pst) eq 'APS') eq 1) then begin
          if (n_elements(pst.ipar) eq 1) then begin
            if (pst.aps[ist] eq 0.0) then nstalk=0 else nstalk=-1
          endif else begin
            ipar=where(pst.aps[*,ist] ne 0.0)
            if (ipar[0] eq -1) then nstalk=0 else nstalk=n_elements(ipar)
          endelse
        endif else begin
          ipar=indgen(nstalk)
        endelse
        if (nstalk eq -1) then begin
          xxstalk=pst.xp[ist]
          zzstalk=pst.zp[ist]
        endif else if (nstalk ne 0) then begin
          xxstalk=pst.xp[ipar,ist]
          zzstalk=pst.zp[ipar,ist]
        endif
      endif
;
;  Plot requested variable (plotting is turned off by default).
;
      plot_plane, array_plot=array[*,*,ivarpos[iplot]], nxg=nxg, nzg=nzg, $
          min=min, max=max, zoom=zoom, xax=xax, zax=zax, $
          xtitle=xtitle, ztitle=ztitle, title=title, $
          subbox=subbox, subcen=subcen, $
          subpos=subpos, rsubbox=rsubbox, subcolor=subcolor, tsubbox=tsubbox,$
          submin=submin, submax=submax, sublog=sublog, $
          noaxes=noaxes, thick=thick, charsize=charsize, $
          loge=loge, log10=log10, $
          t_title=t_title, t_scale=t_scale, t_zero=t_zero, interp=interp, $
          ceiling=ceiling, position=position, fillwindow=fillwindow, $
          tformat=tformat, xxstalk=xxstalk, zzstalk=zzstalk, $
          tmin=tmin, ps=ps, png=png, imgdir=imgdir, noerase=noerase, $
          xsize=xsize, zsize=zsize, lwindow_opened=lwindow_opened, $
          colorbar=colorbar, bartitle=bartitle, quiet=quiet, $
          x0=x0, x1=x1, z0=z0, z1=z1, Lx=Lx, Lz=Lz, time=t, itimg=itimg
;
;  Diagnostics.
;
      if ( (not quiet) and (it mod it1 eq 0) ) then begin
        if (it eq 0 ) then $
            print, '  ------ it -------- t ---------- var ----- min(var) ------- max(var) ------'
        for ivar=0,nvar-1 do begin
            print, it, t, variables[ivar], $
                min(array[*,*,ivarpos[ivar]]), max(array[*,*,ivarpos[ivar]]), $
                format='(i11,e17.7,A12,2e17.7)'
        endfor
      endif
;
;  Split read data into named arrays.
;
      if (it le nit-1) then begin
        tt[it/njump]=t
        for ivar=0,nvar-1 do begin
          cmd=variables[ivar]+'[*,*,it/njump]=array[*,*,ivarpos[ivar]]'
          if (execute(cmd,0) ne 1) then message, 'Error putting data in array'
        endfor
      endif
    endif else begin
      for ip=0, num_files-1 do begin
        dummy=zero
        readu, luns[ip], dummy
      endfor
    endelse
;
    it=it+1
;
  endwhile
;
;  Close files and free luns.
;
  for ip=0, num_files-1 do begin
    close, luns[ip]
    free_lun, luns[ip]
  endfor
endelse
;
;  Put data in structure. One must set nit>0 to specify how many lines
;  of data that should be saved.
;
if (nit ne 0) then begin
  makeobject="object = create_struct(name=objectname,['t'," + $
      arraytostring(variables,quote="'",/noleader) + "],"+"tt,"+$
      arraytostring(variables,/noleader) + ")"
;
  if (execute(makeobject) ne 1) then begin
    message, 'ERROR evaluating variables: ' + makeobject, /info
    undefine,object
  endif
endif
;
end
