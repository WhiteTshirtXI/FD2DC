MODULE modcu_BiCGSTAB

USE, INTRINSIC  :: iso_c_binding

PRIVATE
PUBLIC :: cu_getInstance,cu_initDevice,cu_allocDevice,cu_coo2csr,cu_cpH2D_sysDP,cu_BiCGSTAB_itr,cu_cpD2H_solDP,&
          cu_cpH2D_coords,cu_shutdown,CUBCG_PTR_NOT_INITIALIZED,cu_bicgstab_setstop

TYPE(c_ptr) :: cu_BiCGSTAB_ptr = c_NULL_ptr
INTEGER,PARAMETER :: CUBCG_PTR_NOT_INITIALIZED = -3 

INTERFACE
  FUNCTION cu_getInstance_Intrf RESULT(ptr) BIND (C,name='instantiate_cuBlasBiCGSTAB')
    USE, INTRINSIC  :: iso_c_binding , ONLY : c_ptr
    IMPLICIT NONE
    TYPE(c_ptr)    :: ptr
  END FUNCTION cu_getInstance_Intrf

  FUNCTION cu_initDevice_intrf(ptr) BIND (C,name='wrap_cuBlas_initDevice')
    USE, INTRINSIC  :: iso_c_binding , ONLY : c_ptr,c_int
    IMPLICIT NONE
    TYPE(c_ptr),VALUE    :: ptr
    INTEGER(c_int) :: cu_initDevice_intrf
  END FUNCTION cu_initDevice_intrf

  FUNCTION cu_allocDevice_intrf(ptr,nz,m) BIND (C,name='wrap_cuBlas_allocDevice')
    USE, INTRINSIC  :: iso_c_binding , ONLY : c_ptr,c_double,c_int
    IMPLICIT NONE
    TYPE(c_ptr),VALUE         :: ptr
    INTEGER(c_int),VALUE:: nz,m
    INTEGER(c_int)      :: cu_allocDevice_intrf
  END FUNCTION cu_allocDevice_intrf

  FUNCTION cu_BiCGSTAB_setStop_intrf(ptr,MaxIt,Tol) BIND (C,name='wrap_BiCGSTAB_setStop')
    USE, INTRINSIC  :: iso_c_binding , ONLY : c_ptr,c_int,c_double
    IMPLICIT NONE
    TYPE(c_ptr),VALUE    :: ptr
    INTEGER(c_int),VALUE :: MaxIt
    INTEGER(c_int)       :: cu_BiCGSTAB_setStop_intrf
    REAL(c_double),VALUE :: Tol
  END FUNCTION cu_BiCGSTAB_setStop_intrf

  FUNCTION cu_coo2csr_intrf(ptr) BIND (C,name='wrap_cuBlas_coo2csr')
    USE, INTRINSIC  :: iso_c_binding , ONLY : c_ptr,c_int
    IMPLICIT NONE
    TYPE(c_ptr),VALUE   :: ptr
    INTEGER(c_int)      :: cu_coo2csr_intrf 
  END FUNCTION cu_coo2csr_intrf

  FUNCTION cu_cpH2D_sysDP_intrf(ptr,cooValAhost, bhost, xhost) BIND (C,name='wrap_cuBlas_cpH2D_sysDP')
    USE, INTRINSIC  :: iso_c_binding , ONLY : c_ptr,c_double,c_int
    IMPLICIT NONE
    TYPE(c_ptr),VALUE   :: ptr
    REAL(c_double)      :: cooValAhost(*),bhost(*),xhost(*)
    INTEGER(c_int)      :: cu_cpH2D_sysDP_intrf
  END FUNCTION cu_cpH2D_sysDP_intrf

  FUNCTION cu_BiCGSTAB_itr_intrf(ptr,resid,itr) BIND (C,name='wrap_cuBlas_biCGSTAB_itr')
    USE, INTRINSIC  :: iso_c_binding , ONLY : c_ptr,c_double,c_int
    IMPLICIT NONE
    TYPE(c_ptr),VALUE   :: ptr
    REAL(c_double)      :: resid
    INTEGER(c_int)      :: itr,cu_BiCGSTAB_itr_intrf
  END FUNCTION cu_BiCGSTAB_itr_intrf

  FUNCTION cu_cpD2H_solDP_intrf(ptr,xhost) BIND (C,name='wrap_cuBlas_cpD2H_solDP')
     USE, INTRINSIC  :: iso_c_binding , ONLY : c_ptr,c_double,c_int
     IMPLICIT NONE
     TYPE(c_ptr),VALUE  :: ptr
     REAL(c_double)     :: xhost(*)
     INTEGER(c_int)     :: cu_cpD2H_solDP_intrf
  END FUNCTION cu_cpD2H_solDP_intrf

  FUNCTION  cu_cpH2D_coords_intrf(ptr,cooRowPtrAhost,cooColPtrAhost) BIND (C,name='wrap_cuBlas_cpH2D_coords')
     USE, INTRINSIC  :: iso_c_binding , ONLY : c_ptr,c_int
     TYPE(c_ptr),VALUE  :: ptr
     INTEGER(c_int)     :: cooRowPtrAhost(*),cooColPtrAhost(*)
     INTEGER(c_int)     :: cu_cpH2D_coords_intrf
  END FUNCTION 

  FUNCTION cu_shutdown_intrf(ptr) BIND (C, name='wrap_cuBlas_shutdown')
    USE, INTRINSIC      :: iso_c_binding , ONLY : c_ptr,c_int
    TYPE(c_ptr),VALUE   :: ptr  
    INTEGER(c_int)      :: cu_cpH2D_coords_intrf
  END FUNCTION cu_shutdown_intrf
   
