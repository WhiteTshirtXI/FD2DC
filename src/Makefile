# ------------------Macro-Defs---------------------
#F90=/tmp/shaeri/intel/Compiler/11.0/081/bin/intel64/ifort
#CC=/tmp/shaeri/intel/Compiler/11.0/081/bin/intel64/icc
F90=mpif90
CXX=mpic++
COMPILER_OPTS=-O3
COMP_OPTS_EXT=-I${CULASPARSE_INC_PATH}
#CFLAGS=-O2 -I'/opt/cuda-6.5/include'
CFLAGS=-O3
LIBSPATH=-L${CULASPARSE_LIB_PATH_64} -L.
#LIBS=-lcudart -lcusparse -lcublas -lcuda 
LIBS=-lcula_sparse -lcolamd -lcublas -lcusparse -liomp5 -llammps_ubuntu -lstdc++ -lm -ljpeg -lpng
MODULES=${CULASPARSE_INC_PATH}/cula_sparse_legacy.f90
LAMMPS_LIB=liblammps_ubuntu.a
LAMMPS_INC=-I'/home/shaeri/installed/build/lammps-9Dec14/src'
PP=-cpp
# -------------------End-macro-Defs---------------------------
#modcu_BiCGSTAB.o\
# Here is the link step 
# Here are the compile steps
#library.o:./library.cpp library.h
#	 $(CC) -c $(CFLAGS) ./library.cpp

 OBJ =\
cula_sparse_legacy.o\
precision.o\
real_parameters.o\
parameters.o\
shared_data.o\
modfd_openclose_ops.o\
modfd_set_bc.o\
modfd_tecwrite.o\
mod_create_filenum.o\
modfd_create_geom.o\
modfd_solve_linearsys.o\
modfd_problem_setup.o\
modfd_calc_pre.o\
modfd_calc_temp.o\
modfd_calc_mom.o\
modfd_calc_integrals.o\
solver_sparsekit2.o\
LAMMPS.o\
LAMMPS-wrapper.o\
modlmp_particle.o\
FD2DC.o

FD2DC:$(OBJ)
	 $(F90) -o FD2DC $(OBJ) $(COMPILER_OPTS) $(LIBSPATH) $(LIBS)   

cula_sparse_legacy.o:$(MODULES)
	 $(F90) -c $(COMPILER_OPTS) $(MODULES)

LAMMPS.o:./LAMMPS.F90
	 $(F90) -c $(PP) $(COMPILER_OPTS) ./LAMMPS.F90

LAMMPS-wrapper.o:./LAMMPS-wrapper.cpp LAMMPS-wrapper.h
	 $(CXX) -c $(CFLAGS) $(LAMMPS_INC) ./LAMMPS-wrapper.cpp

modlmp_particle.o:./modlmp_particle.f90 LAMMPS.o LAMMPS-wrapper.o cula_sparse_legacy.o
	 $(F90) -c $(COMPILER_OPTS) $(COMP_OPTS_EXT) $(LAMMPS_INC) ./modlmp_particle.f90

solver_sparsekit2.o:./solver_sparsekit2.f
	 $(F90) -c $(COMPILER_OPTS) ./solver_sparsekit2.f

precision.o:./precision.f90  
	 $(F90) -c $(COMPILER_OPTS) ./precision.f90 

real_parameters.o:./real_parameters.f90 precision.o 
	 $(F90) -c $(COMPILER_OPTS) ./real_parameters.f90 

parameters.o:./parameters.f90  
	 $(F90) -c $(COMPILER_OPTS) ./parameters.f90 

shared_data.o:./shared_data.f90 parameters.o precision.o 
	 $(F90) -c $(COMPILER_OPTS) $(COMP_OPTS_EXT) ./shared_data.f90 

modfd_openclose_ops.o:./modfd_openclose_ops.f90 parameters.o shared_data.o parameters.o shared_data.o 
	 $(F90) -c $(COMPILER_OPTS) ./modfd_openclose_ops.f90 

