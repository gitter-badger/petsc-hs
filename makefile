# PETSC_DIR = ${HOME}/petsc-3.6.2/     

PETSC_DIR_ARCH = ${PETSC_DIR}/arch-darwin-c-debug
# PETSC_DIR_ARCH = ${PETSC_DIR}/arch-darwin-c-debug-complex

PETSC_DIR_ARCH_INCLUDE = ${PETSC_DIR_ARCH}/include
SRCDIR = ${CURDIR}/src/Numerical/PETSc
SRCPARDIR = ${CURDIR}/src/Numerical
CBITS = ${CURDIR}/src/cbits
TESTDIR = ${CURDIR}/test
LIBDIR = ${CURDIR}/lib
EXAMPLEDIR = ${CURDIR}/examples

main:
	make step1
	make step2
	make step3

step1:
	ghc ${SRCDIR}/Internal/InlineC.hs -isrc/

step2:
	cc -w -c ${SRCDIR}/Internal/InlineC.c -o ${LIBDIR}/InlineC_c.o -I${PETSC_DIR_ARCH}/include -I${PETSC_DIR}/include

# step3:
# 	ghci ${EXAMPLEDIR}/TestMain2.hs ${SRCDIR}/Internal/InlineC.hs  ${LIBDIR}/InlineC_c.o  ${LIBDIR}/Internal.o -isrc/ -L${PETSC_DIR_ARCH}/lib -lpetsc -lmpich

step3:
	ghci ${SRCDIR}/Test.hs ${SRCDIR}/Internal/InlineC.hs  ${LIBDIR}/InlineC_c.o  ${LIBDIR}/Internal.o -isrc/ -L${PETSC_DIR_ARCH}/lib -lpetsc -lmpich



reload:
	make step3


ARGS="--resolver nightly"

stack_build:
	chmod +x stack-build.sh
	./stack-build.sh ${ARGS} ${PETSC_DIR} ${PETSC_ARCH}









clean:
	rm lib/*.o
	rm src/Numerical/PETSc/*.o
