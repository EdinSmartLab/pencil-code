! $Id: sub.f90 13537 2010-03-25 15:20:22Z sven.bingert $
!
!  This module contains useful subroutines.
!
!  Rules:
!
!    - Please do not put very specific subroutines here. If a subroutine
!      is only needed by a single module, put it directly in that module.
!
!    - Please DO NOT use large arrays or global arrays
!      [e.g. of size (mx,my,mz) or (nxgrid,nygrid,nzgrid)]
!
module Sub
!
  use Cdata
  use Cparam
  use Messages
!
  implicit none
!
  private
!
  public :: step,step_scalar,stepdown
!
  public :: identify_bcs, parse_bc, parse_bc_rad, parse_bc_radg
!
  public :: poly, notanumber
  public :: keep_compiler_quiet
  public :: blob, vecout
  public :: cubic_step, cubic_der_step, quintic_step, quintic_der_step, erfunc
  public :: sine_step, interp1
  public :: hypergeometric2F1
  public :: gamma_function
!
  public :: get_nseed
!
  public :: grad, div, div_mn, curl, curli, curl_mn, curl_other
  public :: div_other
  public :: gij, g2ij, gij_etc
  public :: gijk_symmetric
  public :: der_step
  public :: u_dot_grad, h_dot_grad
  public :: u_dot_grad_mat
  public :: del2, del2v, del2v_etc, del2vi_etc
!
  public :: dot, dot2, dot_mn, dot_mn_sv, dot_mn_sm, dot2_mn, dot_add, dot_sub
  public :: dyadic2
  public :: cross, cross_mn
  public :: sum_mn, max_mn
  public :: multsv, multsv_add, multsv_mn, multsv_mn_add
  public :: multvs, multvv_mat
  public :: multmm_sc
  public :: multm2, multm2_mn
  public :: multmv, multmv_mn, multmv_transp
  public :: mult_matrix
!
  public :: read_line_from_file, remove_file, control_file_exists
  public :: noform

!
  public :: update_snaptime, read_snaptime
  public :: inpui, outpui, inpup, outpup
  public :: parse_shell
  public :: date_time_string, get_radial_distance, power_law
!
  public :: max_for_dt
!
  public :: write_dx_general, numeric_precision, wdim, rdim
  public :: write_zprof, remove_zprof
!
  public :: tensor_diffusion_coef
!
  public :: smooth_kernel, despike
!
  public :: ludcmp, lubksb
!
  interface poly                ! Overload the `poly' function
    module procedure poly_0
    module procedure poly_1
    module procedure poly_3
  endinterface
!
  interface grad                 ! Overload the `grad' function
    module procedure grad_main   ! grad of an 'mvar' variable
    module procedure grad_other  ! grad of another field (mx,my,mz)
  endinterface
!
  interface del2                 ! Overload the `del2' function
    module procedure del2_main
    module procedure del2_other
  endinterface
!
  interface notanumber          ! Overload the `notanumber' function
    module procedure notanumber_0
    module procedure notanumber_1
    module procedure notanumber_2
    module procedure notanumber_3
    module procedure notanumber_4
  endinterface
