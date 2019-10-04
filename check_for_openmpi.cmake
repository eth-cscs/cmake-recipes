# Sets OPENMPI_FOUND to ON if OpenMPI was found and to OFF otherwise.
#
function(check_for_openmpi)
  execute_process(COMMAND mpirun --version OUTPUT_VARIABLE MPIRUN_OUTPUT)
  string(FIND "${MPIRUN_OUTPUT}" "Open MPI" OMPI_POS)
  if(OMPI_POS STREQUAL "-1")
    set(OPENMPI_FOUND OFF PARENT_SCOPE)
  else()
    set(OPENMPI_FOUND ON PARENT_SCOPE)
  endif()
endfunction()