modfd_set_bc.o:./modfd_set_bc.f90 precision.o shared_data.o real_parameters.o  
	 $(F90) -c $(COMPILER_OPTS) ./modfd_set_bc.f90 

modfd_tecwrite.o:./modfd_tecwrite.f90 precision.o shared_data.o parameters.o precision.o  
	 $(F90) -c $(COMPILER_OPTS) ./modfd_tecwrite.f90 

mod_create_filenum.o:./mod_create_filenum.f90 precision.o 
	 $(F90) -c $(COMPILER_OPTS) ./mod_create_filenum.f90 

modfd_create_geom.o:./modfd_create_geom.f90 shared_data.o precision.o parameters.o real_parameters.o modfd_tecwrite.o   
	 $(F90) -c $(COMPILER_OPTS) ./modfd_create_geom.f90 

modfd_solve_linearsys.o:./modfd_solve_linearsys.f90 precision.o parameters.o shared_data.o real_parameters.o  
	 $(F90) -c $(COMPILER_OPTS) ./modfd_solve_linearsys.f90 

#modcu_BiCGSTAB.o:./modcu_BiCGSTAB.f90  
#	 $(F90) -c $(COMPILER_OPTS) ./modcu_BiCGSTAB.f90 

#modcu_BiCGSTAB.o
modfd_problem_setup.o:./modfd_problem_setup.f90 real_parameters.o parameters.o precision.o shared_data.o modfd_set_bc.o modfd_create_geom.o modfd_tecwrite.o modfd_solve_linearsys.o parameters.o cula_sparse_legacy.o LAMMPS.o LAMMPS-wrapper.o modlmp_particle.o
	 $(F90) -c $(COMPILER_OPTS) ./modfd_problem_setup.f90 

#modcu_BiCGSTAB.o
modfd_calc_pre.o:./modfd_calc_pre.f90 parameters.o real_parameters.o precision.o modfd_set_bc.o shared_data.o modfd_solve_linearsys.o solver_sparsekit2.o 
	 $(F90) -c $(COMPILER_OPTS) ./modfd_calc_pre.f90 

#modcu_BiCGSTAB.o
modfd_calc_temp.o:./modfd_calc_temp.f90 parameters.o real_parameters.o precision.o modfd_set_bc.o shared_data.o modfd_solve_linearsys.o solver_sparsekit2.o 
	 $(F90) -c $(COMPILER_OPTS) ./modfd_calc_temp.f90 

#modcu_BiCGSTAB.o 
modfd_calc_mom.o:./modfd_calc_mom.f90 parameters.o real_parameters.o shared_data.o modfd_set_bc.o precision.o modfd_solve_linearsys.o solver_sparsekit2.o
	 $(F90) -c $(COMPILER_OPTS) ./modfd_calc_mom.f90 

modfd_calc_integrals.o:./modfd_calc_integrals.f90 precision.o real_parameters.o shared_data.o parameters.o modfd_solve_linearsys.o  
	 $(F90) -c $(COMPILER_OPTS) ./modfd_calc_integrals.f90 

#modcu_BiCGSTAB.o
FD2DC.o:./FD2DC.f90 real_parameters.o precision.o modfd_openclose_ops.o modfd_problem_setup.o shared_data.o parameters.o modfd_set_bc.o modfd_calc_pre.o modfd_calc_temp.o modfd_calc_mom.o mod_create_filenum.o modfd_calc_integrals.o cula_sparse_legacy.o modfd_tecwrite.o modfd_create_geom.o solver_sparsekit2.o LAMMPS.o LAMMPS-wrapper.o $(LAMMPS_LIB)
	 $(F90) -c $(COMPILER_OPTS) FD2DC.f90 
# This entry allows you to type " make clean " to get rid of
# all object and module files 
clean:
	rm -f -r f_{files,modd}* *.o *.mod *.M *.d V*.inc *.vo \
	V*.f *.dbg album F.err
 