!
  interface keep_compiler_quiet ! Overload `keep_compiler_quiet' function
    module procedure keep_compiler_quiet_r
    module procedure keep_compiler_quiet_r1d
    module procedure keep_compiler_quiet_r2d
    module procedure keep_compiler_quiet_r3d
    module procedure keep_compiler_quiet_r4d
    module procedure keep_compiler_quiet_p
    module procedure keep_compiler_quiet_bc
    module procedure keep_compiler_quiet_sl
    module procedure keep_compiler_quiet_i
    module procedure keep_compiler_quiet_i1d
    module procedure keep_compiler_quiet_i2d
    module procedure keep_compiler_quiet_i3d
    module procedure keep_compiler_quiet_l
    module procedure keep_compiler_quiet_l1d
    module procedure keep_compiler_quiet_c
  endinterface
!
  interface cross
    module procedure cross_mn
    module procedure cross_0
  endinterface
!
  interface u_dot_grad
    module procedure u_dot_grad_scl
    module procedure u_dot_grad_vec
  endinterface
!
  interface h_dot_grad
    module procedure h_dot_grad_scl
    module procedure h_dot_grad_vec
  endinterface
!
  interface dot
    module procedure dot_mn_sv
    module procedure dot_mn
    module procedure dot_0
  endinterface
!
  interface dot2
    module procedure dot2_mn
    module procedure dot2_0
  endinterface
!
  interface dot_add
    module procedure dot_mn_add
  endinterface
!
  interface dot_sub
    module procedure dot_mn_sub
  endinterface
!
  interface multsv
    module procedure multsv_mn
  endinterface
!
  interface multsv_add
    module procedure multsv_add_mn
  endinterface
!
  interface multvs
    module procedure multvs_mn
  endinterface
!
  interface multvv_mat
    module procedure multvv_mat_mn
  endinterface
!
  interface multmm_sc
    module procedure multmm_sc_mn
  endinterface
!
  interface multm2
    module procedure multm2_mn
  endinterface
!
  interface multmv_transp
    module procedure multmv_mn_transp
  endinterface
!
  interface multmv
    module procedure multmv_mn
  endinterface
!
  interface max_for_dt
    module procedure max_for_dt_nx_nx
    module procedure max_for_dt_1_nx
    module procedure max_for_dt_1_1_1_nx
  endinterface
!
  interface cubic_step
    module procedure cubic_step_pt
    module procedure cubic_step_mn
  endinterface
!
  interface cubic_der_step
    module procedure cubic_der_step_pt
    module procedure cubic_der_step_mn
  endinterface
!
  interface quintic_step
    module procedure quintic_step_pt
    module procedure quintic_step_mn
  endinterface
!
  interface quintic_der_step
    module procedure quintic_der_step_pt
    module procedure quintic_der_step_mn
  endinterface
!
  interface erfunc
    module procedure erfunc_pt
    module procedure erfunc_mn
  endinterface
!
  interface sine_step
    module procedure sine_step_pt
    module procedure sine_step_mn
  endinterface
!
  interface power_law
     module procedure power_law_pt
     module procedure power_law_mn
  endinterface
!
!  extended intrinsic operators to do some scalar/vector pencil arithmetic
!  Tobi: Array valued functions do seem to be slower than subroutines,
!        hence commented out for the moment.
!
!  public :: operator(*),operator(+),operator(/),operator(-)
!
!  interface operator (*)
!    module procedure pencil_multiply1
!    module procedure pencil_multiply2
!  endinterface
!
!  interface operator (+)
!    module procedure pencil_add1
!    module procedure pencil_add2
!  endinterface
!
!  interface operator (/)
!    module procedure pencil_divide1
!    module procedure pencil_divide2
!  endinterface
!
!  interface operator (-)
!    module procedure pencil_substract1
!    module procedure pencil_substract2
!  endinterface

!ajwm Commented pending a C replacement
!  INTERFACE getenv
!    SUBROUTINE GETENV (VAR, VALUE)
!      CHARACTER(LEN=*) VAR, VALUE
!    endsubroutine
!  END INTERFACE

  real, dimension(7,7,7), parameter :: smth_kernel = reshape((/ &
 6.03438e-15,9.07894e-11,1.24384e-08,5.46411e-08,1.24384e-08,9.07894e-11,5.03438e-15,9.07894e-11,2.21580e-07,9.14337e-06,&
 2.69243e-05,9.14337e-06,2.21580e-07,9.07894e-11, 1.24384e-08, 9.14337e-06, 0.000183649, 0.000425400, 0.000183649, 9.14337e-06,&
 1.24384e-08,5.46411e-08,2.69243e-05,0.000425400, 0.000909623, 0.000425400, 2.69243e-05, 5.46411e-08, 1.24384e-08, 9.14337e-06,&
 0.000183649,0.000425400,0.000183649,9.14337e-06, 1.24384e-08, 9.07894e-11, 2.21580e-07, 9.14337e-06, 2.69243e-05, 9.14337e-06,&
 2.21580e-07,9.07894e-11,5.03438e-15,9.07894e-11, 1.24384e-08, 5.46411e-08, 1.24384e-08, 9.07894e-11, 5.03438e-15, 9.07894e-11,&
 2.21580e-07,9.14337e-06,2.69243e-05,9.14337e-06, 2.21580e-07, 9.07894e-11, 2.21580e-07, 7.31878e-05, 0.000909623, 0.00179548, &
 0.000909623,7.31878e-05,2.21580e-07,9.14337e-06, 0.000909623, 0.00550289, 0.00854438, 0.00550289, 0.000909623, 9.14337e-06,   &
 2.69243e-05, 0.00179548, 0.00854438,0.0122469, 0.00854438,      0.00179548, 2.69243e-05, 9.14337e-06, 0.000909623, 0.00550289,&
  0.00854438, 0.00550289,0.000909623,9.14337e-06, 2.21580e-07,  7.31878e-05, 0.000909623, 0.00179548, 0.000909623, 7.31878e-05,&
 2.21580e-07,9.07894e-11,2.21580e-07,9.14337e-06, 2.69243e-05, 9.14337e-06, 2.21580e-07, 9.07894e-11, 1.24384e-08, 9.14337e-06,&
 0.000183649,0.000425400,0.000183649,9.14337e-06, 1.24384e-08, 9.14337e-06, 0.000909623, 0.00550289, 0.00854438, 0.00550289,   &
 0.000909623,9.14337e-06,0.000183649,0.00550289, 0.0162043,    0.0197919, 0.0162043, 0.00550289, 0.000183649, 0.000425400,     &
  0.00854438,  0.0197919,  0.0223153,0.0197919, 0.00854438,        0.000425400, 0.000183649, 0.00550289, 0.0162043, 0.0197919, &
   0.0162043, 0.00550289,0.000183649,9.14337e-06, 0.000909623,  0.00550289, 0.00854438, 0.00550289, 0.000909623, 9.14337e-06,  &
 1.24384e-08,9.14337e-06,0.000183649,0.000425400, 0.000183649, 9.14337e-06, 1.24384e-08, 5.46411e-08, 2.69243e-05, 0.000425400,&
 0.000909623,0.000425400,2.69243e-05,5.46411e-08, 2.69243e-05, 0.00179548, 0.00854438, 0.0122469, 0.00854438, 0.00179548,      &
 2.69243e-05,0.000425400, 0.00854438,0.0197919, 0.0223153,      0.0197919, 0.00854438, 0.000425400, 0.000909623, 0.0122469,    &
   0.0223153,  0.0232260,  0.0223153,0.0122469, 0.000909623,       0.000425400, 0.00854438, 0.0197919, 0.0223153, 0.0197919,   &
  0.00854438,0.000425400,2.69243e-05,0.00179548, 0.00854438,   0.0122469, 0.00854438, 0.00179548, 2.69243e-05, 5.46411e-08,    &
 2.69243e-05,0.000425400,0.000909623,0.000425400, 2.69243e-05, 5.46411e-08, 1.24384e-08, 9.14337e-06, 0.000183649, 0.000425400,&
 0.000183649,9.14337e-06,1.24384e-08,9.14337e-06, 0.000909623, 0.00550289, 0.00854438, 0.00550289, 0.000909623, 9.14337e-06,   &
 0.000183649, 0.00550289,  0.0162043,0.0197919, 0.0162043,        0.00550289, 0.000183649, 0.000425400, 0.00854438, 0.0197919, &
   0.0223153,  0.0197919, 0.00854438,0.000425400, 0.000183649,    0.00550289, 0.0162043, 0.0197919, 0.0162043, 0.00550289,     &
 0.000183649,9.14337e-06,0.000909623,0.00550289, 0.00854438,   0.00550289, 0.000909623, 9.14337e-06, 1.24384e-08, 9.14337e-06, &
 0.000183649,0.000425400,0.000183649,9.14337e-06, 1.24384e-08, 9.07894e-11, 2.21580e-07, 9.14337e-06, 2.69243e-05, 9.14337e-06,&
 2.21580e-07,9.07894e-11,2.21580e-07,7.31878e-05, 0.000909623, 0.00179548, 0.000909623, 7.31878e-05, 2.21580e-07, 9.14337e-06, &
 0.000909623, 0.00550289, 0.00854438,0.00550289, 0.000909623,    9.14337e-06, 2.69243e-05, 0.00179548, 0.00854438, 0.0122469,  &
  0.00854438, 0.00179548,2.69243e-05,9.14337e-06, 0.000909623,  0.00550289, 0.00854438, 0.00550289, 0.000909623, 9.14337e-06,  &
 2.21580e-07,7.31878e-05,0.000909623,0.00179548, 0.000909623,  7.31878e-05, 2.21580e-07, 9.07894e-11, 2.21580e-07, 9.14337e-06,&
 2.69243e-05,9.14337e-06,2.21580e-07,9.07894e-11, 5.03438e-15, 9.07894e-11, 1.24384e-08, 5.46411e-08, 1.24384e-08, 9.07894e-11,&
 5.03438e-15,9.07894e-11,2.21580e-07,9.14337e-06, 2.69243e-05, 9.14337e-06, 2.21580e-07, 9.07894e-11, 1.24384e-08, 9.14337e-06,&
 0.000183649,0.000425400,0.000183649,9.14337e-06, 1.24384e-08, 5.46411e-08, 2.69243e-05, 0.000425400, 0.000909623, 0.000425400,&
 2.69243e-05,5.46411e-08,1.24384e-08,9.14337e-06, 0.000183649, 0.000425400, 0.000183649, 9.14337e-06, 1.24384e-08, 9.07894e-11,&
 2.21580e-07,9.14337e-06,2.69243e-05,9.14337e-06, 2.21580e-07, 9.07894e-11, 5.03438e-15, 9.07894e-11, 1.24384e-08, 5.46411e-08,&
 1.24384e-08,9.07894e-11,5.03438e-15 /), (/ 7, 7, 7 /))
!
  contains
!
!***********************************************************************
    subroutine max_mn(a,res)
!
!  successively calculate maximum of a, which is supplied at each call.
!  Start from scratch if lfirstpoint=.true.
!
!   1-apr-01/axel+wolf: coded
!
      real, dimension (nx) :: a
      real :: res
!
      if (lfirstpoint) then
        res=maxval(a)
      else
        res=max(res,maxval(a))
      endif
!
    endsubroutine max_mn
!***********************************************************************
    subroutine mean_mn(a,res)
!
!  successively calculate mean of a, which is supplied at each call.
!  Start from zero if lfirstpoint=.true.
!
!   17-dec-01/wolf: coded
!
      real, dimension (nx) :: a
      real :: res
!
      if (lfirstpoint) then
        res=sum(a*1.D0)     ! sum at double precision to improve accuracy
      else
        res=res+sum(a*1.D0)
      endif
!
    endsubroutine mean_mn
!***********************************************************************
    subroutine rms_mn(a,res)
!
!  successively calculate rms of a, which is supplied at each call.
!  Start from zero if lfirstpoint=.true.
!
!   1-apr-01/axel+wolf: coded
!
      real, dimension (nx) :: a
      real :: res
!
      if (lfirstpoint) then
        res=sum(a**2)
      else
        res=res+sum(a**2)
      endif
!
    endsubroutine rms_mn
!***********************************************************************
    subroutine rms2_mn(a2,res)
!
!  successively calculate rms of a, with a2=a^2 being supplied at each
!  call.
!  Start from zero if lfirstpoint=.true.
!
!   1-apr-01/axel+wolf: coded
!
      real, dimension (nx) :: a2
      real :: res
!
      if (lfirstpoint) then
        res=sum(a2)
      else
        res=res+sum(a2)
      endif
!
    endsubroutine rms2_mn
!***********************************************************************
    subroutine sum_mn(a,res)
!
!  successively calculate the sum over all points of a, which is supplied
!  at each call.
!  Start from zero if lfirstpoint=.true.
!
!   1-apr-01/axel+wolf: coded
!
      real, dimension (nx) :: a
      real :: res
!
      if (lfirstpoint) then
        res=sum(a)
      else
        res=res+sum(a)
      endif
!
    endsubroutine sum_mn
!***********************************************************************
    subroutine dot_mn(a,b,c)
!
!  dot product, c=a.b, on pencil arrays
!   3-apr-01/axel+gitta: coded

      real, dimension (nx,3) :: a,b
      real, dimension (nx) :: c
!
      intent(in) :: a,b
      intent(out) :: c
!
      c=a(:,1)*b(:,1)+a(:,2)*b(:,2)+a(:,3)*b(:,3)
!
    endsubroutine dot_mn
!***********************************************************************
    subroutine vec_dot_3tensor(a,b,c,ladd)
!
!  dot product of a vector with 3 tensor,
!   c_ij = a_k b_ijk
!   28-aug-08/dhruba : coded

      real, dimension (nx,3) :: a
      real, dimension (nx,3,3) :: c
      real, dimension (nx,3,3,3) :: b
      integer :: i,j
!
      logical, optional :: ladd
      logical :: ladd1

      intent(in) :: a,b,ladd
      intent(out) :: c

      if (present(ladd)) then
        ladd1=ladd
      else
        ladd1=.false.
      endif
!
      do i=1,3
        do j=1,3
          if (ladd1) then
            c(:,i,j)=c(:,i,j)+a(:,1)*b(:,i,j,1)+a(:,2)*b(:,i,j,2)+a(:,3)*b(:,i,j,3)
          else
            c(:,i,j)=a(:,1)*b(:,i,j,1)+a(:,2)*b(:,i,j,2)+a(:,3)*b(:,i,j,3)
          endif
        enddo
      enddo
!
    endsubroutine vec_dot_3tensor
!***********************************************************************
    subroutine contract_jk3(a,c)
!
!  contracts the jk of a_ijk
!  20-aug-08/dhruba: coded

      real, dimension (nx,3,3,3) :: a
      real, dimension (nx,3) :: c
      integer :: i,j,k
!
      intent(in) :: a
      intent(out) :: c
!
      c=0
      do i=1,3
        do j=1,3
          do k=1,3
            c(:,i)=c(:,i)+a(:,i,j,k)
          enddo
      enddo
    enddo
!
    endsubroutine contract_jk3
!***********************************************************************
    subroutine dot_mn_sv(a,b,c)
!
!  dot product, c=a.b, between non-pencilized vector and  pencil array
!  10-oct-06/axel: coded
!
      real, dimension (3)    :: a
      real, dimension (nx,3) :: b
      real, dimension (nx)   :: c
!
      intent(in) :: a,b
      intent(out) :: c
!
      c=a(1)*b(:,1)+a(2)*b(:,2)+a(3)*b(:,3)
!
    endsubroutine dot_mn_sv
!***********************************************************************
    subroutine dot_mn_sm(a,b,c)
!
!  dot product, c=a.b, between non-pencilized vector and pencil matrix
!  10-oct-06/axel: coded
!
      real, dimension (3)      :: a
      real, dimension (nx,3,3) :: b
      real, dimension (nx,3)   :: c
      integer :: i
!
      intent(in) :: a,b
      intent(out) :: c
!
      do i=1,3
        c(:,i)=a(1)*b(:,i,1)+a(2)*b(:,i,2)+a(3)*b(:,i,3)
      enddo
!
    endsubroutine dot_mn_sm
!***********************************************************************
    subroutine dot_0(a,b,c)
!
!  dot product, c=a.b, of two simple 3-d arrays
!  11-mar-04/wolf: coded
!
      real, dimension (:) :: a,b
      real :: c
!
      intent(in) :: a,b
      intent(out) :: c
!
      c = dot_product(a,b)
!
    endsubroutine dot_0
!***********************************************************************
    subroutine dot2_mn(a,b,fast_sqrt,precise_sqrt)
!
!  dot product with itself, to calculate max and rms values of a vector.
!  FAST_SQRT is only correct for ~1e-18 < |a| < 1e18 (for single precision);
!  PRECISE_SQRT works for full range.
!
!  29-sep-97/axel: coded
!   1-apr-01/axel: adapted for cache-efficient sub-array formulation
!  25-jun-05/bing: added optional args for calculating |a|
!
      real, dimension (nx,3) :: a
      real, dimension (nx) :: b,a_max
      logical, optional :: fast_sqrt,precise_sqrt
      logical :: fast_sqrt1,precise_sqrt1
!
      intent(in) :: a,fast_sqrt,precise_sqrt
      intent(out) :: b
!
!     ifc treats these variables as SAVE so we need to reset
      if (present(fast_sqrt)) then
        fast_sqrt1=fast_sqrt
      else
        fast_sqrt1=.false.
      endif

      if (present(precise_sqrt)) then
        precise_sqrt1=precise_sqrt
      else
        precise_sqrt1=.false.
      endif
!
!  rescale by factor a_max before taking sqrt.
!  In single precision this increases the dynamic range from 1e18 to 1e36.
!  To avoid division by zero when calculating a_max, we add tini.
!
      if (precise_sqrt1) then
         a_max=tini+maxval(abs(a),dim=2)
         b=(a(:,1)/a_max)**2+(a(:,2)/a_max)**2+(a(:,3)/a_max)**2
         b=a_max*sqrt(b)
      else
         b=a(:,1)**2+a(:,2)**2+a(:,3)**2
         if (fast_sqrt1) b=sqrt(b)
      endif
!
    endsubroutine dot2_mn
!***********************************************************************
    subroutine dot2_0(a,b)
!
!  dot product, c=a.b, of two simple 3-d arrays
!  11-mar-04/wolf: coded
!
      real, dimension (:) :: a
      real :: b
!
      intent(in) :: a
      intent(out) :: b
!
      b = dot_product(a,a)
!
    endsubroutine dot2_0
!***********************************************************************
    subroutine dot_mn_add(a,b,c)
!
!  dot product, add to previous value
!  11-nov-02/axel: adapted from dot_mn
!
      real, dimension (nx,3) :: a,b
      real, dimension (nx) :: c
!
      intent(in) :: a,b
      intent(inout) :: c
!
      c=c+a(:,1)*b(:,1)+a(:,2)*b(:,2)+a(:,3)*b(:,3)
!
    endsubroutine dot_mn_add
!***********************************************************************
    subroutine dot_mn_sub(a,b,c)
!
!  dot product, subtract from previous value
!  21-jul-03/axel: adapted from dot_mn_sub
!
      real, dimension (nx,3) :: a,b
      real, dimension (nx) :: c
!
      intent(in) :: a,b
      intent(inout) :: c
!
      c=c-(a(:,1)*b(:,1)+a(:,2)*b(:,2)+a(:,3)*b(:,3))
!
    endsubroutine dot_mn_sub

!***********************************************************************
    subroutine dyadic2(a,b)
!
!  dyadic product with itself
!
!  24-jan-09/axel: coded
!
      real, dimension (nx,3) :: a
      real, dimension (nx,3,3) :: b
!
      intent(in) :: a
      intent(out) :: b
!
!  diagonal components
!
      b(:,1,1)=a(:,1)**2
      b(:,2,2)=a(:,2)**2
      b(:,3,3)=a(:,3)**2
!
!  upper off-diagonal components
!
      b(:,1,2)=a(:,1)*a(:,2)
      b(:,1,3)=a(:,1)*a(:,3)
      b(:,2,3)=a(:,2)*a(:,3)
!
!  lower off-diagonal components
!
      b(:,2,1)=b(:,1,2)
      b(:,3,1)=b(:,1,3)
      b(:,3,2)=b(:,2,3)
!
    endsubroutine dyadic2
!***********************************************************************
    subroutine trace_mn(a,b)
!
!  trace of a matrix
!   3-apr-01/axel+gitta: coded
!
      real, dimension (nx,3,3) :: a
      real, dimension (nx) :: b
!
      intent(in) :: a
      intent(out) :: b
!
      b=a(:,1,1)+a(:,2,2)+a(:,3,3)
!
    endsubroutine trace_mn
!***********************************************************************
    subroutine multvv_mat_mn(a,b,c)
!
!  vector multiplied with vector, gives matrix
!   21-dec-01/nils: coded
!   16-jul-02/nils: adapted from pencil_mpi
!
      real, dimension (nx,3) :: a,b
      real, dimension (nx,3,3) :: c
      integer :: i,j
!
      do i=1,3
        do j=1,3
          c(:,i,j)=a(:,j)*b(:,i)
        enddo
      enddo
!
    endsubroutine multvv_mat_mn
!***********************************************************************
    subroutine multmm_sc_mn(a,b,c)
!
!  matrix multiplied with matrix, gives scalar
!   21-dec-01/nils: coded
!   16-jul-02/nils: adapted from pencil_mpi
!
      real, dimension (nx,3,3) :: a,b
      real, dimension (nx) :: c
      integer :: i,j
!
      c=0
      do i=1,3
         do j=1,3
            c=c+a(:,i,j)*b(:,i,j)
         enddo
      enddo
!
    endsubroutine multmm_sc_mn
!***********************************************************************
    subroutine mult_matrix(a,b,c)
!
!  Matrix multiplication of two pencil variables.
!
      real, dimension (nx,3,3) :: a,b
      real, dimension (nx,3,3) :: c
      integer :: i,j,k
!
      c=0
      do i=1,3
        do j=1,3
          do k=1,3
            c(:,i,j)=c(:,i,j)+a(:,i,k)*b(:,k,j)
          enddo
        enddo
      enddo

!
    endsubroutine mult_matrix
!***********************************************************************
    subroutine multm2_mn(a,b)
!
!  matrix squared, gives scalar
!
!  11-nov-02/axel: adapted from multmm_sc_mn
!
      real, dimension (nx,3,3) :: a
      real, dimension (nx) :: b
      integer :: i,j
!
      b=0
      do i=1,3
         do j=1,3
            b=b+a(:,i,j)**2
         enddo
      enddo
!
    endsubroutine multm2_mn
!***********************************************************************
    subroutine multmv_mn(a,b,c,ladd)
!
!  matrix multiplied with vector, gives vector
!  C_i = A_{i,j} B_j
!
!   3-apr-01/axel+gitta: coded
!  24-jun-08/MR: ladd added for incremental work
!
      real, dimension (nx,3,3) :: a
      real, dimension (nx,3) :: b,c
      real, dimension (nx) :: tmp
      integer :: i,j
      logical, optional :: ladd
      logical :: ladd1
!
      intent(in) :: a,b,ladd
      intent(out) :: c
!
      if (present(ladd)) then
        ladd1=ladd
      else
        ladd1=.false.
      endif

      do i=1,3

        j=1
        tmp=a(:,i,j)*b(:,j)
        do j=2,3
          tmp=tmp+a(:,i,j)*b(:,j)
        enddo

        if (ladd1) then
          c(:,i)=c(:,i)+tmp
        else
          c(:,i)=tmp
        endif

      enddo
!
    endsubroutine multmv_mn
!***********************************************************************
    subroutine multmv_mn_transp(a,b,c,ladd)
!
!  transposed matrix multiplied with vector, gives vector
!  could have called multvm_mn, but this may not be clear enough
!  C_i = A_{j,i} B_j
!
!  21-jul-03/axel: adapted from multmv_mn
!  24-jun-08/MR: ladd added for incremental work
!
      real, dimension (nx,3,3) :: a
      real, dimension (nx,3) :: b,c
      real, dimension (nx) :: tmp
      integer :: i,j
      logical, optional :: ladd
      logical :: ladd1
!
      intent(in) :: a,b,ladd
      intent(inout) :: c
!
      if (present(ladd)) then
        ladd1=ladd
      else
        ladd1=.false.
      endif

      do i=1,3
        j=1
        tmp=a(:,j,i)*b(:,j)
        do j=2,3
          tmp=tmp+a(:,j,i)*b(:,j)
        enddo

        if (ladd1) then
          c(:,i)=c(:,i)+tmp
        else
          c(:,i)=tmp
        endif

      enddo
!
    endsubroutine multmv_mn_transp
!***********************************************************************
    subroutine multsv_mn(a,b,c)
!
!  vector multiplied with scalar, gives vector
!
!  22-nov-01/nils erland: coded
!  10-oct-03/axel: a is now the scalar (now consistent with old routines)
!  24-jun-08/MR: ladd added for incremental work
!  28-feb-10/bing: removed ladd keyword, use multsv_mn_add instead
!
      intent(in) :: a,b
      intent(out) :: c
!
      real, dimension (nx,3) :: b,c
      real, dimension (nx) :: a
      integer :: i
!
      do i=1,3
        c(:,i)=a*b(:,i)
      enddo
!
    endsubroutine multsv_mn
!***********************************************************************
    subroutine multsv_mn_add(a,b,c)
!
!  vector multiplied with scalar, gives vector
!
!  22-nov-01/nils erland: coded
!  10-oct-03/axel: a is now the scalar (now consistent with old routines)
!  24-jun-08/MR: ladd added for incremental work
!
      intent(in) :: a,b
      intent(inout) :: c
!
      real, dimension (nx,3) :: b,c
      real, dimension (nx) :: a
      integer :: i
!
      do i=1,3
        c(:,i)=c(:,i)+a*b(:,i)
      enddo
!
    endsubroutine multsv_mn_add
!***********************************************************************
    subroutine multsv_add_mn(a,b,c,d)
!
!  multiply scalar with a vector and subtract from another vector
!  29-oct-97/axel: coded
!
      real, dimension (nx,3) :: a,c,d
      real, dimension (nx) :: b
      integer :: j
!
      intent(in) :: a,b,c
      intent(out) :: d
!
      do j=1,3
        d(:,j)=a(:,j)+b*c(:,j)
      enddo
!
    endsubroutine multsv_add_mn
!***********************************************************************
    subroutine multvs_mn(a,b,c)
!
!  vector pencil multiplied with scalar pencil, gives vector pencil
!   22-nov-01/nils erland: coded
!
      real, dimension (nx,3) :: a, c
      real, dimension (nx) :: b
      integer :: i
!
      do i=1,3
        c(:,i)=a(:,i)*b(:)
      enddo
!
    endsubroutine multvs_mn
!***********************************************************************
    subroutine cross_mn(a,b,c)
!
!  cross product, c = a x b, for pencil variables.
!  Previously called crossp.
!
      real, dimension (nx,3) :: a,b,c
!
      intent(in) :: a,b
      intent(out) :: c
!
      c(:,1)=a(:,2)*b(:,3)-a(:,3)*b(:,2)
      c(:,2)=a(:,3)*b(:,1)-a(:,1)*b(:,3)
      c(:,3)=a(:,1)*b(:,2)-a(:,2)*b(:,1)
!
    endsubroutine cross_mn
!***********************************************************************
    subroutine cross_0(a,b,c)
!
!  cross product, c = a x b, for simple 3-d vectors
!  (independent of position)
!
      real, dimension (3) :: a,b,c
!
      intent(in) :: a,b
      intent(out) :: c
!
      c(1)=a(2)*b(3)-a(3)*b(2)
      c(2)=a(3)*b(1)-a(1)*b(3)
      c(3)=a(1)*b(2)-a(2)*b(1)
!
    endsubroutine cross_0
!***********************************************************************
    subroutine gij(f,k,g,nder)
!
!  calculate gradient of a vector, return matrix
!   3-apr-01/axel+gitta: coded
!
      use Deriv, only: der,der2
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx,3,3) :: g
      real, dimension (nx) :: tmp
      integer :: i,j,k,k1,nder
!
      intent(in) :: f,k
      intent(out) :: g
!
      k1=k-1
      do i=1,3
        do j=1,3
          if (nder == 1) then
            call der(f,k1+i,tmp,j)
          elseif (nder == 2) then
            call der2(f,k1+i,tmp,j)
          endif
          g(:,i,j)=tmp
        enddo
      enddo
!
    endsubroutine gij
!***********************************************************************
    subroutine gijk_symmetric(f,k,g,nder)
!
!  calculate gradient of a (symmetric) second rank matrix, return 3rd rank matrix
!   18-aug-08/dhruba: coded
!
      use Deriv, only: der,der2
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx,3,3,3) :: g
      real, dimension (nx,2,3,3) :: tmpg
      real, dimension (nx) :: tmp
      integer :: i,j,l,l1,k,k1,nder
!
      intent(in) :: f,k
      intent(out) :: g
!
      k1=k-1
      do i=1,2
        do l=1,3
          l1=l-1
          do j=1,3
            if (nder == 1) then
              call der(f,k1+i+l1,tmp,j)
            elseif (nder == 2) then
              call der2(f,k1+i+l1,tmp,j)
            endif
            tmpg(:,i,l,j)=tmp
          enddo
        enddo
      enddo
      g(:,1,1,:) = tmpg(:,1,1,:)
      g(:,2,2,:) = tmpg(:,1,2,:)
      g(:,3,3,:) = tmpg(:,1,3,:)
      g(:,1,2,:) = tmpg(:,2,1,:)
      g(:,2,1,:) = g(:,1,2,:)
      g(:,1,3,:) = tmpg(:,2,2,:)
      g(:,3,1,:) = g(:,1,3,:)
      g(:,2,3,:) = tmpg(:,2,3,:)
      g(:,3,2,:) = g(:,2,3,:)
!
    endsubroutine gijk_symmetric
!***********************************************************************
    subroutine grad_main(f,k,g)
!
!  calculate gradient of a scalar, get vector
!  29-sep-97/axel: coded
!
      use Deriv, only: der
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx,3) :: g
      real, dimension (nx) :: tmp
      integer :: k
!
      intent(in) :: f,k
      intent(out) :: g
!
      call der(f,k,tmp,1); g(:,1)=tmp
      call der(f,k,tmp,2); g(:,2)=tmp
      call der(f,k,tmp,3); g(:,3)=tmp
!
    endsubroutine grad_main
!***********************************************************************
    subroutine grad_other(f,g)
!
!  FOR NON 'mvar' variable
!  calculate gradient of a scalar, get vector
!  26-nov-02/tony: coded
!
      use Deriv, only: der
!
      real, dimension (mx,my,mz) :: f
      real, dimension (nx,3) :: g
      real, dimension (nx) :: tmp
!
      intent(in) :: f
      intent(out) :: g
!
! Uses overloaded der routine
!
      call der(f,tmp,1); g(:,1)=tmp
      call der(f,tmp,2); g(:,2)=tmp
      call der(f,tmp,3); g(:,3)=tmp
!
    endsubroutine grad_other
!***********************************************************************
    subroutine div(f,k,g)
!
!  calculate divergence of vector, get scalar
!  13-dec-01/nils: coded
!  16-jul-02/nils: adapted from pencil_mpi
!
      use Deriv, only: der
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx) :: g, tmp
      integer :: k,k1
!
      intent(in)  :: f,k
      intent(out) :: g
!
      k1=k-1
!
      call der(f,k1+1,tmp,1)
      g=tmp
      call der(f,k1+2,tmp,2)
      g=g+tmp
      call der(f,k1+3,tmp,3)
      g=g+tmp
!
    endsubroutine div
!***********************************************************************
    subroutine div_other(f,g)
!
      use Deriv, only: der

      real, dimension (mx,my,mz,3) :: f
      real, dimension (nx) :: g, tmp
!
      call der(f(:,:,:,1),tmp,1)
      g=tmp
      call der(f(:,:,:,2),tmp,2)
      g=g+tmp
      call der(f(:,:,:,3),tmp,3)
      g=g+tmp
!
    endsubroutine div_other
!***********************************************************************
    subroutine div_mn(aij,b)
!
!  calculate divergence from derivative matrix
!  18-sep-04/axel: coded
!
      real, dimension (nx,3,3) :: aij
      real, dimension (nx) :: b
!
      intent(in) :: aij
      intent(out) :: b
!
      b=aij(:,1,1)+aij(:,2,2)+aij(:,3,3)
!
    endsubroutine div_mn
!***********************************************************************
    subroutine curl_mn(aij,b)
!
!  calculate curl from derivative matrix
!  21-jul-03/axel: coded
!
      real, dimension (nx,3,3), intent (in) :: aij
      real, dimension (nx,3), intent (out) :: b
!
      b(:,1)=aij(:,3,2)-aij(:,2,3)
      b(:,2)=aij(:,1,3)-aij(:,3,1)
      b(:,3)=aij(:,2,1)-aij(:,1,2)
!
    endsubroutine curl_mn
!***********************************************************************
    subroutine curl(f,k,g)
!
!  calculate curl of a vector, get vector
!  12-sep-97/axel: coded
!  10-sep-01/axel: adapted for cache efficiency
!
      use Deriv, only: der
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx,3) :: g
      real, dimension (nx) :: tmp1,tmp2
      integer :: k,k1
!
      intent(in) :: f,k
      intent(out) :: g
!
      k1=k-1
!
      call der(f,k1+3,tmp1,2)
      call der(f,k1+2,tmp2,3)
      g(:,1)=tmp1-tmp2
!
      call der(f,k1+1,tmp1,3)
      call der(f,k1+3,tmp2,1)
      g(:,2)=tmp1-tmp2
!
      call der(f,k1+2,tmp1,1)
      call der(f,k1+1,tmp2,2)
      g(:,3)=tmp1-tmp2
!
    endsubroutine curl
!***********************************************************************
    subroutine curl_other(f,g)
!
!  calculate curl of a non-mvar vector, get vector
!  23-june-09/wlad: adapted from curl
!
      use Deriv, only: der
!
      real, dimension (mx,my,mz,3) :: f
      real, dimension (nx,3) :: g
      real, dimension (nx) :: tmp1,tmp2
!
      intent(in) :: f
      intent(out) :: g
!
      call der(f(:,:,:,3),tmp1,2)
      call der(f(:,:,:,2),tmp2,3)
      g(:,1)=tmp1-tmp2
!
      call der(f(:,:,:,1),tmp1,3)
      call der(f(:,:,:,3),tmp2,1)
      g(:,2)=tmp1-tmp2
!
      call der(f(:,:,:,2),tmp1,1)
      call der(f(:,:,:,1),tmp2,2)
      g(:,3)=tmp1-tmp2
!
    endsubroutine curl_other
!***********************************************************************
    subroutine curli(f,k,g,i)
!
!  calculate curl of a vector, get vector
!  22-oct-02/axel+tarek: adapted from curl
!
      use Deriv, only: der
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx) :: g
      real, dimension (nx) :: tmp1,tmp2
      integer :: k,k1,i
!
      intent(in) :: f,k,i
      intent(out) :: g
!
      k1=k-1
!
      select case (i)
!
      case (1)
      call der(f,k1+3,tmp1,2)
      call der(f,k1+2,tmp2,3)
      g=tmp1-tmp2
!
      case (2)
      call der(f,k1+1,tmp1,3)
      call der(f,k1+3,tmp2,1)
      g=tmp1-tmp2
!
      case (3)
      call der(f,k1+2,tmp1,1)
      call der(f,k1+1,tmp2,2)
      g=tmp1-tmp2
!
      endselect
!
    endsubroutine curli
!***********************************************************************
    subroutine del2_main(f,k,del2f)
!
!  calculate del2 of a scalar, get scalar
!  12-sep-97/axel: coded
!
      use Deriv, only: der,der2
!
      intent(in) :: f,k
      intent(out) :: del2f
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx) :: del2f,d2fdx,d2fdy,d2fdz
      integer :: k
!
      call der2(f,k,d2fdx,1)
      call der2(f,k,d2fdy,2)
      call der2(f,k,d2fdz,3)
      del2f=d2fdx+d2fdy+d2fdz
!
   endsubroutine del2_main
!***********************************************************************
    subroutine del2_other(f,del2f)
!
!  calculate del2 of a scalar, get scalar
!   8-may-09/nils: adapted from del2
!
      use Deriv, only: der,der2
!
      intent(in) :: f
      intent(out) :: del2f
!
      real, dimension (mx,my,mz) :: f
      real, dimension (nx) :: del2f,d2fdx,d2fdy,d2fdz
!
      call der2(f,d2fdx,1)
      call der2(f,d2fdy,2)
      call der2(f,d2fdz,3)
      del2f=d2fdx+d2fdy+d2fdz
!
   endsubroutine del2_other
!***********************************************************************
    subroutine del2v(f,k,del2f)
!
!  calculate del2 of a vector, get vector
!  28-oct-97/axel: coded
!
      use Deriv, only: der
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx,3) :: del2f
      real, dimension (nx) :: tmp
      integer :: i,k,k1
!
      intent(in) :: f,k
      intent(out) :: del2f
!
!  do the del2 diffusion operator
!
      k1=k-1
      do i=1,3
        call del2(f,k1+i,tmp)
        del2f(:,i)=tmp
      enddo
!
    endsubroutine del2v
!***********************************************************************
    subroutine del2v_etc(f,k,del2,graddiv,curlcurl,gradcurl)
!
!  calculates a number of second derivative expressions of a vector
!  outputs a number of different vector fields.
!  gradcurl is not the vector gradient.
!  Surprisingly, calling derij only if graddiv or curlcurl are present
!  does not speed up the code on Mephisto @ 32x32x64.
!
!  12-sep-01/axel: coded
!
      use Deriv, only: der,der2,derij
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx,3,3) :: fjji,fijj
      real, dimension (nx,3,3), optional :: gradcurl
      real, dimension (nx,3), optional :: del2,graddiv,curlcurl
      real, dimension (nx,3) ::  fjik
      real, dimension (nx) :: tmp
      integer :: i,j,k,k1
!
      intent(in) :: f,k
      intent(out) :: del2,graddiv,curlcurl,gradcurl
!
!  calculate f_{i,jj} and f_{j,ji}
!  AJ: graddiv needs diagonal elements from the first tmp (derij only sets
!      off-diagonal elements)
!
      k1=k-1
      do i=1,3
      do j=1,3
        if (present(del2) .or. present(curlcurl) .or. present(gradcurl) .or. &
            present(graddiv)) then
          call der2 (f,k1+i,tmp,  j); fijj(:,i,j)=tmp  ! f_{i,jj}
        endif
        if (present(graddiv) .or. present(curlcurl).or. present(gradcurl)) then
          call derij(f,k1+j,tmp,j,i); fjji(:,i,j)=tmp  ! f_{j,ji}
        endif
      enddo
      enddo
!
!  the diagonal terms have not been set in derij; do this now
!  ** They are automatically set above, because derij   **
!  ** doesn't overwrite the value of tmp for i=j!       **
!
!     do j=1,3
!       fjji(:,j,j)=fijj(:,j,j)
!     enddo
!

!
!  calculate f_{i,jk} for i /= j /= k
!
      if (present(gradcurl)) then
        call derij(f,k1+1,tmp,2,3)
        fjik(:,1)=tmp
        call derij(f,k1+2,tmp,1,3)
        fjik(:,2)=tmp
        call derij(f,k1+3,tmp,1,2)
        fjik(:,3)=tmp
      endif
!
      if (present(del2)) then
        do i=1,3
          del2(:,i)=fijj(:,i,1)+fijj(:,i,2)+fijj(:,i,3)
        enddo
      endif
!
      if (present(graddiv)) then
        do i=1,3
          graddiv(:,i)=fjji(:,i,1)+fjji(:,i,2)+fjji(:,i,3)
        enddo
      endif
!
      if (present(curlcurl)) then
        curlcurl(:,1)=fjji(:,1,2)-fijj(:,1,2)+fjji(:,1,3)-fijj(:,1,3)
        curlcurl(:,2)=fjji(:,2,3)-fijj(:,2,3)+fjji(:,2,1)-fijj(:,2,1)
        curlcurl(:,3)=fjji(:,3,1)-fijj(:,3,1)+fjji(:,3,2)-fijj(:,3,2)
      endif
!
      if (present(gradcurl)) then
         gradcurl(:,1,1) = fjik(:,3)   - fjik(:,2)
         gradcurl(:,1,2) = fjji(:,1,3) - fijj(:,3,1)
         gradcurl(:,1,3) = fijj(:,2,1) - fjji(:,1,2)

         gradcurl(:,2,1) = fijj(:,3,2) - fjji(:,2,3)
         gradcurl(:,2,2) = fjik(:,1)   - fjik(:,3)
         gradcurl(:,2,3) = fjji(:,2,1) - fijj(:,1,2)

         gradcurl(:,3,1) = fjji(:,3,2) - fijj(:,2,3)
         gradcurl(:,3,2) = fijj(:,1,3) - fjji(:,3,1)
         gradcurl(:,3,3) = fjik(:,2)   - fjik(:,1)
!
      endif
!
    endsubroutine del2v_etc
!***********************************************************************
    subroutine del2vi_etc(f,k,ii,del2,graddiv,curlcurl)
!
!  calculates a number of second derivative expressions of a vector
!  outputs a number of different vector fields.
!  Surprisingly, calling derij only if graddiv or curlcurl are present
!  does not speed up the code on Mephisto @ 32x32x64.
!  Just do the ith component
!
!   7-feb-04/axel: adapted from del2v_etc
!
      use Deriv, only: der2,derij
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx,3,3) :: fjji,fijj
      real, dimension (nx), optional :: del2,graddiv,curlcurl
      real, dimension (nx) :: tmp
      integer :: i,j,k,k1,ii
!
      intent(in) :: f,k,ii
      intent(out) :: del2,graddiv,curlcurl
!
!  do the del2 diffusion operator
!
      k1=k-1
      do i=1,3
      do j=1,3
        call der2 (f,k1+i,tmp,  j); fijj(:,i,j)=tmp  ! f_{i,jj}
        call derij(f,k1+j,tmp,j,i); fjji(:,i,j)=tmp  ! f_{j,ji}
      enddo
      enddo
!
      if (present(del2)) then
        del2=fijj(:,ii,1)+fijj(:,ii,2)+fijj(:,ii,3)
      endif
!
      if (present(graddiv)) then
        graddiv=fjji(:,ii,1)+fjji(:,ii,2)+fjji(:,ii,3)
      endif
!
      if (present(curlcurl)) then
        select case (ii)
        case (1); curlcurl=fjji(:,1,2)-fijj(:,1,2)+fjji(:,1,3)-fijj(:,1,3)
        case (2); curlcurl=fjji(:,2,3)-fijj(:,2,3)+fjji(:,2,1)-fijj(:,2,1)
        case (3); curlcurl=fjji(:,3,1)-fijj(:,3,1)+fjji(:,3,2)-fijj(:,3,2)
        endselect
      endif
!
    endsubroutine del2vi_etc
!***********************************************************************
    subroutine gij_etc(f,iref,Bij,del2,graddiv)
!
!  calculate B_i,j = eps_ikl A_l,jk and A_l,kk
!
!  21-jul-03/axel: coded
!  26-jul-05/tobi: do not calculate both d^2 A/(dx dy) and d^2 A/(dy dx)
!
      use Deriv, only: der2,derij
!
      real, dimension (mx,my,mz,mfarray), intent (in) :: f
      integer, intent (in) :: iref
      real, dimension (nx,3,3), intent (out) :: bij
      real, dimension (nx,3), intent (out), optional :: del2,graddiv
!
!  locally used variables
!
      real, dimension (nx,3,3,3) :: d2A
      real, dimension (nx) :: tmp
      integer :: iref1,i,j
!
!  reference point of argument
!
      iref1=iref-1
!
!  calculate all mixed and non-mixed second derivatives
!  of the vector potential (A_k,ij)
!
!  do not calculate both d^2 A/(dx dy) and d^2 A/(dy dx)
!  (This wasn't spotted by me but by a guy from SGI...)
!  Note: for non-cartesian coordinates there are different correction terms,
!  see below.
!
      do i=1,3
        do j=1,3
          call der2(f,iref1+i,tmp,j); d2A(:,j,j,i)=tmp
        enddo
        call derij(f,iref1+i,tmp,2,3); d2A(:,2,3,i)=tmp; d2A(:,3,2,i)=tmp
        call derij(f,iref1+i,tmp,3,1); d2A(:,3,1,i)=tmp; d2A(:,1,3,i)=tmp
        call derij(f,iref1+i,tmp,1,2); d2A(:,1,2,i)=tmp; d2A(:,2,1,i)=tmp
      enddo
!
!  calculate b_i,j = eps_ikl A_l,kj, as well as optionally,
!  del2_i = A_i,jj and graddiv_i = A_j,ji
!
      bij(:,1,:)=d2A(:,2,:,3)-d2A(:,3,:,2)
      bij(:,2,:)=d2A(:,3,:,1)-d2A(:,1,:,3)
      bij(:,3,:)=d2A(:,1,:,2)-d2A(:,2,:,1)
!
!  calculate del2 and graddiv, if requested
!
      if (present(graddiv)) &
           graddiv(:,:)=d2A(:,1,:,1)+d2A(:,2,:,2)+d2A(:,3,:,3)
!
      if (present(del2)) &
           del2(:,:)=d2A(:,1,1,:)+d2A(:,2,2,:)+d2A(:,3,3,:)
!
    endsubroutine gij_etc
!***********************************************************************
    subroutine g2ij(f,k,g)
!
!  calculates the Hessian, i.e. all second derivatives of a scalar
!
!  11-jul-02/axel: coded
!
      use Deriv, only: der2,derij
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx,3,3) :: g
      real, dimension (nx) :: tmp
      integer :: i,j,k
!
      intent(in) :: f,k
      intent(out) :: g
!
!  run though all 9 possibilities, treat diagonals separately
!
      do j=1,3
        call der2 (f,k,tmp,j); g(:,j,j)=tmp
        do i=j+1,3
          call derij(f,k,tmp,i,j); g(:,i,j)=tmp; g(:,j,i)=tmp
        enddo
      enddo
!
    endsubroutine g2ij
!*************************************************************************
    subroutine u_dot_grad_vec(k,gradf,uu,ugradf)
!
!  u.gradu
!
      intent(in) :: k,gradf,uu
      intent(out) :: ugradf
!
      real, dimension (nx,3,3) :: gradf
      real, dimension (nx,3) :: uu,ugradf
      real, dimension (nx) :: tmp
      integer :: j,k
!
      if (k<1 .or. k>mfarray) then
        call fatal_error('u_dot_grad_vec','variable index is out of bounds')
        return
      endif
!
      do j=1,3
        call u_dot_grad_scl(k+j-1,gradf(:,j,:),uu,tmp)
        ugradf(:,j)=tmp
      enddo
!
    endsubroutine u_dot_grad_vec
!***********************************************************************
    subroutine u_dot_grad_mat(f,k,gradM,u_dot_gradM)
!
!  u.grad(M)
! where M is a second rank matrix
!
!  dhruba: addapted from udotgradA
!
      intent(in) :: f,k,gradM
      intent(out) :: u_dot_gradM
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (nx,3,3,3) :: gradM
      real,dimension(nx,3) :: uu
      real, dimension (nx,3,3) :: u_dot_gradM
      integer :: k
!
!  upwind
!
      uu=f(l1:l2,m,n,k:k+2)
      call vec_dot_3tensor(uu,gradM,u_dot_gradM)
!
    endsubroutine u_dot_grad_mat
!***********************************************************************
    subroutine u_dot_grad_scl(k,gradf,uu,ugradf)
!
!  Do advection-type term u.grad f_k.
!  Assumes gradf to be known, but takes f and k as arguments to be able
!  to calculate upwind correction
!
      intent(in) :: k,gradf,uu
      intent(out) :: ugradf
!
      real, dimension (nx,3) :: uu,gradf
      real, dimension (nx) :: ugradf
      integer :: k
!
      if (k<1 .or. k>mfarray) then
        call fatal_error('u_dot_grad_scl','variable index is out of bounds')
        return
      endif
!
      call dot_mn(uu,gradf,ugradf)
!
    endsubroutine u_dot_grad_scl
!***********************************************************************
    subroutine h_dot_grad_vec(hh,gradf,hgradf)
!
!  h.gradf for vectors h and f
!
!  23-mar-08/axel: adapted from u_dot_grad_vec
!
      intent(in) :: hh,gradf
      intent(out) :: hgradf
!
      real, dimension (nx,3,3) :: gradf
      real, dimension (nx,3) :: hh,hgradf
      real, dimension (nx) :: tmp
      integer :: j
!
!  dot product for each of the three components of gradf
!
      do j=1,3
        call h_dot_grad_scl(hh,gradf(:,j,:),tmp)
        hgradf(:,j)=tmp
      enddo
!
    endsubroutine h_dot_grad_vec
!***********************************************************************
    subroutine h_dot_grad_scl(hh,gradf,hgradf)
!
!  Do advection-type term h.grad f_k, but h is not taken from f array
!
!  23-mar-08/axel: adapted from u_dot_grad_scl
!
      intent(in) :: hh,gradf
      intent(out) :: hgradf
!
      real, dimension (nx,3) :: hh,gradf
      real, dimension (nx) :: hgradf
!
      call dot_mn(hh,gradf,hgradf)
!
    endsubroutine h_dot_grad_scl
!***********************************************************************
    subroutine inpup(file,a,nv)
!
!  read particle snapshot file
!  11-apr-00/axel: adapted from input
!
      integer :: nv
      real, dimension (nv) :: a
      character (len=*) :: file
!
      open(1,file=file,form='unformatted')
      read(1) a
      close(1)
    endsubroutine inpup
!***********************************************************************
    subroutine inpui(file,a,nv)
!
!  read data (random seed, etc.) from file
!  11-apr-00/axel: adapted from input
!
      integer :: nv,iostat
      integer, dimension (nv) :: a
      character (len=*) :: file
!
      open(1,file=file,form='formatted')
      read(1,*,IOSTAT=iostat) a
      close(1)
!
      if (iostat /= 0) then
        if (lroot) &
             print*, "Error encountered reading ", &
                     size(a), "integers from ", trim(file)
        call fatal_error('inpui','')
      endif
    endsubroutine inpui
!***********************************************************************
    subroutine inpuf(file,a,nv)
!
!  read formatted snapshot
!   5-aug-98/axel: coded
!
      integer :: nv
      real, dimension (mx,my,mz,nv) :: a
      character (len=*) :: file
      real :: t_sp   ! t in single precision for backwards compatibility
!
      open(1,file=file)
      read(1,10) a
      read(1,10) t_sp,x,y,z
      t = t_sp
      close(1)
10    format(8e10.3)
!
    endsubroutine inpuf
!***********************************************************************
    subroutine outpup(file,a,nv)
!
!  write snapshot file, always write mesh and time, could add other things
!  11-apr-00/axel: adapted from output
!
      integer :: nv
      real, dimension (nv) :: a
      character (len=*) :: file
!
      open(1,file=file,form='unformatted')
      write(1) a
      close(1)
!
    endsubroutine outpup
!***********************************************************************
    subroutine outpui(file,a,nv)
!
!  write snapshot file, always write mesh and time, could add other things
!  11-apr-00/axel: adapted from output
!
      integer :: nv
      integer, dimension (nv) :: a
      character (len=*) :: file
!
      open(1,file=file,form='formatted')
      write(1,*) a
      close(1)
!
    endsubroutine outpui
!***********************************************************************
    subroutine outpuf(file,a,nv)
!
!  write formatted snapshot, otherwise like output
!   5-aug-98/axel: coded
!
      integer :: nv
      character (len=*) :: file
      real, dimension (mx,my,mz,nv) :: a
      real :: t_sp   ! t in single precision for backwards compatibility
!
      t_sp = t
      open(1,file=file)
      write(1,10) a
      write(1,10) t_sp,x,y,z
      close(1)
10    format(8e10.3)
!
    endsubroutine outpuf
!***********************************************************************
    character function numeric_precision()
!
!  return 'S' if running in single, 'D' if running in double precsision
!
!  12-jul-06/wolf: extracted from wdim()
!
      integer :: real_prec
!
      real_prec = precision(1.)
      if (real_prec==6 .or. real_prec==7) then
        numeric_precision = 'S'
      elseif (real_prec == 15) then
        numeric_precision = 'D'
      else
        print*, 'WARNING: encountered unknown precision ', real_prec
        numeric_precision = '?'
      endif
!
    endfunction numeric_precision
!***********************************************************************
    subroutine wdim(file,mxout,myout,mzout)
!
!  write dimension to file
!
!   8-sep-01/axel: adapted to take myout,mzout
!
      character (len=*) :: file
      character         :: prec
      integer, optional :: mxout,myout,mzout
      integer           :: mxout1,myout1,mzout1,iprocz_slowest=0
!
!  determine whether mxout=mx (as on each processor)
!  or whether mxout is different (eg when writing out full array)
!
      if (present(mzout)) then
        mxout1=mxout
        myout1=myout
        mzout1=mzout
      elseif (lmonolithic_io) then
        mxout1=nxgrid+2*nghost
        myout1=nygrid+2*nghost
        mzout1=nzgrid+2*nghost
      else
        mxout1=mx
        myout1=my
        mzout1=mz
      endif
!
!  only root writes allprocs/dim.dat (with io_mpio.f90),
!  but everybody writes to their procN/dim.dat (with io_dist.f90)
!
      if (lroot .or. .not. lmonolithic_io) then
        open(1,file=file)
        write(1,'(3i7,3i5)') mxout1,myout1,mzout1,mvar,maux,mglobal
!
!  check for double precision
!
        prec = numeric_precision()
        write(1,'(a)') prec
!
!  write number of ghost cells (could be different in x, y and z)
!
        write(1,'(3i5)') nghost, nghost, nghost
        if (present(mzout)) then
          if (lprocz_slowest) iprocz_slowest=1
          write(1,'(4i5)') nprocx, nprocy, nprocz, iprocz_slowest
        else
          write(1,'(3i5)') ipx, ipy, ipz
        endif
        !
        close(1)
      endif
!
      endsubroutine wdim
!***********************************************************************
      subroutine rdim(file,mx_in,my_in,mz_in,mvar_in,maux_in,mglobal_in,&
          prec_in,nghost_in,ipx_in, ipy_in, ipz_in)
!
!  write dimension to file
!
!   15-sep-09/nils: adapted from rdim
!
      character (len=*) :: file
      character         :: prec_in
      integer           :: mx_in,my_in,mz_in
      integer           :: mvar_in,maux_in,mglobal_in,nghost_in
      integer           :: ipx_in, ipy_in, ipz_in
!
!  Every processor writes to their procN/dim.dat (with io_dist.f90)
!
      open(124,file=file,FORM='formatted')
      read(124,*) mx_in,my_in,mz_in,mvar_in,maux_in,mglobal_in
      read(124,*) prec_in
      read(124,*) nghost_in, nghost_in, nghost_in
      read(124,*) ipx_in, ipy_in, ipz_in
!
      close(124)
!
      endsubroutine rdim
!***********************************************************************
    subroutine read_snaptime(file,tout,nout,dtout,t)
!
    use Mpicomm, only: mpibcast_real
!
!  Read in output time for next snapshot (or similar) from control file
!
!  30-sep-97/axel: coded
!  24-aug-99/axel: allow for logarithmic spacing
!   9-sep-01/axel: adapted for MPI
!
      character (len=*) :: file
      integer :: nout
      real :: tout,dtout
      double precision :: t
      intent(in)  :: file, dtout, t
      intent(out) :: tout, nout
      integer :: lun
      integer, parameter :: nbcast_array=2
      real, dimension(nbcast_array) :: bcast_array
      logical :: exist
!
!  depending on whether or not file exists, we need to
!  either read or write tout and nout from or to the file
!
      if (lroot) then
        inquire(FILE=trim(file),EXIST=exist)
        lun=1
        open(lun,FILE=trim(file))
        if (exist) then
          read(lun,*) tout,nout
        else
!
!  special treatment when dtout is negative
!  now tout and nout refer to the next snapshopt to be written
!
          if (dtout < 0.) then
            tout=log10(t)
          else
            !  make sure the tout is a good time
            if (dtout /= 0.) then
              tout = t - mod(t, dble(abs(dtout))) + dtout
            else
              call warning("read_snaptime", &
                  "Am I writing snapshots every 0 time units? (check " // &
                  trim(file) // ")" )
              tout = t
            endif
          endif
          nout=1
          write(lun,*) tout,nout
        endif
        close(lun)
        bcast_array(1)=tout
        bcast_array(2)=nout
      endif
!
!  broadcast tout and nout, botch into floating point array. Should be
!  done with a special MPI datatype.
!
      call mpibcast_real(bcast_array,nbcast_array)
      tout=bcast_array(1)
      nout=bcast_array(2)
!
    endsubroutine read_snaptime
!***********************************************************************
    subroutine update_snaptime(file,tout,nout,dtout,t,lout,ch,enum)
!
!  Check whether we need to write snapshot; if so, update the snapshot
!  file (e.g. tsnap.dat). Done by all processors.
!
!  30-sep-97/axel: coded
!  24-aug-99/axel: allow for logarithmic spacing
!
      use General, only: chn
!
      character (len=*) :: file
      character (len=5) :: ch
      logical :: lout,enum
      double precision :: t
      real :: t_sp   ! t in single precision for backwards compatibility
      real :: tout,dtout
      integer :: lun,nout
!
!  Use t_sp as a shorthand for either t or lg(t).
!
      if (dtout<0.0) then
        t_sp=log10(t)
      else
        t_sp=t
      endif
!
!  If enum=.false. we don't want to generate a running file number (eg in wvid).
!  If enum=.true. we do want to generate character from nout for file name do
!  this before nout has been updated to new value.
!
      if (enum) call chn(nout,ch,'update_snaptime: '//trim(file))
!
!  Mark lout=.true. when time has exceeded the value of tout do while loop to
!  make make sure tt is always larger than tout.
!  (otherwise slices are written just to catch up with tt.)
!
      if (t_sp >= tout) then
        tout=tout+abs(dtout)
        nout=nout+1
        lout=.true.
!
!  Write corresponding value of tout to file to make sure we have it, in case
!  the code craches. If the disk is full, however, we need to reset the values
!  manually.
!
        if (lroot) then
          lun=1
          open(lun,FILE=trim(file))
          write(lun,*) tout,nout
          write(lun,*) 'This file is written automatically (routine'
          write(lun,*) 'check_snaptime in sub.f90). The values above give'
          write(lun,*) 'time and number of the *next* snapshot. These values'
          write(lun,*) 'are only read once in the beginning. You may adapt'
          write(lun,*) 'them by hand (eg after a crash).'
          close(lun)
        endif
      else
        lout=.false.
      endif
!
    endsubroutine update_snaptime
!***********************************************************************
    subroutine vecout(lun,file,vv,thresh,nvec)
!
!  write vectors to disc if their length exceeds thresh
!
!  22-jul-03/axel: coded
!
      character (len=*) :: file
      real, dimension(nx,3) :: vv
      real, dimension(nx) :: v2
      real :: thresh,thresh2,dummy=0.
      integer :: l,lun,nvec
      real :: t_sp   ! t in single precision for backwards compatibility
!
      t_sp = t
!
!  return if thresh=0 (default)
!
      if (thresh==0.) return
!
!  open files when first data point
!
      if (lfirstpoint) then
        open(lun,FILE=trim(file)//'.dat',form='unformatted',position='append')
        write(lun) 0,0,0,t_sp,dummy,dummy  !(marking first line)
        nvec=0
      endif
!
!  write data
!
      thresh2=thresh**2
      v2=vv(:,1)**2+vv(:,2)**2+vv(:,3)**2
      do l=1,nx
        if (v2(l)>=thresh2) then
          write(lun) l,m-nghost,n-nghost,vv(l,:)
          nvec=nvec+1
        endif
      enddo
!
!  close file, and write number of vectors to a separate file
!
      if (llastpoint) then
        close(lun)
        open(lun,FILE=trim(file)//'.num',position='append')
        write(lun,*) t_sp,nvec
        close(lun)
      endif
!
    endsubroutine vecout
!***********************************************************************
    subroutine despike(f,j,retval,factor)
!
!  Remove large spikes from
!  14-aug-06/tony: coded
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension(nx) :: retval
      real, dimension (mx) :: tmp_penc
      real, dimension (mx) :: meanf
      real :: factor
      real, parameter :: t1 = 1./26.
      real, parameter :: t2 = 0.70710678/26.
      real, parameter :: t3 = 0.57735027/26.
      real, parameter :: t4 = 0.
      real, parameter, dimension (-1:1,-1:1,-1:1) :: interp3D = reshape(&
            (/ t3, t2, t3, &
               t2, t1, t2, &
               t3, t2, t3, &
               t2, t1, t2, &
               t1, t4, t1, &
               t2, t1, t2, &
               t3, t2, t3, &
               t2, t1, t2, &
               t3, t2, t3 /),&
            (/ 3,3,3 /))
      integer :: ii,jj,kk
      integer :: j

      meanf=0.
      if ((nxgrid/=1).and.(nygrid/=1).and.(nzgrid/=1)) then
        tmp_penc=f(:,m,n,j)
        do kk=-1,1
        do jj=-1,1
        do ii=-1,1
          if (ii/=0.or.jj/=0.or.kk/=0) &
          meanf(3:mx-2)=meanf(3:mx-2)+interp3D(ii,jj,kk)*(f(3+ii:mx-2+ii,m+jj,n+kk,j)-tmp_penc(3:mx-2))
        enddo
        enddo
        enddo
      else
        call fatal_error('shock_max3_pencil_interp', &
            'Tony got lazy and only implemented the 3D case')
      endif
!
!      factor1=1./factor
      retval=max(meanf(l1:l2)*factor,f(l1:l2,m,n,j))
!      retval=max(meanf(l1:l2)*factor,retval)
!
    endsubroutine despike
!***********************************************************************
    subroutine smooth_kernel(f,j,smth)
!
!  Smooth scalar field FF using predefined constant gaussian like kernel
!  20-jul-06/tony: coded
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension(nx) :: smth
      integer :: j,l
!
      do l=l1,l2
        smth(l-l1+1)=sum(smth_kernel*f(l-3:l+3,m-3:m+3,n-3:n+3,j))
      enddo
!
    endsubroutine smooth_kernel
!***********************************************************************
    subroutine identify_bcs(varname_input,idx)
!
!  print boundary conditions for scalar field
!
!  19-jul-02/wolf: coded
!  29-may-04/axel: allowed variable name to be 8 chars long
!
      character (len=*) :: varname_input
      integer :: idx
!
      write(*,'(A,A10,",  x: <",A8,">, y: <",A8,">,  z: <",A8,">")') &
           'Bcs for ', varname_input, &
           trim(bcx(idx)), trim(bcy(idx)), trim(bcz(idx))
!
    endsubroutine identify_bcs
!***********************************************************************
    function noform(cname)
!
!  Given a string of the form `name(format)',
!  returns the name without format, fills empty space
!  of correct length (depending on format) with dashes
!  for output as legend.dat and first line of time_series.dat
!
!  22-jun-02/axel: coded
!
      integer, parameter :: max_col_width=30
      character (len=*) :: cname
      character (len=max_col_width) :: noform,cform,cnumber,dashes
      integer :: index_e,index_f,index_g,index_i,index_d,index_r,index1,index2
      integer :: iform0,iform1,iform2,length,number,number1,number2
