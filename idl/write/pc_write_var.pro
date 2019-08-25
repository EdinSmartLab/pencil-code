; Writes a data snapshot in the HDF5 format

pro pc_write_var, varfile, obj, tags=tags, group=group, time=time, datadir=datadir, dim=dim, grid=grid, unit=unit, start_param=start_param, run_param=run_param, quiet=quiet

	datadir = pc_get_datadir (datadir)
	default, group, 'data'
	if (not keyword_set (unit)) then pc_units, obj=unit, datadir=datadir, dim=dim, param=start_param, quiet=quiet
	if (not keyword_set (dim)) then pc_read_dim, obj=dim, datadir=datadir, quiet=quiet
	if (not keyword_set (grid)) then pc_read_grid, obj=grid, datadir=datadir, dim=dim, param=start_param, quiet=quiet

	; case-insensitve replacements for dataset names
	replace = { lntt:'lnTT', tt:'TT' }
	search = strlowcase (tag_names (replace))
	num_replace = n_elements (search)

	is_structure = (size (obj, /type) eq 8)

	if (strmid (group, strlen (group)-1) eq '/') then group = strmid (group, 0, strlen (group)-1)
	if (strmid (varfile, strlen (varfile)-4) eq '.dat') then varfile = strmid (varfile, 0, strlen (varfile)-4)
	if (strmid (varfile, strlen (varfile)-3) ne '.h5') then varfile += '.h5'
	h5_open_file, datadir+'/allprocs/'+varfile, /write, /truncate
	if (keyword_set (group)) then h5_create_group, group

	if (is_structure) then begin
		; write from var structure (pc_read_var)
		if (size (varcontent, /type) eq 0) then begin
			varcontent = pc_varcontent (datadir=datadir, dim=dim, param=start_param, par2=run_param, quiet=quiet)
		end
		labels = strlowcase (varcontent[*].idlvar)
		labels = labels[where (labels ne 'dummy')]
	end else begin
		; write from var array (pc_read_var_raw)
		labels = strlowcase (tag_names (tags))
	end

	num_content = n_elements (labels)
	for i = 0, num_content-1 do begin
		if (is_structure) then begin
			if (labels[i] eq 'dummy') then continue
		end else begin
			if (size (tags.(i), /n_dimensions) ne 0) then continue
			if (label eq 'time') then continue
		end
		label = labels[i]
		for j = 0, num_replace-1 do begin
			if (label eq search[j]) then label = replace.(j)
		end

		if (is_structure) then begin
			pos = (where (label eq strlowcase (tag_names (obj))))[0]
			if (size (obj.(pos), /n_dimensions) eq 4) then begin
				num_dims = (size (obj.(pos), /dimensions))[3]
				components = [ 'x', 'y', 'z' ]
				for comp = 0, num_dims-1 do begin
					if (num_dims eq 3) then begin
						comp_label = strmid (label, 0, strlen (label)-1) + components[comp]
					end else begin
						comp_label = label + str (comp+1)
					end
					h5_write, group+'/'+comp_label, reform ((obj.(pos))[*,*,*,comp])
				end
			end else begin
				h5_write, group+'/'+label, obj.(pos)
			end
		end else begin
			h5_write, group+'/'+label, obj[*,*,*,tags.(i)]
		end
	end

	if (is_structure and (size (time, /type) eq 0)) then begin
		t_pos = (where ('t' eq strlowcase (tag_names (obj))))[0]
		if (t_pos ge 0) then time = double (obj.(t_pos))
	end

	if (size (time, /type) ne 0) then h5_write, 'time', time

	h5_create_group, 'grid'
	h5_write, 'grid/Lx', grid.Lx
	h5_write, 'grid/Ly', grid.Ly
	h5_write, 'grid/Lz', grid.Lz
	h5_write, 'grid/x', grid.x
	h5_write, 'grid/y', grid.y
	h5_write, 'grid/z', grid.z
	h5_write, 'grid/dx', grid.dx
	h5_write, 'grid/dy', grid.dy
	h5_write, 'grid/dz', grid.dz
	h5_write, 'grid/dx_1', grid.dx_1
	h5_write, 'grid/dy_1', grid.dy_1
	h5_write, 'grid/dz_1', grid.dz_1
	h5_write, 'grid/dx_tilde', grid.dx_tilde
	h5_write, 'grid/dy_tilde', grid.dy_tilde
	h5_write, 'grid/dz_tilde', grid.dz_tilde

	h5_create_group, 'settings'
	h5_write, 'settings/l1', dim.l1
	h5_write, 'settings/l2', dim.l2
	h5_write, 'settings/m1', dim.m1
	h5_write, 'settings/m2', dim.m2
	h5_write, 'settings/n1', dim.n1
	h5_write, 'settings/n2', dim.n2
	h5_write, 'settings/nx', dim.nxgrid
	h5_write, 'settings/ny', dim.nygrid
	h5_write, 'settings/nz', dim.nzgrid
	h5_write, 'settings/mx', dim.mxgrid
	h5_write, 'settings/my', dim.mygrid
	h5_write, 'settings/mz', dim.mzgrid
	h5_write, 'settings/nghost', dim.nghostx
	h5_write, 'settings/nprocx', dim.nprocx
	h5_write, 'settings/nprocy', dim.nprocy
	h5_write, 'settings/nprocz', dim.nprocz
	h5_write, 'settings/mvar', dim.mvar
	h5_write, 'settings/maux', dim.maux
	h5_write, 'settings/mglobal', dim.mglobal
	h5_write, 'settings/precision', dim.precision
	h5_write, 'settings/version', 0

	h5_create_group, 'unit'
	h5_write, 'unit/density', unit.density
	h5_write, 'unit/energy', unit.energy
	h5_write, 'unit/flux', unit.energy / (unit.length^2 * unit.time)
	h5_write, 'unit/length', unit.length
	h5_write, 'unit/magnetic', unit.magnetic_field
	h5_write, 'unit/mass', unit.mass
	h5_write, 'unit/system', unit.system
	h5_write, 'unit/temperature', unit.temperature
	h5_write, 'unit/time', unit.time
	h5_write, 'unit/velocity', unit.velocity

	h5_close_file
end

