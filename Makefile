CC := gcc
CFLAGS := -Wall -Werror -O2 

prog1 = gaussian_blur_serial.c

exes = gaussian_blur_serial  

all: $(exes)

mmm_mpi: $(prog1)
	$(CC) $(CFLAGS) $(prog1) -o $@ 

mandelbrot_mpi: $(prog2)
	$(CC) $(CFLAGS) $(prog2) -o $@ -lm

clean:
	rm -f $(exes) *.pgm