!
      intent(in)  :: cname
!
!  fill DASHES with, well, dashes
!
      dashes = repeat('-', max_col_width)
!
!  find position of left bracket to isolate format, cform
!
      iform0=index(cname,' ')
      iform1=index(cname,'(')
      iform2=index(cname,')')
!
!  set format; use default if not given
!  Here we keep the parenthesis in cform
!
      if (iform1>0) then
        cform=cname(iform1:iform2)
        length=iform1-1
      else
        cform='(1p,e10.2,0p)'
        length=iform0-1
      endif
!
!  find length of formatted expression, examples: f10.2, e10.3, g12.1
!  index_1 is the position of the format type (f,e,g), and
!  index_d is the position of the dot
!
      index_e=scan(cform,'eE')
      index_f=scan(cform,'fF')
      index_g=scan(cform,'gG')
      index_i=scan(cform,'iI')
      index_d=index(cform,'.')
      index_r=index(cform,')')
      index1=max(index_e,index_f,index_g,index_i)
      index2=index_d; if (index_d==0) index2=index_r
!
!  calculate the length of the format and assemble expression for legend
!
      cnumber=cform(index1+1:index2-1)
      read(cnumber,'(i4)',err=99) number
10    number1=max(0,(number-length)/2)
      number2=max(1,number-length-number1) ! at least one separating dash
