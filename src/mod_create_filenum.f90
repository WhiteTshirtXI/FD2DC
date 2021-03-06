!    This file is part of FD2DC.
!
!    FD2DC is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation, either version 3 of the License, or
!    (at your option) any later version.
!
!    FD2DC is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU General Public License for more details.
!
!    You should have received a copy of the GNU General Public License
!    along with FD2DC.  If not, see <http://www.gnu.org/licenses/>.

MODULE mod_create_filenum
PRIVATE
PUBLIC :: create_filenum
CONTAINS
!===================================================================================
SUBROUTINE create_filenum(filecount,fn)
!
! sets up filenum and inputfilenum
! ie output_00000, output_00001 etc for time dependent output
!
USE precision,             ONLY : r_single


IMPLICIT NONE

INTEGER                                       :: n5,n4,n3,n2,n1,nch
INTEGER,INTENT(IN)                            :: filecount
CHARACTER(LEN = 5), DIMENSION(:), INTENT(OUT) :: fn
CHARACTER(LEN=1)   :: c00000,c0000,c000,c00,c0


    nch=1
  Do n5=0,9  
   DO n4=0,9 
    DO n3=0,9
     DO n2=0,9
      DO n1=0,9
      
      C00000=ACHAR(48+n5)
       C0000=ACHAR(48+n4) 
        c000=ACHAR(48+n3)
         c00=ACHAR(48+n2)
          c0=ACHAR(48+n1)

           fn(nch)=C00000//C0000//C000//C00//C0
           IF(nch==filecount)GO TO 100

           nch=nch+1

      END DO
     END DO
    END DO
   END DO 
  END DO 
    100 CONTINUE


END SUBROUTINE create_filenum
END MODULE mod_create_filenum