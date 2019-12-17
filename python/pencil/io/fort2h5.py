# fort2h5.py
#
# Read existing Fortran unformatted simulation data and write as hdf5.
#
#
# Author: F. Gent (fred.gent.ncl@gmail.com).
#
"""
Contains the functions to read old Fortran binary simulation data and
write snapshots in hdf5 (data/allprocs/VAR*.h5 files), video slices to
data/slices/uu1_xy.h5, etc. and averages to data/averages/xy.h5, etc
"""

def var2h5(newdir, olddir, allfile_names, todatadir, fromdatadir,
           precision, lpersist, quiet, nghost, settings, param, grid,
           x, y, z, lshear, lremove_old_snapshots, indx,
           last_var=True, trimall=False, l_mpi=False, driver=None, comm=None
          ):

    """
    Copy a simulation snapshot set written in Fortran binary to hdf5.

    call signature:

    var2h5(newdir, olddir, allfile_names, todatadir, fromdatadir,
           precision, lpersist, quiet, nghost, settings, param, grid,
           x, y, z, lshear, lremove_old_snapshots, indx
          )

    Keyword arguments:

    *newdir*:
      String path to simulation destination directory.

    *olddir*:
      String path to simulation destination directory.

    *allfile_names*:
      A list of names of the snapshot files to be written, e.g. VAR0.

    *todatadir*:
      Directory to which the data is stored.

    *fromdatadir*:
      Directory from which the data is collected.

    *precision*:
      Single 'f' or double 'd' precision for new data.

    *lpersist*:
      option to include persistent variables from snapshots.

    *quiet*
      Option not to print output.

    *nghost*:
      Number of ghost zones.

    *settings*
      simulation properties.

    *param*
      simulation Param object.

    *grid*
      simulation Grid object.

    *xyz*:
      xyz arrays of the domain with ghost zones.

    *lshear*:
      Flag for the shear.

    *lremove_old_snapshots*:
      If True the old snapshots will be deleted once the new snapshot has
      been saved.

    *indx*
      List of variable indices in the f-array.

    *last_var*
      If last_var copy and remove var.dat

    """
    import os
    import numpy as np
    import h5py
    import glob
    from .. import read
    from .. import sim
    from . import write_h5_snapshot

    #move var.h5 out of the way, if it exists for reading binary
    if os.path.exists(todatadir+'/var.h5'):
        cmd='mv '+todatadir+'/var.h5 '+todatadir+'/var.bak'
        os.system(cmd)

    if l_mpi:
        rank = comm.Get_rank()
        size = comm.Get_size()
    else:
        rank = 0
        size = 1

    #proceed to copy each snapshot in varfile_names
    if l_mpi:
        file_names = np.array_split(allfile_names, size)
        if 'VARd1' in allfile_names:
            varfile_names = file_names[size-rank-1]
        else:
            varfile_names = file_names[rank]
    else:
        varfile_names = allfile_names
    if len(varfile_names) > 0:
        for file_name in varfile_names:
            #load Fortran binary snapshot
            print('rank {}:'.format(rank)+'saving '+file_name, flush=True)
            os.chdir(olddir)
            var = read.var(file_name, datadir=fromdatadir, quiet=quiet,
                           lpersist=lpersist, trimall=trimall
                          )
            try:
                var.deltay
                lshear = True
            except:
                lshear = False

            if lpersist:
                persist = {}
                for key in read.record_types.keys():
                    try:
                        persist[key] = var.__getattribute__(key)[()]
                        if (type(persist[key][0])==str):
                            persist[key][0] = \
                                           var.__getattribute__(key)[0].encode()
                    except:
                        continue
            else:
                persist = None
            #write data to h5
            os.chdir(newdir)
            write_h5_snapshot(var.f, file_name=file_name, datadir=todatadir,
                              precision=precision, nghost=nghost,
                              persist=persist,
                              settings=settings, param=param, grid=grid,
                              lghosts=True, indx=indx, t=var.t, x=x, y=y, z=z,
                              lshear=lshear, driver=driver, comm=comm)
            if lremove_old_snapshots:
                os.chdir(olddir)
                cmd = "rm -f "+os.path.join(fromdatadir, 'proc*', file_name)
                os.system(cmd)
    if last_var:
        last_var = rank==size-1
    if last_var:
        os.chdir(olddir)
        var = read.var('var.dat', datadir=fromdatadir, quiet=quiet,
                       lpersist=lpersist, trimall=trimall
                      )
        if lpersist:
            persist = {}
            for key in read.record_types.keys():
                try:
                    persist[key] = var.__getattribute__(key)[()]
                except:
                    continue
        else:
            persist = None
            #write data to h5
            os.chdir(newdir)
            write_h5_snapshot(var.f, file_name='var', datadir=todatadir,
                              precision=precision, nghost=nghost,
                              persist=persist,
                              settings=settings, param=param, grid=grid,
                              lghosts=True, indx=indx, t=var.t, x=x, y=y, z=z,
                              lshear=lshear, driver=driver, comm=comm)
        if lremove_old_snapshots:
            os.chdir(olddir)
            cmd = "rm -f "+os.path.join(fromdatadir, 'proc*', 'var.dat')
            os.system(cmd)