!
!  sanity check
!
      if (number1+length+number2 > max_col_width) then
        call error("noform", &
                   "Increase max_col_width or sanitize print.in{,.double}")
      endif

      noform=dashes(1:number1)//cname(1:length)//dashes(1:number2)
      return
!
! in case of errors:
!
99    print*,'noform: formatting problem'
      print*,'problematic cnumber= <',cnumber,'>'
      number=10
      goto 10
!
    endfunction noform
!***********************************************************************
    function levi_civita(i,j,k)
!
!  totally antisymmetric tensor
!
!  20-jul-03/axel: coded
!
      real :: levi_civita
      integer :: i,j,k
!
      if ( &
        (i==1 .and. j==2 .and. k==3) .or. &
        (i==2 .and. j==3 .and. k==1) .or. &
        (i==3 .and. j==1 .and. k==2) ) then
        levi_civita=1.
      elseif ( &
        (i==3 .and. j==2 .and. k==1) .or. &
        (i==1 .and. j==3 .and. k==2) .or. &
        (i==2 .and. j==1 .and. k==3) ) then
        levi_civita=-1.
      else
        levi_civita=0.
      endif

    endfunction levi_civita
!***********************************************************************
    function poly_1(coef, x)
!
!  Horner's scheme for polynomial evaluation.
!  Version for 1d array.
!  17-jan-02/wolf: coded
!
      real, dimension(:) :: coef
      real, dimension(:) :: x
      real, dimension(size(x,1)) :: poly_1
      integer :: Ncoef,i

      Ncoef = size(coef,1)

      poly_1 = coef(Ncoef)
      do i=Ncoef-1,1,-1
        poly_1 = poly_1*x+coef(i)
      enddo

    endfunction poly_1
