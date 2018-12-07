CC := gcc
CCU:= nvcc
CFLAGS := -Wall -Werror -O2 
CUFLAGS := -Xcompiler -Wall -Xcompiler -Werror -O2

prog1 = gaussian_blur_serial.c
prog2 = gaussian_blur_cuda.cu

exes = gaussian_blur_serial gaussian_blur_cuda

all: $(exes)

gaussian_blur_serial: $(prog1)
	$(CC) $(CFLAGS) $(prog1) -o $@ -lm

gaussian_blur_cuda: $(prog2)
	$(CCU) $(CUFLAGS) -o gaussian_blur_cuda gaussian_blur_cuda.cu -lm

clean:
	rm -f $(exes) *.pgm