def slices2h5(newdir, olddir, grid,
              todatadir='data/slices', fromdatadir='data',
              precision='d', quiet=True, lremove_old_slices=False,
              l_mpi=False, driver=None, comm=None):

    """
    Copy a simulation set of video slices written in Fortran binary to hdf5.

    call signature:

    slices2h5(newdir, olddir, grid,
              todatadir='data/slices', fromdatadir='data',
              precision='d', quiet=True, lremove_old_slices=False)

    Keyword arguments:

    *newdir*:
      String path to simulation destination directory.

    *olddir*:
      String path to simulation destination directory.

    *grid*
      simulation Grid object.

    *todatadir*:
      Directory to which the data is stored.

    *fromdatadir*:
      Directory from which the data is collected.

    *precision*:
      Single 'f' or double 'd' precision for new data.

    *quiet*
      Option not to print output.

    *lremove_old_slices*:
      If True the old video slices will be deleted once the new slices have
      been saved.
    """

    import os
    import numpy as np
    from .. import read
    from .. import sim
    from . import write_h5_slices

    if l_mpi:
        rank = comm.Get_rank()
        size = comm.Get_size()
    else:
        rank = 0
        size = 1

    #copy old video slices to new h5 sim
    os.chdir(olddir)
    #identify the coordinates and positions of the slices
    coordinates = {}
    positions = {}
    readlines1 = open('data/slice_position.dat','r').readlines()
    readlines2 = open('data/proc0/slice_position.dat','r').readlines()
    lines1, lines2 = [],[]
    for line in readlines1:
        lines1.append(int(line.split(' ')[-1].split('\n')[0]))
    """In newer binary sims lines2 obtains 7 strings below, but older sims may
    only yield the integer coordinates, so lines2 is hardcoded. The current
    version of the Pencil Code has 7 potential slices, but earlier versions
    may not. If your sim does not conform to this arrangement edit/copy this
    module and set lines1 and lines2 manually from data/slice_position.dat and
    the extensions present in your slice_*.xy  etc.
    """
    #check simulation includes the slice keys in data/proc*/slice_position.dat
    try:
        int(int(readlines2[0].split(' ')[-1].split('\n')[0]))
        lines2=['xy', 'xy2', 'xy3', 'xy4', 'xz', 'xz2', 'yz']
    except:
        for line in readlines2:
            lines2.append(line.split(' ')[-1].split('\n')[0].lower())
    #check if number of slice options as expected
    try:
        len(lines1)==7
    except ValueError:
        if rank == 0:
            print("ERROR: slice keys and positions must be set see lines 212...", flush=True)
        return -1
    for key, num in zip(lines2, lines1):
        if num > 0:
            if 'xy' in key:
                positions[key] = grid.z[num-1]
            if 'xz' in key:
                positions[key] = grid.y[num-1]
            if 'yz' in key:
                positions[key] = grid.x[num-1]
            coordinates[key] = num
    if l_mpi:
        import glob
        slice_lists = glob.glob('data/slice_*')
        slice_lists.remove('slice_position.dat')
        slice_lists = np.array_split(slice_lists,20)
        slice_list = slice_lists[rank]
        if len(slice_list) > 0:
            for field_ext in slice_list:
                field=str.split(str.split(field_ext,'_')[-1],'.')[0]
                extension=str.split(str.split(field_ext,'_')[-1],'.')[1]
                vslice = read.slices(field=field, extension=extension)
                os.chdir(newdir)
                write_h5_slices(vslice, coordinates, positions, datadir=todatadir,
                                precision=precision, quiet=quiet, driver=driver, comm=comm)
        comm.Barrier()
        if rank == size-1:
            if lremove_old_slices:
                os.chdir(olddir)
                cmd = "rm -f "+os.path.join(fromdatadir, 'proc*', 'slice_*')
                os.system(cmd)
    else:
        vslice = read.slices()
        #write new slices in hdf5
        os.chdir(newdir)
        write_h5_slices(vslice, coordinates, positions, datadir=todatadir,
                        precision=precision, quiet=quiet, driver=driver, comm=comm)
        if lremove_old_slices:
            os.chdir(olddir)
            cmd = "rm -f "+os.path.join(fromdatadir, 'proc*', 'slice_*')
            os.system(cmd)

