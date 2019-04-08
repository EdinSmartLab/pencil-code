function hdf5_content, group, number=num

	common hdf5_file_info, file_id, file_name

	if (size (file_id, /type) eq 0) then file_id = !Values.D_NaN

	if (finite (file_id, /NaN)) then begin
		print, "ERROR: no HDF5 file is open!"
		stop
		return, !Values.D_NaN
	end

	num = h5g_get_nmembers (file_id, group)
	list = strarr (num)
	for pos = 0, num-1 do begin
		list[pos] = h5g_get_member_name (file_id, group, pos)
	end

	return, list
end