!***********************************************************************
    function poly_0(coef, x)
!
!  Horner's scheme for polynomial evaluation.
!  Version for scalar.
!  17-jan-02/wolf: coded
!
      real, dimension(:) :: coef
      real :: x
      real :: poly_0
      integer :: Ncoef,i

      Ncoef = size(coef,1)

      poly_0 = coef(Ncoef)
      do i=Ncoef-1,1,-1
        poly_0 = poly_0*x+coef(i)
      enddo

    endfunction poly_0
!***********************************************************************
    function poly_3(coef, x)
!
!  Horner's scheme for polynomial evaluation.
!  Version for 3d array.
!  17-jan-02/wolf: coded
!
      real, dimension(:) :: coef
      real, dimension(:,:,:) :: x
      real, dimension(size(x,1),size(x,2),size(x,3)) :: poly_3
      integer :: Ncoef,i

      Ncoef = size(coef,1)

      poly_3 = coef(Ncoef)
      do i=Ncoef-1,1,-1
        poly_3 = poly_3*x+coef(i)
      enddo

    endfunction poly_3
!***********************************************************************
    function step_scalar(x,x0,width)
!
!  Smooth unit step function centred at x0; implemented as tanh profile
!  05 sept 2008/dhruba : copied from step
!
      real :: x
      real :: step_scalar
      real :: x0,width
      step_scalar = 0.5*(1+tanh((x-x0)/(width+tini)))
!
    endfunction step_scalar
!***********************************************************************
    function step(x,x0,width)
!
!  Smooth unit step function centred at x0; implemented as tanh profile
!  23-jan-02/wolf: coded
!
      real, dimension(:) :: x
      real, dimension(size(x,1)) :: step
      real :: x0,width
      step = 0.5*(1+tanh((x-x0)/(width+tini)))
!
    endfunction step
!***********************************************************************
    function der_step(x,x0,width)
!
!  Derivative of smooth unit STEP() function given above (i.e. a bump profile).
!  Adapt this if you change the STEP() profile, or you will run into
!  inconsistenies.
!
!  23-jan-02/wolf: coded
!
      real, dimension(:) :: x
      real, dimension(size(x,1)) :: der_step,arg
      real :: x0,width
!
!  Some argument gymnastics to avoid `floating overflow' for large
!  arguments
!
      arg = abs((x-x0)/(width+tini))
      arg = min(arg,8.)         ! cosh^2(8) = 3e+27
      der_step = 0.5/(width*cosh(arg)**2)
!
      endfunction der_step
!***********************************************************************
    function der6_step(x,x0,width)
!
!  6th order derivative of smooth unit STEP() function given
!   above (i.e. a bump profile).
!  Adapt this if you change the STEP() profile, or you will run into
!  inconsistenies.
!
!  08-dec-09/dhruba: aped from der_step
!
      real, dimension(:) :: x
      real, dimension(size(x,1)) :: der6_step,arg,sechx,tanhx
      real :: x0,width
!
!  Some argument gymnastics to avoid `floating overflow' for large
!  arguments
!
      arg = abs((x-x0)/(width+tini))
      tanhx=tanh(arg)
      arg = min(arg,8.)         ! cosh^2(8) = 3e+27
      sechx=1./cosh(arg)
      der6_step = (1./(2*width**6))*(&
             -272.0*(sechx**6)*tanhx+416.0*(sechx**4)*(tanhx**3) &
             -32.0*(sechx**2)*(tanhx**5) )
!
      endfunction der6_step
!***********************************************************************
    function stepdown(x,x0,width)
!
!  Smooth unit step function centred at x0; implemented as tanh profile
!  23-jan-02/wolf: coded
!
      real, dimension(:) :: x
      real, dimension(size(x,1)) :: stepdown
      real :: x0,width
      stepdown = -0.5*(1+tanh((x-x0)/(width+tini)))
!
    endfunction stepdown
!***********************************************************************
      function cubic_step_pt(x,x0,width,shift)
!
!  Smooth unit step function with cubic (smooth) transition over [x0-w,x0+w].
!  Optional argument SHIFT shifts center:
!  for shift=1. the interval is [x0    ,x0+2*w],
!  for shift=-1. it is          [x0-2*w,x0    ].
!  This is to make sure the interior region is not affected.
!  Maximum slope is 3/2=1.5 times that of a linear profile.
!
!  This version is for scalar args.
!
!  18-apr-04/wolf: coded
!
        real :: x
        real :: cubic_step_pt,xi
        real :: x0,width
        real, optional :: shift
        real :: relshift
!
        if (present(shift)) then; relshift=shift; else; relshift=0.; endif
        xi = (x-x0)/(width+tini) - relshift
        xi = max(xi,-1.)
        xi = min(xi, 1.)
        cubic_step_pt = 0.5 + xi*(0.75-xi**2*0.25)
!
      endfunction cubic_step_pt
!***********************************************************************
      function cubic_step_mn(x,x0,width,shift)
!
!  Smooth unit step function with cubic (smooth) transition over [x0-w,x0+w].
!  Version for 1d arg (in particular pencils).
!
!  18-apr-04/wolf: coded
!
        real, dimension(:) :: x
        real, dimension(size(x,1)) :: cubic_step_mn,xi
        real :: x0,width
        real, optional :: shift
        real :: relshift
!
        if (present(shift)) then; relshift=shift; else; relshift=0.; endif
        xi = (x-x0)/(width+tini) - relshift
        xi = max(xi,-1.)
        xi = min(xi, 1.)
        cubic_step_mn = 0.5 + xi*(0.75-xi**2*0.25)
!
      endfunction cubic_step_mn
!***********************************************************************
      function cubic_der_step_pt(x,x0,width,shift)
!
!  Derivative of smooth unit step function, localized to [x0-w,x0+w].
!  This version is for scalar args.
!
!  12-jul-05/axel: adapted from cubic_step_pt
!
        real :: x
        real :: cubic_der_step_pt,xi
        real :: x0,width
        real, optional :: shift
        real :: relshift,width1
!
        if (present(shift)) then; relshift=shift; else; relshift=0.; endif
        width1 = 1./(width+tini)
        xi = (x-x0)*width1 - relshift
        xi = max(xi,-1.)
        xi = min(xi, 1.)
        cubic_der_step_pt = (0.75-xi**2*0.75) * width1
!
      endfunction cubic_der_step_pt
!***********************************************************************
      function cubic_der_step_mn(x,x0,width,shift)
!
!  Derivative of smooth unit step function, localized to [x0-w,x0+w].
!  Version for 1d arg (in particular pencils).
!
!  12-jul-05/axel: adapted from cubic_step_mn
!
        real, dimension(:) :: x
        real, dimension(size(x,1)) :: cubic_der_step_mn,xi
        real :: x0,width
        real, optional :: shift
        real :: relshift,width1
!
        if (present(shift)) then; relshift=shift; else; relshift=0.; endif
        width1 = 1./(width+tini)
        xi = (x-x0)*width1 - relshift
        xi = max(xi,-1.)
        xi = min(xi, 1.)
        cubic_der_step_mn = (0.75-xi**2*0.75) * width1
!
      endfunction cubic_der_step_mn
!***********************************************************************
      function quintic_step_pt(x,x0,width,shift)
!
!  Smooth unit step function with quintic (smooth) transition over [x0-w,x0+w].
!  Optional argument SHIFT shifts center:
!  for shift=1. the interval is [x0    ,x0+2*w],
!  for shift=-1. it is          [x0-2*w,x0    ].
!  Maximum slope is 15/8=1.875 times that of a linear profile.
!
!  This version is for scalar args.
!
!  09-aug-05/wolf: coded
!
        real :: x
        real :: quintic_step_pt,xi
        real :: x0,width
        real, optional :: shift
        real :: relshift
!
        if (present(shift)) then; relshift=shift; else; relshift=0.; endif
        xi = (x-x0)/(width+tini) - relshift
        xi = max(xi,-1.)
        xi = min(xi, 1.)
        quintic_step_pt = 0.5 + xi*(0.9375 + xi**2*(-0.625 + xi**2*0.1875))
!
      endfunction quintic_step_pt
!***********************************************************************
      function quintic_step_mn(x,x0,width,shift)
!
!  Smooth unit step function with quintic (smooth) transition over [x0-w,x0+w].
!
!  Version for 1d arg (in particular pencils).
!
!  09-aug-05/wolf: coded
!
        real, dimension(:) :: x
        real, dimension(size(x,1)) :: quintic_step_mn,xi
        real :: x0,width
        real, optional :: shift
        real :: relshift
!
        if (present(shift)) then; relshift=shift; else; relshift=0.; endif
        xi = (x-x0)/(width+tini) - relshift
        xi = max(xi,-1.)
        xi = min(xi, 1.)
        quintic_step_mn = 0.5 + xi*(0.9375 + xi**2*(-0.625 + xi**2*0.1875))
!
      endfunction quintic_step_mn
!***********************************************************************
      function quintic_der_step_pt(x,x0,width,shift)
!
!  Derivative of smooth unit step function, localized to [x0-w,x0+w].
!
!  This version is for scalar args.
!
!  09-aug-05/wolf: coded
!
        real :: x
        real :: quintic_der_step_pt,xi
        real :: x0,width
        real, optional :: shift
        real :: relshift,width1
!
        if (present(shift)) then; relshift=shift; else; relshift=0.; endif
        width1 = 1./(width+tini)
        xi = (x-x0)*width1 - relshift
        xi = max(xi,-1.)
        xi = min(xi, 1.)
        quintic_der_step_pt = (0.9375 + xi**2*(-1.875 + xi**2*0.9375)) &
                              * width1
!
      endfunction quintic_der_step_pt
!***********************************************************************
      function quintic_der_step_mn(x,x0,width,shift)
!
!  Derivative of smooth unit step function, localized to [x0-w,x0+w].
!
!  Version for 1d arg (in particular pencils).
!
!  09-aug-05/wolf: coded
!
        real, dimension(:) :: x
        real, dimension(size(x,1)) :: quintic_der_step_mn,xi
        real :: x0,width
        real, optional :: shift
        real :: relshift,width1
!
        if (present(shift)) then; relshift=shift; else; relshift=0.; endif
        width1 = 1./(width+tini)
        xi = (x-x0)*width1 - relshift
        xi = max(xi,-1.)
        xi = min(xi, 1.)
        quintic_der_step_mn = (0.9375 + xi**2*(-1.875 + xi**2*0.9375)) &
                              * width1
!
      endfunction quintic_der_step_mn
!***********************************************************************
      function sine_step_pt(x,x0,width,shift)
!
!  Smooth unit step function with sine (smooth) transition over [x0-w,x0+w].
!  Optional argument SHIFT shifts center:
!  for shift=1. the interval is [x0    ,x0+2*w],
!  for shift=-1. it is          [x0-2*w,x0    ].
!  Maximum slope is 15/8=1.875 times that of a linear profile.
!
!  This version is for scalar args.
!
!  13-jun-06/tobi: Adapted from cubic_step
!
        real :: x
        real :: sine_step_pt,xi
        real :: x0,width
        real, optional :: shift
        real :: relshift
!
        if (present(shift)) then; relshift=shift; else; relshift=0.; endif
        xi = (x-x0)/(width+tini) - relshift
        xi = max(xi,-1.)
        xi = min(xi, 1.)
        sine_step_pt = 0.5*(1+sin(0.5*pi*xi))
!
      endfunction sine_step_pt
!***********************************************************************
      function sine_step_mn(x,x0,width,shift)
!
!  Smooth unit step function with sine (smooth) transition over [x0-w,x0+w].
!
!  Version for 1d arg (in particular pencils).
!
!  13-jun-06/tobi: Adapted from cubic_step
!
        real, dimension(:) :: x
        real, dimension(size(x,1)) :: sine_step_mn,xi
        real :: x0,width
        real, optional :: shift
        real :: relshift
!
        if (present(shift)) then; relshift=shift; else; relshift=0.; endif
        xi = (x-x0)/(width+tini) - relshift
        xi = max(xi,-1.)
        xi = min(xi, 1.)
        sine_step_mn = 0.5*(1+sin(0.5*pi*xi))
!
      endfunction sine_step_mn
!***********************************************************************
      function notanumber_0(f)
!
!  Check for denormalised floats (in fact NaN or -Inf, Inf).
!  The test used here should work on all architectures even if
!  optimisation is high (something like `if (any(f /= f+1))' would be
!  optimised away).
!  Version for scalars
!  20-Nov-03/tobi: adapted
!
        logical :: notanumber_0
        real :: f,g
!
        g=f
        notanumber_0 = &
             ( (f /= g) .or. (f == g-sign(1.0,g)*float(radix(g))**exponent(g)) )
!
      endfunction notanumber_0
!***********************************************************************
      function notanumber_1(f)
!
!  Check for denormalised floats (in fact NaN or -Inf, Inf).
!  The test used here should work on all architectures even if
!  optimisation is high (something like `if (any(f /= f+1))' would be
!  optimised away).
!  Version for 1d arrays.
!  24-jan-02/wolf: coded
!
        logical :: notanumber_1
        real, dimension(:) :: f
        real, dimension(size(f,1)) :: g
!
        g=f
        notanumber_1 = any&
             ( (f /= g) .or. (f == g-sign(1.0,g)*float(radix(g))**exponent(g)) )
!
      endfunction notanumber_1