def aver2h5(newdir, olddir,
            todatadir='data/averages', fromdatadir='data', l2D=True,
            precision='d', quiet=True, lremove_old_averages=False,
            laver2D=False, l_mpi=False, driver=None, comm=None):

    """
    Copy a simulation set of video slices written in Fortran binary to hdf5.

    call signature:

    aver2h5(newdir, olddir,
            todatadir='data/slices', fromdatadir='data', l2D=True,
            precision='d', quiet=True, lremove_old_averages=False)

    Keyword arguments:

    *newdir*:
      String path to simulation destination directory.

    *olddir*:
      String path to simulation destination directory.

    *todatadir*:
      Directory to which the data is stored.

    *fromdatadir*:
      Directory from which the data is collected.

    *l2D*
     Option to include 2D averages if the file sizes are not too large

    *precision*:
      Single 'f' or double 'd' precision for new data.

    *quiet*
      Option not to print output.

    *lremove_old_averages*:
      If True the old averages data will be deleted once the new h5 data
      has been saved.

    *laver2D*
      If True apply to each plane_list 'y', 'z' and load each variable
      sequentially
    """

    import os
    import numpy as np
    from .. import read
    from .. import sim
    from . import write_h5_averages

    #copy old 1D averages to new h5 sim
    if l_mpi:
        rank = comm.Get_rank()
        size = comm.Get_size()
    else:
        rank = 0
        size = 1

    if laver2D:
        os.chdir(olddir)
        for xl in ['y','z']:
            if os.path.exists(xl+'aver.in'):
                 variables=[]
                 file_id = open(xl+'aver.in','r')
                 for line in file_id.readlines():
                     variables.append(line.rstrip('\n'))
                 file_id.close()
                 if l_mpi:
                     varN = np.array_split(np.arange(len(variables)),size)
                     nvars = varN[rank]
                 else:
                     nvars = np.arange(len(variables))
                 if len(nvars) > 0:
                     for iav in nvars:
                         print('writing',iav,variables[iav],'of',xl+'averages', flush=True)
                         os.chdir(olddir)
                         av = read.aver(plane_list=xl, var_index=iav)
                         os.chdir(newdir)
                         for key in av.__dict__.keys():
                             if not key in 't':
                                 write_h5_averages(av, file_name=key,
                                                   datadir=todatadir,
                                                   precision=precision,
                                                   append=True,
                                                   quiet=quiet, driver=driver, comm=comm)
    else:
        if rank == size-1 or not l_mpi:
            os.chdir(olddir)
            av = read.aver()
            os.chdir(newdir)
            for key in av.__dict__.keys():
                if not key in 't':
                    write_h5_averages(av, file_name=key, datadir=todatadir,
                                      precision=precision, quiet=quiet, driver=driver, comm=comm)
            if lremove_old_averages:
                os.chdir(olddir)
                cmd = "rm -f "+os.path.join(fromdatadir, '*averages.dat')
                os.system(cmd)
            if l2D:
               plane_list = []
               os.chdir(olddir)
               if os.path.exists('xaver.in'):
                   plane_list.append('x')
               if os.path.exists('yaver.in'):
                   plane_list.append('y')
               if os.path.exists('zaver.in'):
                   plane_list.append('z')
               if len(plane_list) > 0:
                   for key in plane_list:
                       os.chdir(olddir)
                       av = read.aver(plane_list=key)
                       os.chdir(newdir)
                       write_h5_averages(av, file_name=key, datadir=todatadir,
                                         precision=precision, quiet=quiet, driver=driver, comm=comm)
    if lremove_old_averages:
        if l_mpi:
            comm.Barrier()
        os.chdir(olddir)
        cmd = "rm -f "+os.path.join(fromdatadir, '*averages.dat')
        if rank == 0:
            os.system(cmd)

