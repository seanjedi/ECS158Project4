CC := gcc
CFLAGS := -Wall -Werror -O2 

prog1 = gaussian_blur_serial.c

exes = gaussian_blur_serial  

all: $(exes)

gaussian_blur_serial: $(prog1)
	$(CC) $(CFLAGS) $(prog1) -o $@ -lm

clean:
	rm -f $(exes) *.pgm