!***********************************************************************
      function notanumber_2(f)
!
!  Check for denormalised floats (in fact NaN or -Inf, Inf).
!  The test used here should work on all architectures even if
!  optimisation is high (something like `if (any(f /= f+1))' would be
!  optimised away).
!  Version for 2d arrays.
!
!  1-may-02/wolf: coded
!
        logical :: notanumber_2
        real, dimension(:,:) :: f
        real, dimension(size(f,1),size(f,2)) :: g
!
        g=f
        notanumber_2 = any&
             ( (f /= g) .or. (f == g-sign(1.0,g)*float(radix(g))**exponent(g)) )
!
      endfunction notanumber_2
!***********************************************************************
      function notanumber_3(f)
!
!  Check for denormalised floats (in fact NaN or -Inf, Inf).
!  The test used here should work on all architectures even if
!  optimisation is high (something like `if (any(f /= f+1))' would be
!  optimised away).
!  Version for 3d arrays.
!
!  24-jan-02/wolf: coded
!
        logical :: notanumber_3
        real, dimension(:,:,:) :: f
        real, dimension(size(f,1),size(f,2),size(f,3)) :: g
!
        g=f
        notanumber_3 = any&
             ( (f /= g) .or. (f == g-sign(1.0,g)*float(radix(g))**exponent(g)) )
!
      endfunction notanumber_3
!***********************************************************************
      function notanumber_4(f)