def sim2h5(newdir='.', olddir='.', varfile_names=None,
           todatadir='data/allprocs', fromdatadir='data',
           precision='d', nghost=3, lpersist=False,
           x=None, y=None, z=None, lshear=False,
           lremove_old_snapshots=False, lremove_old_slices=False,
           lremove_old_averages=False, execute=False, quiet=True,
           l2D=True, lvars=True, lvids=True, laver=True, laver2D=False,
           lremove_deprecated_vids=False
          ):

    """
    Copy a simulation object written in Fortran binary to hdf5.
    The default is to copy all snapshots from/to the current simulation
    directory. Optionally the old files can be removed to

    call signature:

    sim2h5(newdir='.', olddir='.', varfile_names=None,
           todatadir='data/allprocs', fromdatadir='data',
           precision='d', nghost=3, lpersist=False,
           x=None, y=None, z=None, lshear=False,
           lremove_old_snapshots=False, lremove_old_slices=False,
           lremove_old_averages=False, execute=False, quiet=True,
           l2D=True, lvars=True, lvids=True, laver=True)

    Keyword arguments:

    *newdir*:
      String path to simulation destination directory.
      Path may be relative or absolute.

    *newdir*:
      String path to simulation destination directory.
      Path may be relative or absolute.

    *varfile_names*:
      A list of names of the snapshot files to be written, e.g. VAR0
      If None all varfiles in olddir+'/data/proc0/' will be converted

    *todatadir*:
      Directory to which the data is stored.

    *fromdatadir*:
      Directory from which the data is collected.

    *precision*:
      Single 'f' or double 'd' precision for new data.
      
    *nghost*:
      Number of ghost zones.
      TODO: handle switching size of ghost zones.

    *lpersist*:
      option to include persistent variables from snapshots.

    *xyz*:
      xyz arrays of the domain with ghost zones.
      This will normally be obtained from Grid object, but facility to
      redefine an alternative grid value.

    *lshear*:
      Flag for the shear.

    *lremove_old*:
      If True the old snapshots will be deleted once the new snapshot has
      been saved.
      A warning is given without execution to avoid unintended removal.

    *execute*:
      optional confirmation required if lremove_old.

    """

    import os
    import numpy as np
    import h5py
    import glob
    from .. import read
    from .. import sim
    from . import write_h5_grid

    try:
        from mpi4py import MPI
        comm = MPI.COMM_WORLD
        rank = comm.Get_rank()
        size = comm.Get_size()
        driver='mpio'
        l_mpi = True
        l_mpi = l_mpi and (size != 1)
    except ImportError:
        comm = None
        driver=None
        rank = 0
        size = 1
        l_mpi = False
    print('rank {} and size {}'.format(rank,size), flush=True)
    if rank == size-1:
        print('l_mpi',l_mpi, flush=True)

    #test if simulation directories
    os.chdir(olddir)
    if not sim.is_sim_dir():
        if rank == 0:
            print("ERROR: Directory ("+olddir+") needs to be a simulation", flush=True)
        return -1
    if newdir != olddir:
        os.chdir(newdir)
        if not sim.is_sim_dir():
            if rank == 0:
                print("ERROR: Directory ("+newdir+") needs to be a simulation", flush=True)
            return -1
    #
    lremove_old = lremove_old_snapshots or\
                  lremove_old_slices or lremove_old_averages
    if lremove_old:
        if not execute:
            os.chdir(olddir)
            if rank == 0:
                print("WARNING: Are you sure you wish to remove the Fortran"+
                      " binary files from \n"+
                      os.getcwd()+".\n"+
                      "Set execute=True to proceed.", flush=True)
            return -1

    os.chdir(olddir)
    if varfile_names == None:
        os.chdir(fromdatadir+'/proc0')
        lVARd = False
        varfiled_names = glob.glob('VARd*')
        if len(varfiled_names) > 0:
            varfile_names = glob.glob('VAR*')
            for iv in range(len(varfile_names)-1,-1,-1):
                if 'VARd' in varfile_names[iv]:
                    varfile_names.remove(varfile_names[iv])
            lVARd = True
        else:
            varfile_names = glob.glob('VAR*')
        os.chdir(olddir)
    gkeys = ['x', 'y', 'z', 'Lx', 'Ly', 'Lz', 'dx', 'dy', 'dz',
             'dx_1', 'dy_1', 'dz_1', 'dx_tilde', 'dy_tilde', 'dz_tilde',
            ]
    grid = None
    if rank == size-1:
        grid = read.grid(quiet=True)
    if l_mpi:
        grid=comm.bcast(grid, root=size-1)
    if not quiet:
        print(rank,grid)
    for key in gkeys:
        if not key in grid.__dict__.keys():
            if rank == 0:
                print("ERROR: key "+key+" missing from grid", flush=True)
            return -1
    #obtain the settings from the old simulation
    settings={}
    skeys = ['l1', 'l2', 'm1', 'm2', 'n1', 'n2',
             'nx', 'ny', 'nz', 'mx', 'my', 'mz',
             'nprocx', 'nprocy', 'nprocz',
             'maux', 'mglobal', 'mvar', 'precision',
            ]
    if rank == 0:
        olddim = read.dim()
        for key in skeys:
            settings[key]=olddim.__getattribute__(key)
        olddim = None
        settings['nghost']=nghost
        settings['precision']=precision.encode()
    if l_mpi:
        settings=comm.bcast(settings, root=0)
    if not quiet:
        print(rank,grid)
    #obtain physical units from old simulation
    ukeys = ['length', 'velocity', 'density', 'magnetic', 'time',
                 'temperature', 'flux', 'energy', 'mass', 'system',
                ]
    param = None
    if rank == size-1:
        param = read.param()
    if l_mpi:
        param=comm.bcast(param, root=size-1)
    param.__setattr__('unit_mass',param.unit_density*param.unit_length**3)
    param.__setattr__('unit_energy',param.unit_mass*param.unit_velocity**2)
    param.__setattr__('unit_time',param.unit_length/param.unit_velocity)
    param.__setattr__('unit_flux',param.unit_mass/param.unit_time**3)
    param.unit_system=param.unit_system.encode()
    #index list for variables in f-array
    if not quiet:
        print(rank,param)
    indx = None
    if rank == 0:
        indx = read.index()
    if l_mpi:
        indx=comm.bcast(indx, root=0)

    #check consistency between Fortran binary and h5 data
    os.chdir(newdir)
    dim = None
    if rank == size-1:
        dim = read.dim()
    if l_mpi:
        dim=comm.bcast(dim, root=size-1)
    if not quiet:
        print(rank,dim)
    try:
        dim.mvar == settings['mvar']
        dim.mx   == settings['mx']
        dim.my   == settings['my']
        dim.mz   == settings['mz']
    except ValueError:
        if rank == size-1:
            print("ERROR: new simulation dimensions do not match.", flush=True)
        return -1
    dim = None
    if rank == size-1:
        print('precision is ',precision, flush=True)
    if laver2D:
        aver2h5(newdir, olddir,
                todatadir='data/averages', fromdatadir='data', l2D=False,
                precision=precision, quiet=quiet, laver2D=laver2D,
                lremove_old_averages=False, l_mpi=l_mpi, driver=driver, comm=comm)
    #copy snapshots
    if lvars:
        var2h5(newdir, olddir, varfile_names, todatadir, fromdatadir,
               precision, lpersist, quiet, nghost, settings, param, grid,
               x, y, z, lshear, lremove_old_snapshots, indx, l_mpi=l_mpi, driver=driver, comm=comm)
    #copy downsampled snapshots if present
    if lvars and lVARd:
        var2h5(newdir, olddir, varfiled_names, todatadir, fromdatadir,
               precision, lpersist, quiet, nghost, settings, param, grid,
               x, y, z, lshear, lremove_old_snapshots, indx, last_var=False,
               trimall=True, l_mpi=l_mpi, driver=driver, comm=comm)
    #copy old video slices to new h5 sim
    if lvids:
        if lremove_deprecated_vids:
            for ext in ['bb.','uu.','ux.','uy.','uz.','bx.','by.','bz.']:
                cmd = 'rm -f data/proc*/slice_'+ext+'*'
                os.system(cmd)
        cmd = 'src/read_all_videofiles.x'
        os.system(cmd)
        slices2h5(newdir, olddir, grid,
                  todatadir='data/slices', fromdatadir='data',
                  precision=precision, quiet=quiet,
                  lremove_old_slices=lremove_old_slices, l_mpi=l_mpi, driver=driver, comm=comm)
    #copy old averages data to new h5 sim
    if laver:
        aver2h5(newdir, olddir,
                todatadir='data/averages', fromdatadir='data', l2D=l2D,
                precision=precision, quiet=quiet,
                lremove_old_averages=lremove_old_averages, l_mpi=l_mpi, driver=driver, comm=comm)
    #check some critical sim files are present for new sim without start
    #construct grid.h5 sim information if requied for new h5 sim
    os.chdir(newdir)
    if l_mpi:
        comm.Barrier()
    if rank == 0:
        write_h5_grid(file_name='grid', datadir='data', precision=precision,
                      nghost=nghost, settings=settings, param=param, grid=grid,
                      unit=None, quiet=quiet)
        source_file = os.path.join(olddir,fromdatadir,'proc0/varN.list')
        target_file = os.path.join(newdir,todatadir,'varN.list')
        if os.path.exists(source_file):
            cmd='cp '+source_file+' '+target_file
            os.system(cmd)
        items=['def_var.pro', 'index.pro', 'jobid.dat', 'param.nml',
               'particle_index.pro', 'pc_constants.pro', 'pointmass_index.pro',
               'pt_positions.dat', 'sn_series.dat', 'svnid.dat', 'time_series.dat',
               'tsnap.dat', 'tspec.dat', 'tvid.dat', 'var.general',
               'variables.pro', 'varname.dat']
        for item in items:
            source_file = os.path.join(olddir,fromdatadir,item)
            target_file = os.path.join(newdir,fromdatadir,item)
            if os.path.exists(source_file):
                if not os.path.exists(target_file):
                    cmd='cp '+source_file+' '+target_file
                    os.system(cmd)