END INTERFACE

CONTAINS

SUBROUTINE cu_getInstance()
  IMPLICIT NONE
  cu_BiCGSTAB_ptr = cu_getInstance_Intrf()
END SUBROUTINE cu_getInstance

SUBROUTINE cu_initDevice(err)
  IMPLICIT NONE
  INTEGER,INTENT(OUT) :: err
  IF(C_ASSOCIATED(cu_BiCGSTAB_ptr,c_NULL_ptr))THEN
    err = CUBCG_PTR_NOT_INITIALIZED
    RETURN
  ENDIF
  err = cu_initDevice_intrf(cu_BiCGSTAB_ptr)
END SUBROUTINE

SUBROUTINE cu_allocDevice(nz,m,err)
  IMPLICIT NONE
  INTEGER         :: nz,m
  INTEGER,INTENT(OUT) :: err
  IF(C_ASSOCIATED(cu_BiCGSTAB_ptr,c_NULL_ptr))THEN
    err = CUBCG_PTR_NOT_INITIALIZED
    RETURN
  ENDIF
  err = cu_allocDevice_intrf(cu_BiCGSTAB_ptr,nz,m)
END SUBROUTINE

SUBROUTINE cu_BiCGSTAB_setStop(MaxIt,Tol,err)
  IMPLICIT NONE
  INTEGER,INTENT(OUT) :: err
  DOUBLE PRECISION    :: Tol
  INTEGER             :: MaxIt
  IF(C_ASSOCIATED(cu_BiCGSTAB_ptr,c_NULL_ptr))THEN
    err = CUBCG_PTR_NOT_INITIALIZED
    RETURN
  ENDIF
  err = cu_BiCGSTAB_setStop_intrf(cu_BiCGSTAB_ptr,MaxIt,Tol)
END SUBROUTINE

SUBROUTINE cu_coo2csr(err)
  IMPLICIT NONE
  INTEGER,INTENT(OUT) :: err
  IF(C_ASSOCIATED(cu_BiCGSTAB_ptr,c_NULL_ptr))THEN
    err = CUBCG_PTR_NOT_INITIALIZED
    RETURN
  ENDIF
  err =  cu_coo2csr_intrf(cu_BiCGSTAB_ptr)
END SUBROUTINE

SUBROUTINE cu_cpH2D_sysDP(cooValAhost, bhost, xhost,err)
  IMPLICIT NONE
  INTEGER,INTENT(OUT) :: err
  DOUBLE PRECISION :: cooValAhost(*),bhost(*),xhost(*)
  IF(C_ASSOCIATED(cu_BiCGSTAB_ptr,c_NULL_ptr))THEN
    err = CUBCG_PTR_NOT_INITIALIZED
    RETURN
  ENDIF
  err = cu_cpH2D_sysDP_intrf(cu_BiCGSTAB_ptr, cooValAhost, bhost, xhost)
END SUBROUTINE

SUBROUTINE cu_BiCGSTAB_itr(resid,iter,err)
  IMPLICIT NONE
  INTEGER,INTENT(OUT) :: err
  DOUBLE PRECISION :: resid
  INTEGER          :: iter
  IF(C_ASSOCIATED(cu_BiCGSTAB_ptr,c_NULL_ptr))THEN
    err = CUBCG_PTR_NOT_INITIALIZED
    RETURN
  ENDIF
  err = cu_BiCGSTAB_itr_intrf(cu_BiCGSTAB_ptr,resid,iter)
END SUBROUTINE

SUBROUTINE cu_cpD2H_solDP(xhost,err)
  IMPLICIT NONE
  INTEGER,INTENT(OUT) :: err
  DOUBLE PRECISION :: xhost(*)
  IF(C_ASSOCIATED(cu_BiCGSTAB_ptr,c_NULL_ptr))THEN
    err = CUBCG_PTR_NOT_INITIALIZED
    RETURN
  ENDIF
  err = cu_cpD2H_solDP_intrf(cu_BiCGSTAB_ptr,xhost)
END SUBROUTINE

SUBROUTINE cu_cpH2D_coords(cooRowPtrAhost,cooColPtrAhost,err)
  IMPLICIT NONE
  INTEGER,INTENT(OUT) :: err
  INTEGER :: cooRowPtrAhost(*),cooColPtrAhost(*)
  IF(C_ASSOCIATED(cu_BiCGSTAB_ptr,c_NULL_ptr))THEN
    err = CUBCG_PTR_NOT_INITIALIZED
    RETURN
  ENDIF
  err = cu_cpH2D_coords_intrf(cu_BiCGSTAB_ptr,cooRowPtrAhost,cooColPtrAhost)
END SUBROUTINE cu_cpH2D_coords

SUBROUTINE cu_shutdown(err)
  USE, INTRINSIC  :: iso_c_binding , ONLY : c_NULL_ptr
  IMPLICIT NONE
  INTEGER,INTENT(OUT) :: err
  IF(C_ASSOCIATED(cu_BiCGSTAB_ptr,c_NULL_ptr))THEN
    err = CUBCG_PTR_NOT_INITIALIZED
    RETURN
  ENDIF
  err = cu_shutdown_intrf(cu_BiCGSTAB_ptr)
  cu_BiCGSTAB_ptr = c_NULL_ptr;
END SUBROUTINE 

END MODULE modcu_BiCGSTAB