!
!  Check for denormalised floats (in fact NaN or -Inf, Inf).
!  The test used here should work on all architectures even if
!  optimisation is high (something like `if (any(f /= f+1))' would be
!  optimised away).
!  Version for 4d arrays.
!
!  24-jan-02/wolf: coded
!
        logical :: notanumber_4
        real, dimension(:,:,:,:) :: f
        real, dimension(size(f,1),size(f,2),size(f,3),size(f,4)) :: g
!
        g=f
        notanumber_4 = any&
             ( (f /= g) .or. (f == g-sign(1.0,g)*float(radix(g))**exponent(g)) )
!
      endfunction notanumber_4
!***********************************************************************
      subroutine nan_inform(f,msg,region,int1,int2,int3,int4,lstop)
!
!  Check input array (f or df) for NaN, -Inf, Inf, and output location in
!  array.
!
!  30-apr-04/anders: coded
!  12-jun-04/anders: region or intervals supplied in call
!
        real, dimension(:,:,:,:) :: f
        character (len=*) :: msg
        integer :: a,b,c,d,a1=1,a2=mx,b1=1,b2=my,c1=1,c2=mz,d1=1,d2=1
        integer, dimension(2), optional :: int1,int2,int3,int4
        character (len=*), optional :: region
        logical, optional :: lstop
!
!  Must set d2 according to whether f or df is considered
!
        d2 = size(f,4)
!
!  Set intervals for different predescribed regions
!
        if (present(region)) then

          select case (region)
            case ('f_array')
            case ('pencil')
              b1=m
              b2=m
              c1=n
              c2=n
            case ('default')
              call fatal_error('nan_inform','No such region')
          endselect

        endif
!
!  Overwrite with supplied intervals
!
        if (present(int1)) then  ! x
          a1=int1(1)
          a2=int1(2)
        endif

        if (present(int2)) then  ! y
          b1=int2(1)
          b2=int2(2)
        endif

        if (present(int3)) then  ! z
          c1=int3(1)
          c2=int3(2)
        endif

        if (present(int4)) then  ! variable
          d1=int4(1)
          d2=int4(2)
        endif
!
!  Look for NaN and inf in resulting interval
!
        do a=a1,a2
          do b=b1,b2
            do c=c1,c2
              do d=d1,d2
                if (notanumber(f(a,b,c,d))) then
                  print*,'nan_inform: NaN with message "', msg, &
                      '" encountered in the variable ', varname(d)
                  print*,'nan_inform: ', varname(d), ' = ', f(a,b,c,d)
                  print*,'nan_inform: t, it, itsub   = ', t, it, itsub
                  print*,'nan_inform: l, m, n, iproc = ', a, b, c, iproc
                  print*,'----------------------------'
                  if (present(lstop)) then
                    if (lstop) call fatal_error('nan_stop','')
                  endif
                endif
              enddo
            enddo
          enddo
        enddo
!
      endsubroutine nan_inform
!***********************************************************************
      subroutine keep_compiler_quiet_r(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        real     :: v1, v2, v3, v4
        optional ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_r', &
              'The world is a disk, and we never got here...')
          print*,                  v1
          if (present(v2)) print*, v2
          if (present(v3)) print*, v3
          if (present(v4)) print*, v4
        endif
!
      endsubroutine keep_compiler_quiet_r
!***********************************************************************
      subroutine keep_compiler_quiet_r1d(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        real, dimension(:) :: v1, v2, v3, v4
        optional           ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_r1d', &
              '91 is a prime, and we never got here...')
          print*,                  minval(v1)
          if (present(v2)) print*, minval(v2)
          if (present(v3)) print*, minval(v3)
          if (present(v4)) print*, minval(v4)
        endif
!
      endsubroutine keep_compiler_quiet_r1d
!***********************************************************************
      subroutine keep_compiler_quiet_r2d(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        real, dimension(:,:) :: v1, v2, v3, v4
        optional             ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_r2d', &
              '91 is a prime, and we never got here...')
          print*,                  minval(v1)
          if (present(v2)) print*, minval(v2)
          if (present(v3)) print*, minval(v3)
          if (present(v4)) print*, minval(v4)
        endif
!
      endsubroutine keep_compiler_quiet_r2d
!***********************************************************************
      subroutine keep_compiler_quiet_r3d(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        real, dimension(:,:,:) :: v1, v2, v3, v4
        optional               ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_r3d', &
              '91 is a prime, and we never got here...')
          print*,                  minval(v1)
          if (present(v2)) print*, minval(v2)
          if (present(v3)) print*, minval(v3)
          if (present(v4)) print*, minval(v4)
        endif
!
      endsubroutine keep_compiler_quiet_r3d
!***********************************************************************
      subroutine keep_compiler_quiet_r4d(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        real, dimension(:,:,:,:) :: v1, v2, v3, v4
        optional                 ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_r4d', &
              'The world is a disk, and we never got here...')
          print*,                  minval(v1)
          if (present(v2)) print*, minval(v2)
          if (present(v3)) print*, minval(v3)
          if (present(v4)) print*, minval(v4)
        endif
!
      endsubroutine keep_compiler_quiet_r4d
!***********************************************************************
      subroutine keep_compiler_quiet_p(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        type (pencil_case) :: v1, v2, v3, v4
        optional           ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_p', &
              'The world is a disk, and we never got here...')
          print*,                  v1
          if (present(v2)) print*, v2
          if (present(v3)) print*, v3
          if (present(v4)) print*, v4
        endif
!
      endsubroutine keep_compiler_quiet_p
!***********************************************************************
      subroutine keep_compiler_quiet_bc(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        type (boundary_condition) :: v1, v2, v3, v4
        optional                  ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_p', &
              'The world is a disk, and we never got here...')
          print*,                  v1
          if (present(v2)) print*, v2
          if (present(v3)) print*, v3
          if (present(v4)) print*, v4
        endif
!
      endsubroutine keep_compiler_quiet_bc
!***********************************************************************
      subroutine keep_compiler_quiet_sl(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        type (slice_data) :: v1, v2, v3, v4
        optional          ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_p', &
              'The world is a disk, and we never got here...')
          print*,                  v1%ix
          if (present(v2)) print*, v2%ix
          if (present(v3)) print*, v3%ix
          if (present(v4)) print*, v4%ix
        endif
!
      endsubroutine keep_compiler_quiet_sl
!***********************************************************************
      subroutine keep_compiler_quiet_i(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        integer  :: v1, v2, v3, v4
        optional ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_1', &
              'The world is a disk, and we never got here...')
          print*,                  v1
          if (present(v2)) print*, v2
          if (present(v3)) print*, v3
          if (present(v4)) print*, v4
        endif
!
      endsubroutine keep_compiler_quiet_i
!***********************************************************************
      subroutine keep_compiler_quiet_i1d(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        integer, dimension(:)  :: v1, v2, v3, v4
        optional               ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_i1d', &
              'The world is a disk, and we never got here...')
          print*,                  v1(1)
          if (present(v2)) print*, v2(1)
          if (present(v3)) print*, v3(1)
          if (present(v4)) print*, v4(1)
        endif
!
      endsubroutine keep_compiler_quiet_i1d
!***********************************************************************
      subroutine keep_compiler_quiet_i2d(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        integer, dimension(:,:)  :: v1, v2, v3, v4
        optional                 ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_i2d', &
              'The world is a disk, and we never got here...')
          print*,                  v1(1,1)
          if (present(v2)) print*, v2(1,1)
          if (present(v3)) print*, v3(1,1)
          if (present(v4)) print*, v4(1,1)
        endif
!
      endsubroutine keep_compiler_quiet_i2d
!***********************************************************************
      subroutine keep_compiler_quiet_i3d(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        integer, dimension(:,:,:)  :: v1, v2, v3, v4
        optional                   ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_i3d', &
              'The world is a disk, and we never got here...')
          print*,                  v1(1,1,1)
          if (present(v2)) print*, v2(1,1,1)
          if (present(v3)) print*, v3(1,1,1)
          if (present(v4)) print*, v4(1,1,1)
        endif
!
      endsubroutine keep_compiler_quiet_i3d
!***********************************************************************
      subroutine keep_compiler_quiet_l1d(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        logical, dimension(:)  :: v1, v2, v3, v4
        optional               ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_l1d', &
              'The world is a disk, and we never got here...')
          print*,                  v1(1)
          if (present(v2)) print*, v2(1)
          if (present(v3)) print*, v3(1)
          if (present(v4)) print*, v4(1)
        endif
!
      endsubroutine keep_compiler_quiet_l1d
!***********************************************************************
      subroutine keep_compiler_quiet_l(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        logical  :: v1, v2, v3, v4
        optional ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_l', &
              'The world is a disk, and we never got here...')
          print*,                  v1
          if (present(v2)) print*, v2
          if (present(v3)) print*, v3
          if (present(v4)) print*, v4
        endif
!
      endsubroutine keep_compiler_quiet_l
!***********************************************************************
      subroutine keep_compiler_quiet_c(v1,v2,v3,v4)
!
!  Call this to avoid compiler warnings about unused variables.
!  Optional arguments allow for more variables of the same shape+type.
!
!  04-aug-06/wolf: coded
!
        character (len=*) :: v1, v2, v3, v4
        optional          ::     v2, v3, v4
!
        if (NO_WARN) then
          call error('keep_compiler_quiet_l', &
              'The world is a disk, and we never got here...')
          print*,                  v1
          if (present(v2)) print*, v2
          if (present(v3)) print*, v3
          if (present(v4)) print*, v4
        endif
!
      endsubroutine keep_compiler_quiet_c
!***********************************************************************
      subroutine parse_bc(bc,bc1,bc2)
!
!  Parse boundary conditions, which may be in the form `a' (applies to
!  both `lower' and `upper' boundary) or `a:s' (use `a' for lower,
!  `s' for upper boundary.
!
!  24-jan-02/wolf: coded
!
        character (len=2*bclen+1), dimension(mcom) :: bc
        character (len=bclen), dimension(mcom) :: bc1,bc2
        integer :: j,isep
!
        intent(in) :: bc
        intent(out) :: bc1,bc2
!
        do j=1,mcom
          if (bc(j) == '') then ! will probably never happen due to default='p'
            if (lroot) print*, 'Empty boundary condition No. ', &
                 j, 'in (x, y, or z)'
            call fatal_error('parse_bc','')
          endif
          isep = index(bc(j),':')
          if (isep > 0) then
            bc1(j) = bc(j)(1:isep-1)
            bc2(j) = bc(j)(isep+1:)
          else
            bc1(j) = bc(j)(1:bclen)
            bc2(j) = bc(j)(1:bclen)
          endif
        enddo
!
      endsubroutine parse_bc
!***********************************************************************
      subroutine parse_bc_rad(bc,bc1,bc2)
!
!  Parse boundary conditions, which may be in the form `a' (applies to
!  both `lower' and `upper' boundary) or `a:s' (use `a' for lower,
!  `s' for upper boundary.
!
!   6-jul-03/axel: adapted from parse_bc
!
        character (len=2*bclen+1), dimension(3) :: bc
        character (len=bclen), dimension(3) :: bc1,bc2
        integer :: j,isep
!
        intent(in) :: bc
        intent(out) :: bc1,bc2
!

        do j=1,3
          if (bc(j) == '') then ! will probably never happen due to default='p'
            if (lroot) print*, 'Empty boundary condition No. ', &
                 j, 'in (x, y, or z)'
            call fatal_error('parse_bc','')
          endif
          isep = index(bc(j),':')
          if (isep > 0) then
            bc1(j) = bc(j)(1:isep-1)
            bc2(j) = bc(j)(isep+1:)
          else
            bc1(j) = bc(j)(1:bclen)
            bc2(j) = bc(j)(1:bclen)
          endif
        enddo
!
      endsubroutine parse_bc_rad
!***********************************************************************
      subroutine parse_bc_radg(bc,bc1,bc2)
!
!  Parse boundary conditions, which may be in the form `a' (applies to
!  both `lower' and `upper' boundary) or `a:s' (use `a' for lower,
!  `s' for upper boundary.
!
!   6-jul-03/axel: adapted from parse_bc
!
        character (len=2*bclen+1) :: bc
        character (len=bclen) :: bc1,bc2
        integer :: isep
!
        intent(in) :: bc
        intent(out) :: bc1,bc2
!
        if (bc == '') then
          if (lroot) print*, 'Empty boundary condition in (x, y, or z)'
          call fatal_error('parse_bc_radg','')
        endif
        isep = index(bc,':')
        if (isep > 0) then
          bc1 = bc(1:isep-1)
          bc2 = bc(isep+1:)
        else
          bc1 = bc(1:bclen)
          bc2 = bc(1:bclen)
        endif
!
      endsubroutine parse_bc_radg
!***********************************************************************
      subroutine parse_shell(strin,strout)
!
!  Parse strin replacing all $XXXX sequences with appropriate
!  values from the environment.  Return the parsed result in strout
!
        use General, only: safe_character_assign
!
      character (len=*) :: strin, strout
      character (len=255) :: envname, chunk !, envvalue
      character (len=1) :: chr
      character (len=64), parameter :: envnamechars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-'
      integer :: inptr, inlen, envstart, nameptr
!
      intent(in)    :: strin
      intent(inout)   :: strout
!
      inptr=1
      inlen=len(trim(strin))
      strout=''

dlrloop:do
        envstart =index(strin(inptr:inlen),'$')
        if (envstart .le. 0) exit;
        chunk = trim(strin(inptr:envstart-1))
        if (envstart .gt. inptr) call safe_character_assign(strout,trim(strout)//trim(chunk))
        inptr = envstart + 1;
        if (inptr .gt. inlen) exit dlrloop

        nameptr = inptr
nameloop: do
          chr = trim(strin(nameptr:nameptr))
          if (index(envnamechars,chr) .gt. 0) then
            nameptr=nameptr+1
          else
            exit nameloop
          endif

          if (nameptr .gt. inlen) exit nameloop
        enddo nameloop
        if ((nameptr-1) .ge. inptr) then
         envname=trim(strin(inptr:nameptr-1))
! Commented pending a C replacement
!         call getenv(trim(envname),envvalue)
!         call safe_character_assign(strout,trim(strout)//trim(envvalue))
        endif

        inptr=nameptr
        if (inptr .gt. inlen) exit dlrloop

      enddo dlrloop

      if (inptr .le. inlen) then
         chunk = trim(strin(inptr:inlen))
         call safe_character_assign(strout,trim(strout)//trim(chunk))
      endif
!
      endsubroutine parse_shell
!***********************************************************************
      subroutine remove_file(fname)
!
!  Remove a file; this variant seems to be portable
!  5-mar-02/wolf: coded
!
        character (len=*) :: fname
        logical :: exist
!
!  check whether file exists
!
        inquire(FILE=fname,exist=exist)
!
!  remove file
!
        if (exist) then
          if (ip<=6) print*,'remove_file: Removing file <',trim(fname),'>'
          open(1,FILE=fname)
          close(1,STATUS='DELETE')
        endif
!
      endsubroutine remove_file
!***********************************************************************
      subroutine touch_file(fname)
!
!  touch file (used for code locking)
!  25-may-03/axel: coded
!
        character (len=*) :: fname
!
        open(1,FILE=fname)
        close(1)
!
      endsubroutine touch_file
!***********************************************************************
      function control_file_exists(fname, delete)
!
!  Does the given control file exist in either ./ or ./runtime/ ?
!  If DELETE is true, delete the file after checking for existence.
!  Does nothing and returns .false. on any non-root MPI node.
!
!  26-jul-09/wolf: coded
!
        logical :: control_file_exists
        character (len=*) :: fname
        logical, optional :: delete
        logical :: delete1, exists
!
        if (present(delete)) then
          delete1 = delete
        else
          delete1 = .false.
        endif

        exists = file_exists(trim("./" // fname), delete1)
        if (.not. exists) then
          exists = file_exists(trim("./runtime/" // fname), delete1)
        endif
        control_file_exists = exists

      endfunction control_file_exists
!***********************************************************************
      function file_exists(fname, delete)
!
!  Does the given file exist?
!  If DELETE is true, delete the file after checking for existence.
!  Does nothing and returns .false. on any non-root MPI node.
!
!  24-jul-09/wolf: coded
!
        logical :: file_exists
        character (len=*) :: fname
        logical, optional :: delete
        logical :: exist
!
        if (lroot) then
          inquire(FILE=fname, EXIST=exist)
!
          if (exist .and. present(delete)) then
            if (delete) then
              call remove_file(fname)
            endif
          endif
!
          file_exists = exist
        else
          file_exists = .false.
        endif
!
      endfunction file_exists
!***********************************************************************
      function read_line_from_file(fname)
!
!  Read the first line from a file; return empty string if file is empty
!  4-oct-02/wolf: coded
!
        character (len=linelen) :: read_line_from_file,line
        character (len=*) :: fname
        logical :: exist
!
        read_line_from_file=''  ! default
        inquire(FILE=fname,EXIST=exist)
        if (exist) then
          open(1,FILE=fname,ERR=666)
          read(1,'(A)',END=666,ERR=666) line
          close(1)
          read_line_from_file = line
        endif
666     return
!
      endfunction read_line_from_file
!***********************************************************************
    subroutine get_nseed(nseed)
!
!  Get length of state of random number generator. The current seed can
!  be represented by nseed (4-byte) integers.
!  Different compilers have different lengths:
!    NAG: 1, Compaq: 2, Intel: 47, SGI: 64, NEC: 256
!
      use Mpicomm, only: lroot
      use General, only: random_seed_wrapper
!
      integer :: nseed
!
      call random_seed_wrapper(SIZE=nseed)
      !
      ! test whether mseed is large enough for this machine
      !
      if (nseed > mseed) then
        if (lroot) print*, 'This machine requires mseed >= ', nseed, &
            ', but you have only ', mseed
        call fatal_error('get_nseed','Need to increase mseed')
      endif
!
    endsubroutine get_nseed
!***********************************************************************
    subroutine write_dx_general(file,x00,y00,z00)
!
!  Write .general file for data explorer (aka DX)
!  04-oct-02/wolf: coded
!  08-oct-02/tony: use safe_character_assign() to detect string overflows
!
      use General, only: safe_character_append
!
      real :: x00,y00,z00
      character (len=*) :: file
      character (len=datelen) :: date
      character (len=linelen) :: field='',struct='',type='',dep=''
!
      call date_time_string(date)
!
!  accumulate a few lines
!
      if (lhydro    ) then
        call safe_character_append(field,  'uu, '       )
        call safe_character_append(struct, '3-vector, ' )
        call safe_character_append(type,   'float, '    )
        call safe_character_append(dep,    'positions, ')
      endif
      if (ldensity  ) then
        call safe_character_append(field,  'lnrho, '    )
        call safe_character_append(struct, 'scalar, '   )
        call safe_character_append(type,   'float, '    )
        call safe_character_append(dep,    'positions, ')
      endif
      if (lentropy  ) then
        call safe_character_append(field,  'ss, '       )
        call safe_character_append(struct, 'scalar, '   )
        call safe_character_append(type,   'float, '    )
        call safe_character_append(dep,    'positions, ')
      endif
      if (lmagnetic ) then
        call safe_character_append(field,  'aa, '       )
        call safe_character_append(struct, '3-vector, ' )
        call safe_character_append(type,   'float, '    )
        call safe_character_append(dep,    'positions, ')
      endif
!
!  remove trailing comma
!
      field  = field (1:len(trim(field ))-1)
      struct = struct(1:len(trim(struct))-1)
      type   = type  (1:len(trim(type  ))-1)
      dep    = dep   (1:len(trim(dep   ))-1)
!
!  now write
!
      open(1,FILE=file)
!
      write(1,'(A)'  ) '# Creator: The Pencil Code'
      write(1,'(A,A)') '# Date: ', trim(date)
      write(1,'(A,A)') 'file = ', trim(datadir)//'/proc0/var.dat'
      write(1,'(A,I4," x ",I4," x ",I4)') 'grid = ', mx, my, mz
      write(1,'(A)'  ) '# NB: setting lsb (little endian); may need to change this to msb'
      write(1,'(A,A," ",A)') 'format = ', 'lsb', 'ieee'
      write(1,'(A,A)') 'header = ', 'bytes 4'
      write(1,'(A,A)') 'interleaving = ', 'record'
      write(1,'(A,A)') 'majority = ', 'column'
      write(1,'(A,A)') 'field = ', trim(field)
      write(1,'(A,A)') 'structure = ', trim(struct)
      write(1,'(A,A)') 'type = ', trim(type)
      write(1,'(A,A)') 'dependency = ', trim(dep)
      write(1,'(A,A,6(", ",1PG12.4))') 'positions = ', &
           'regular, regular, regular', &
           x00, dx, y00, dy, z00, dz
      write(1,'(A)') ''
      write(1,'(A)') 'end'
!
      close(1)

    endsubroutine write_dx_general
!***********************************************************************
    subroutine write_zprof(file,a)
!
!  writes z-profile to a file (if constructed for identical pencils)
!
!  10-jul-05/axel: coded
!
      use General, only: safe_character_assign
!
      real, dimension(nx) :: a
      character (len=*) :: file
      character (len=120) :: wfile
!
!  do this only for the first step
!
      if (lwrite_prof) then
        if (m==m1) then
!
!  write zprofile file
!
          call safe_character_assign(wfile, &
            trim(directory)//'/zprof_'//trim(file)//'.dat')
          open(1,file=wfile,position='append')
          write(1,*) z(n),a(1)
          close(1)
!
!  add file name to list of f zprofile files
!
          if (n==n1) then
            call safe_character_assign(wfile,trim(directory)//'/zprof_list.dat')
            open(1,file=wfile,position='append')
            write(1,*) file
            close(1)
          endif
        endif
      endif
!
    endsubroutine write_zprof
!***********************************************************************
    subroutine remove_zprof()
!
!  remove z-profile file
!
!  10-jul-05/axel: coded
!
      use General, only: safe_character_assign
!
      character (len=120) :: filename,wfile,listfile
!
!  do this only for the first step
!
      call safe_character_assign(listfile,trim(directory)//'/zprof_list.dat')
!
!  read list of file and remove them one by one
!
      open(2,file=listfile)
      filename_loop: do while (it<=nt)
        read(2,*,end=999) filename
        call safe_character_assign(wfile, &
          trim(directory)//'/zprof_'//trim(filename)//'.dat')
        call remove_file(wfile)
      enddo filename_loop
999   close(2)
!
!  now delete this listfile altogether
!
      call remove_file(listfile)
!
    endsubroutine remove_zprof
!***********************************************************************
    subroutine date_time_string(date)
!
!  Return current date and time as a string.
!  Subroutine, because nested writes don't work on some machines, so
!  calling a function like
!    print*, date_time_string()
!  may crash mysteriously.
!
!  4-oct-02/wolf: coded
!
      intent (out) :: date
!
      character (len=*) :: date
      integer, dimension(8) :: values
      character (len=3), dimension(12) :: month = &
           (/ 'jan', 'feb', 'mar', 'apr', 'may', 'jun', &
              'jul', 'aug', 'sep', 'oct', 'nov', 'dec' /)
!
      if (len(date) < 20) &
          call fatal_error('date_time_string','string arg too short')
!
      call date_and_time(VALUES=values)
      write(date,'(I2.2,"-",A3,"-",I4.2," ",I2.2,":",I2.2,":",I2.2)') &
           values(3), month(values(2)), values(1), &
           values(5), values(6), values(7)
!
! TEMPORARY DEBUGGING STUFF
! SOMETIMES THIS ROUTINE PRINTS '***' WHEN IT SHOULDN'T
!
      if (index(date,'*')>0) then
        open(11,FILE='date_time_string.debug')
        write(11,*) 'This file was generated because sub$date_time_string()'
        write(11,*) 'produced a strange result.'
        write(11,*)
        write(11,*) 'date = <', date,'>'
        write(11,*) 'values = ', values
        write(11,*) 'i.e.'
        write(11,*) 'values(1) = ', values(1)
        write(11,*) 'values(2) = ', values(2)
        write(11,*) 'values(3) = ', values(3)
        write(11,*) 'values(4) = ', values(4)
        write(11,*) 'values(5) = ', values(5)
        write(11,*) 'values(6) = ', values(6)
        write(11,*) 'values(7) = ', values(7)
        close(11)
      endif
!
!  END OF TEMPORARY DEBUGGING STUFF
!
!
    endsubroutine date_time_string
!***********************************************************************
    subroutine blob(ampl,f,i,radius,xblob,yblob,zblob)
!
!  single  blob
!
!  27-jul-02/axel: coded
!
      integer :: i
      real, dimension (mx,my,mz,mfarray) :: f
      real,optional :: xblob,yblob,zblob
      real :: ampl,radius,x01=0.,y01=0.,z01=0.
!
!  single  blob
!
      if (present(xblob)) x01=xblob
      if (present(yblob)) y01=yblob
      if (present(zblob)) z01=zblob
      if (ampl==0) then
        if (lroot) print*,'ampl=0 in blob'
      else
        if (lroot.and.ip<14) print*,'blob: variable i,ampl=',i,ampl
        f(:,:,:,i)=f(:,:,:,i)+ampl*(&
           spread(spread(exp(-((x-x01)/radius)**2),2,my),3,mz)&
          *spread(spread(exp(-((y-y01)/radius)**2),1,mx),3,mz)&
          *spread(spread(exp(-((z-z01)/radius)**2),1,mx),2,my))
      endif
!
    endsubroutine blob
!***********************************************************************
    recursive function hypergeometric2F1(a,b,c,z,tol) result (hyp2F1)

      real, intent(in) :: a,b,c,z,tol
      real :: hyp2F1
      real :: fac
      integer :: n

      real :: aa,bb,cc

      aa=a; bb=b; cc=c

      fac=1
      hyp2F1=fac
      n=1

      if (z<=0.5) then

        do while (fac>tol)
          fac=fac*aa*bb*z/(cc*n)
          hyp2F1=hyp2F1+fac
          aa=aa+1
          bb=bb+1
          cc=cc+1
          n=n+1
        enddo

      else

        !!!!!!!! only valid for mu=-1 !!!!!!!!
        !hyp2F1=2*hypergeometric2F1(aa,bb,aa+bb-cc+1,1-z,tol)-sqrt(1-z)* &
               !2*hypergeometric2F1(cc-aa,cc-bb,cc-aa-bb+1,1-z,tol)
        hyp2F1=(gamma_function(cc)*gamma_function(cc-aa-bb))/ &
               (gamma_function(cc-aa)*gamma_function(cc-bb))* &
               hypergeometric2F1(aa,bb,aa+bb-cc+1,1-z,tol) &
              +(1-z)**(cc-aa-bb)* &
               (gamma_function(cc)*gamma_function(aa+bb-cc))/ &
               (gamma_function(aa)*gamma_function(bb))* &
               hypergeometric2F1(cc-aa,cc-bb,cc-aa-bb+1,1-z,tol)

      endif

    endfunction hypergeometric2F1
!***********************************************************************
    recursive function pi_function(x) result(pi_func)
!
!  calculates the Pi-function using rational approximation
!
!    Pi(x) = Gamma(x+1) = x!
!
!  coefficients were determined using maple's minimax() function
!
!
!  9-jun-04/tobi+wolf: coded
!
      real, intent(in) :: x
      real :: pi_func
      integer, parameter :: order=7
      real, dimension(order) :: coeff1,coeff2
      real :: enum,denom
      integer :: i

      coeff1=(/0.66761295020790986D00, &
               0.36946093910826145D00, &
               0.18669829780572704D00, &
               4.8801451277274492D-2, &
               1.36528684153155468D-2, &
               1.7488042503123817D-3, &
               3.6032044608268575D-4/)

      coeff2=(/0.66761295020791116D00, &
               0.754817592058897962D00, &
              -3.7915754844972276D-2, &
              -0.11379619871302534D00, &
               1.5035521280605477D-2, &
               3.1375176929984225D-3, &
              -5.5599617153443518D-4/)

      if (x>1) then

        pi_func=x*pi_function(x-1)

      elseif (x<0) then

        if (abs(x+1)<=epsilon(x)) then
          pi_func=pi_function(x+1)/epsilon(x)
        else
          pi_func=pi_function(x+1)/(x+1)
        endif

      else

        enum=coeff1(order)
        do i=order-1,1,-1
          enum=enum*x+coeff1(i)
        enddo
        denom=coeff2(order)
        do i=order-1,1,-1
          denom=denom*x+coeff2(i)
        enddo
        pi_func=enum/denom

      endif
!
    endfunction pi_function
!***********************************************************************
    function gamma_function(x)
!
!  calculates the Gamma-function as
!
!    Gamma(x) = Pi(x-1)
!
!
!  9-jun-04/tobi+wolf: coded
!
      real, intent(in) :: x
      real :: gamma_function
!
      gamma_function=pi_function(x-1)
!
    endfunction gamma_function
!***********************************************************************
    subroutine tensor_diffusion_coef(gecr,ecr_ij,bij,bb,vKperp,vKpara,rhs,llog,gvKperp,gvKpara)
!
!  calculates tensor diffusion with variable tensor (or constant tensor)
!  calculates parts common to both variable and constant tensor first
!  note:ecr=lnecr in the below comment
!
!  write diffusion tensor as K_ij = Kpara*ni*nj + (Kperp-Kpara)*del_ij.
!
!  vKperp*del2ecr + d_i(vKperp)d_i(ecr) + (vKpara-vKperp) d_i(n_i*n_j*d_j ecr)
!      + n_i*n_j*d_i(ecr)d_j(vKpara-vKperp)
!
!  = vKperp*del2ecr + gKperp.gecr + (vKpara-vKperp) (H.G + ni*nj*Gij)
!      + ni*nj*Gi*(vKpara_j - vKperp_j),
!  where H_i = (nj bij - 2 ni nj nk bk,j)/|b| and vKperp, vKpara are variable
!  diffusion coefficients
!
!  calculates (K.gecr).gecr
!  =  vKperp(gecr.gecr) + (vKpara-vKperp)*Gi(ni*nj*Gj)
!
!  adds both parts into decr/dt
!
!  10-oct-03/axel: adapted from pscalar
!  30-nov-03/snod: adapted from tensor_diff without variable diffusion
!  04-dec-03/snod: converted for evolution of lnecr (=ecr)
!   9-apr-04/axel: adapted for general purpose tensor diffusion
!  25-jun-05/bing:
!
      real, dimension (nx,3,3) :: ecr_ij,bij
      real, dimension (nx,3) :: gecr,bb,bunit,hhh,gvKperp1,gvKpara1,tmpv
      real, dimension (nx) :: abs_b,b1,del2ecr,gecr2,vKperp,vKpara
      real, dimension (nx) :: hhh2,quenchfactor,rhs,tmp,tmpi,tmpj,tmpk
      real :: limiter_tensordiff=3.
      integer :: i,j,k
      logical, optional :: llog
      real, optional, dimension (nx,3) :: gvKperp,gvKpara
!
      intent(in) :: bb,bij,gecr,ecr_ij
      intent(out) :: rhs
!
!  calculate unit vector of bb
!
!     call dot2_mn(bb,abs_b,PRECISE_SQRT=.true.)
      call dot2_mn(bb,abs_b,FAST_SQRT=.true.)
      b1=1./max(tini,abs_b)
      call multsv_mn(b1,bb,bunit)
!
!  calculate first H_i
!
      del2ecr=0.
      do i=1,3
        del2ecr=del2ecr+ecr_ij(:,i,i)
        hhh(:,i)=0.
        do j=1,3
          tmpj(:)=0.
          do k=1,3
            tmpj(:)=tmpj(:)-2.*bunit(:,k)*bij(:,k,j)
          enddo
          hhh(:,i)=hhh(:,i)+bunit(:,j)*(bij(:,i,j)+bunit(:,i)*tmpj(:))
        enddo
      enddo
      call multsv_mn(b1,hhh,tmpv)
!
!  limit the length of H such that dxmin*H < 1, so we also multiply
!  by 1/sqrt(1.+dxmin^2*H^2).
!  and dot H with ecr gradient
!
!     call dot2_mn(tmpv,hhh2,PRECISE_SQRT=.true.)
      call dot2_mn(tmpv,hhh2,FAST_SQRT=.true.)
      quenchfactor=1./max(1.,limiter_tensordiff*hhh2*dxmax)
      call multsv_mn(quenchfactor,tmpv,hhh)
      call dot_mn(hhh,gecr,tmp)
!
!  dot Hessian matrix of ecr with bi*bj, and add into tmp
!
      call multmv_mn(ecr_ij,bunit,hhh)
      call dot_mn(hhh,bunit,tmpj)
      tmp = tmp+tmpj
!
!  calculate (Gi*ni)^2 needed for lnecr form; also add into tmp
!
      gecr2=0.
      if (present(llog)) then
        call dot_mn(gecr,bunit,tmpi)
        tmp=tmp+tmpi**2
!
!  calculate gecr2 - needed for lnecr form
!
        call dot2_mn(gecr,gecr2)
      endif
!
!  if variable tensor, add extra terms and add result into decr/dt
!
!  set gvKpara, gvKperp
!
     if (present(gvKpara)) then; gvKpara1=gvKpara; else; gvKpara1=0.; endif
     if (present(gvKperp)) then; gvKperp1=gvKperp; else; gvKperp1=0.; endif
!
!  put d_i ecr d_i vKperp into tmpj
!
      call dot_mn(gvKperp1,gecr,tmpj)
!
!  nonuniform conductivities, add terms into tmpj

      call dot(bunit,gvKpara1-gvKperp1,tmpi)
      call dot(bunit,gecr,tmpk)
      tmpj = tmpj+tmpi*tmpk
!
!
!  calculate rhs
!
      rhs=vKperp*(del2ecr+gecr2) + (vKpara-vKperp)*tmp + tmpj
!
    endsubroutine tensor_diffusion_coef
!***********************************************************************
    subroutine max_for_dt_nx_nx(f,maxf)
!
!  Like maxf = max(f,max), unless we have chosen to manipulate data
!  before taking the maximum value. Designed for calculation of time step,
!  where one may want to exclude certain regions, etc.
!
!  Would be nicer as an (assumed-size) array-valued function (as a plug-in
!  replacement for max), but this can be more than 2 times slower (NEC
!  SX-5, compared to about 15% slower with Intel F95) than a subroutine
!  call according to tests.
!
!  30-jan-04/wolf: coded
!
      real, dimension(nx) :: maxf,f
!
      intent(in)    :: f
      intent(inout) :: maxf
!
      maxf = max(f,maxf)
!
    endsubroutine max_for_dt_nx_nx
!***********************************************************************
    subroutine max_for_dt_1_nx(f,maxf)
!
!  Like max_for_dt_n_n, but with a different signature of argument shapes.
!
!  30-jan-04/wolf: coded
!
      real, dimension(nx) :: maxf
      real                :: f
!
      intent(in)    :: f
      intent(inout) :: maxf
!
      maxf = max(f,maxf)
!
    endsubroutine max_for_dt_1_nx
!***********************************************************************
    subroutine max_for_dt_1_1_1_nx(f1,f2,f3,maxf)
!
!  Like max_for_dt_n_n, but with a different signature of argument shapes.
!
!  30-jan-04/wolf: coded
!
      real, dimension(nx) :: maxf
      real                :: f1,f2,f3
!
      intent(in)    :: f1,f2,f3
      intent(inout) :: maxf
!
      maxf = max(f1,f2,f3,maxf)
!
    endsubroutine max_for_dt_1_1_1_nx
!***********************************************************************
    function pencil_multiply1(s,v)
!
!  The `*' operator may be extended through this function to allow
!  elementwise multiplication of a `pencil-scalar' with a `pencil-vector'
!
!   6-Sep-05/tobi: coded
!
      real, dimension(nx), intent(in) :: s
      real, dimension(nx,3), intent(in) :: v
      real, dimension(nx,3) :: pencil_multiply1
!
      integer :: i
!
      do i=1,3; pencil_multiply1(:,i) = s(:) * v(:,i); enddo
!
    endfunction pencil_multiply1
!***********************************************************************
    function pencil_multiply2(v,s)
!
!  The `*' operator may be extended through this function to allow
!  elementwise multiplication of a `pencil-scalar' with a `pencil-vector'
!
!   6-Sep-05/tobi: coded
!
      real, dimension(nx,3), intent(in) :: v
      real, dimension(nx), intent(in) :: s
      real, dimension(nx,3) :: pencil_multiply2
!
      integer :: i
!
      do i=1,3; pencil_multiply2(:,i) = v(:,i) * s(:); enddo
!
    endfunction pencil_multiply2
!***********************************************************************
    function pencil_add1(s,v)
!
!  The `+' operator may be extended through this function to allow
!  elementwise addition of a `pencil-scalar' to a `pencil-vector'
!
!   6-Sep-05/tobi: coded
!
      real, dimension(nx), intent(in) :: s
      real, dimension(nx,3), intent(in) :: v
      real, dimension(nx,3) :: pencil_add1
!
      integer :: i
!
      do i=1,3; pencil_add1(:,i) = s(:) + v(:,i); enddo
!
    endfunction pencil_add1
!***********************************************************************
    function pencil_add2(v,s)
!
!  The `+' operator may be extended through this function to allow
!  elementwise addition of a `pencil-scalar' to a `pencil-vector'
!
!   6-Sep-05/tobi: coded
!
      real, dimension(nx,3), intent(in) :: v
      real, dimension(nx), intent(in) :: s
      real, dimension(nx,3) :: pencil_add2
!
      integer :: i
!
      do i=1,3; pencil_add2(:,i) = v(:,i) + s(:); enddo
!
    endfunction pencil_add2
!***********************************************************************
    function pencil_divide1(s,v)
!
!  The `/' operator may be extended through this function to allow
!  elementwise division of a `pencil-scalar' by a `pencil-vector'
!
!   6-Sep-05/tobi: coded
!
      real, dimension(nx), intent(in) :: s
      real, dimension(nx,3), intent(in) :: v
      real, dimension(nx,3) :: pencil_divide1
!
      integer :: i
!
      do i=1,3; pencil_divide1(:,i) = s(:) / v(:,i); enddo
!
    endfunction pencil_divide1
!***********************************************************************
    function pencil_divide2(v,s)
!
!  The `/' operator may be extended through this function to allow
!  elementwise division of a `pencil-vector' by a `pencil-scalar'
!
!   6-Sep-05/tobi: coded
!
      real, dimension(nx,3), intent(in) :: v
      real, dimension(nx), intent(in) :: s
      real, dimension(nx,3) :: pencil_divide2
!
      integer :: i
!
      do i=1,3; pencil_divide2(:,i) = v(:,i) / s(:); enddo
!
    endfunction pencil_divide2
!***********************************************************************
    function pencil_substract1(s,v)
!
!  The `-' operator may be extended through this function to allow
!  elementwise substraction of a `pencil-vector' from a `pencil-scalar'
!
!   6-Sep-05/tobi: coded
!
      real, dimension(nx), intent(in) :: s
      real, dimension(nx,3), intent(in) :: v
      real, dimension(nx,3) :: pencil_substract1
!
      integer :: i
!
      do i=1,3; pencil_substract1(:,i) = s(:) - v(:,i); enddo
!
    endfunction pencil_substract1
!***********************************************************************
    function pencil_substract2(v,s)
!
!  The `-' operator may be extended through this function to allow
!  elementwise substraction of a `pencil-scalar' from a `pencil-vector'
!
!   6-Sep-05/tobi: coded
!
      real, dimension(nx,3), intent(in) :: v
      real, dimension(nx), intent(in) :: s
      real, dimension(nx,3) :: pencil_substract2
!
      integer :: i
!
      do i=1,3; pencil_substract2(:,i) = v(:,i) - s(:); enddo
!
    endfunction pencil_substract2
!***********************************************************************
    function erfunc_pt(x)
!
! Error function from Numerical Recipes.
! erfunc(x) = 1 - erfc(x)
!
!  This version is for scalar args.
!
! 15-Jan-2007/dintrans: coded
!
    implicit none
!
    real :: erfunc_pt,dumerfc,x,t,z
!
    z = abs(x)
    t = 1.0 / ( 1.0 + 0.5 * z )
!
    dumerfc =  t * exp(-z * z - 1.26551223 + t *        &
        ( 1.00002368 + t * ( 0.37409196 + t *           &
        ( 0.09678418 + t * (-0.18628806 + t *           &
        ( 0.27886807 + t * (-1.13520398 + t *           &
        ( 1.48851587 + t * (-0.82215223 + t * 0.17087277 )))))))))
!
    if ( x.lt.0.0 ) dumerfc = 2.0 - dumerfc
    erfunc_pt = 1.0 - dumerfc
!
    endfunction erfunc_pt
!***********************************************************************
    function erfunc_mn(x)
!
! Error function from Numerical Recipes.
! erfunc_mn(x) = 1 - erfc(x)
!
!  Version for 1d arg (in particular pencils).
!
! 15-Jan-2007/dintrans: coded
!
    implicit none
!
    real, dimension(:) :: x
    real, dimension(size(x,1)) :: erfunc_mn,dumerfc,t,z
!
    z = abs(x)
    t = 1.0 / ( 1.0 + 0.5 * z )
!
    dumerfc =  t * exp(-z * z - 1.26551223 + t *        &
        ( 1.00002368 + t * ( 0.37409196 + t *           &
        ( 0.09678418 + t * (-0.18628806 + t *           &
        ( 0.27886807 + t * (-1.13520398 + t *           &
        ( 1.48851587 + t * (-0.82215223 + t * 0.17087277 )))))))))
!
    where ( x.lt.0. ) dumerfc = 2.0 - dumerfc
!
    erfunc_mn = 1.0 - dumerfc
!
    endfunction erfunc_mn
!***********************************************************************
    subroutine power_law_mn(const,dist,plaw_,output,xref)
!
! General distance power law initial conditions
!
! 24-feb-05/wlad: coded
!  4-jul-07/wlad: generalized for any power law case
!
      real, dimension(:) :: dist,output
      real :: const,plaw_
      real, optional :: xref
!
      intent(in)  :: const,plaw_
      intent(out) :: output
!
      if (present(xref)) dist=dist/xref
!
      if (rsmooth.eq.0.) then
        output = const*dist**(-plaw_)
      else
        output = const*(dist**2+rsmooth**2)**(-.5*plaw_)
      endif
!
    endsubroutine power_law_mn
!***********************************************************************
    subroutine power_law_pt(const,dist,plaw_,output,xref)
!
! General distance power law initial conditions
!
! 24-feb-05/wlad: coded
!  4-jul-07/wlad: generalized for any power law case
!
      real :: dist,output
      real :: const,plaw_
      real, optional :: xref
!
      intent(in)  :: const,plaw_
      intent(out) :: output
!
      if (present(xref)) dist=dist/xref
!
      if (rsmooth.eq.0.) then
        output = const*dist**(-plaw_)
      else
        output = const*(dist**2+rsmooth**2)**(-.5*plaw_)
      endif
!
    endsubroutine power_law_pt
!***********************************************************************
    subroutine get_radial_distance(rrmn,rcylmn,e1_,e2_,e3_)
!
!  Calculate distance and its cylindrical projection for different
!  coordinate systems.
!
!  e1, e2, and e3 are the positions in the respective coordinate systems
!
!  15-mar-07/wlad : coded
!
      real, dimension(:),intent(out) :: rrmn,rcylmn
      real, dimension(size(rrmn,1)) :: xc
      real, intent(in), optional :: e1_,e2_,e3_
      real :: e1,e2,e3
      integer :: tmp
      logical :: lorigin
!
!  Check if we are dealing with distance from the origin
!
      tmp=0 ; lorigin=.false.
      if (present(e1_)) then;e1=e1_;tmp=tmp+1;else;e1=0.;endif
      if (present(e2_)) then;e2=e2_;tmp=tmp+1;else;e2=0.;endif
      if (present(e3_)) then;e3=e3_;tmp=tmp+1;else;e3=0.;endif
      if (tmp==0) lorigin=.true.
!
!  Check if this array has size nx or mx
!
      select case (size(rrmn))
      case (mx)
        xc=x
      case (nx)
        xc=x(l1:l2)
      case default
        print*,'get_radial_distance: '//&
             'the array has dimension=',size(rrmn),' is that correct?'
        call fatal_error('get_radial_distance','')
      endselect
!
!  Calculate the coordinate-free distance relative to the
!  position (e1,e2,e3)
!
      if (lorigin) then
        rcylmn=sqrt(xc**2+y(m)**2)+tini
        rrmn  =sqrt(    rcylmn**2 +z(n)**2)
      else
        rcylmn=sqrt((xc-e1)**2+(y(m)-e2)**2)+tini
        rrmn  =sqrt(       rcylmn**2+(z(n)-e3)**2)
      endif
!
    endsubroutine get_radial_distance
!***********************************************************************
    function interp1(r,fr,nr,r0)
!
!  20-dec-07/dintrans: coded
!
    integer :: nr,istop,i,i1,i2
    real, dimension (nr) :: r,fr
    real    :: r0,interp1

    if (r0 == r(1)) then
      interp1=fr(1)
      return
    elseif (r0 > r(nr)) then
      interp1=fr(nr)
      return
    else
      istop=0 ; i=1
      do while (istop /= 1)
        if (r(i) >= r0) istop=1
        i=i+1
      enddo
      i1=i-2 ; i2=i-1
      interp1=(fr(i1)*(r(i2)-r0)+fr(i2)*(r0-r(i1)))/(r(i2)-r(i1))
    endif
!
    endfunction interp1
!***********************************************************************
    subroutine ludcmp(a,indx)
!
!  25-jun-09/rplasson: coded (adapted from numerical recipe)
!
!  Computes the LU decomposition of the matrix a
!  The result is placed in the matrix a
!  The row permutations are returned in indx
!
      real, dimension(:,:), intent(INOUT) :: a
      integer, dimension(:), intent(OUT) :: indx
      real, dimension(size(a,1)) :: vv,swap
      integer :: j,n,imax
      integer, dimension(1) :: tmp

      n=size(a,1)
      if (n /= size(a,2)) call fatal_error('ludcmp','non square matrix')
      if (n /= size(indx)) call fatal_error('ludcmp','bad dimension for indx')
      vv=maxval(abs(a),dim=2)
      if (any(vv == 0.0)) call fatal_error('ludcmp','singular matrix')
      vv=1.0/vv
      do j=1,n
        tmp=maxloc(vv(j:n)*abs(a(j:n,j)))
        imax=(j-1)+tmp(1)
        if (j /= imax) then
          swap=a(imax,:)
          a(imax,:)=a(j,:)
          a(j,:)=swap
          vv(imax)=vv(j)
        endif
        indx(j)=imax
        if (a(j,j) == 0.0) a(j,j)=tiny(0.)
        a(j+1:n,j)=a(j+1:n,j)/a(j,j)
        a(j+1:n,j+1:n)=a(j+1:n,j+1:n)-spread(a(j+1:n,j),dim=2,ncopies=(n-j)) * &
            spread(a(j,j+1:n),dim=1,ncopies=(n-j))
      enddo
!
    endsubroutine ludcmp
!***********************************************************************
    subroutine lubksb(a,indx,b)
!
!  25-jun-09/rplasson: coded (adapted from numerical recipe)
!
!  Solves the equation A.X=B
!  'a' must contain the LU decomposition of matrix A obtained by ludcmp
!  'indx' is the permutation vector obtained by ludcmp
!  'b' contains B, and returns the solution vector X
!
      real, dimension(:,:), intent(IN) :: a
      integer, dimension(:), intent(IN) :: indx
      real, dimension(:), intent(INOUT) :: b
      integer :: i,n,ii,ll
      real :: summ

      n=size(a,1)
      if (n /= size(a,2)) call fatal_error('lubksb','non square matrix')
      if (n /= size(indx)) call fatal_error('lubksb','bad dimension for indx')
      ii=0
      do i=1,n
        ll=indx(i)
        summ=b(ll)
        b(ll)=b(i)
        if (ii /= 0) then
          summ=summ-dot_product(a(i,ii:i-1),b(ii:i-1))
        else if (summ /= 0.0) then
          ii=i
        endif
        b(i)=summ
      enddo
      do i=n,1,-1
        b(i) = (b(i)-dot_product(a(i,i+1:n),b(i+1:n)))/a(i,i)
      enddo
!
    endsubroutine lubksb
!***********************************************************************
endmodule Sub
