#include<stdio.h>
#include<stdlib.h>
#include<time.h>
#include<string.h>
#include<math.h>

///////////////////
//Multiply Kernal//
///////////////////
void multiplyKernal(float* matrix, float* kernal, int order, int windowSizeX, int windowSizeY){
	float temp[windowSizeX * windowSizeY];
	memcpy(temp, matrix, (windowSizeX*windowSizeY) + 1;
	int middle = ceil(order/2);

	for(int y = 0; y < windowSizeY; y++){
		for(int x = 0; x < windowSizeX; x++){
			float sum = 0;
			for(int y2 = 0; y2 < order; y2++){
				for(int x2 = 0; x2 < order; x2++){
					int tempX = x - middle + x2, tempY = y - middle + y2;
					if(tempX < 0){
						tempX = 0;
					}else if(tempX > windowSizeX){
						tempX = windowSizeX;
					}
					if(tempY < 0){
						tempY = 0;
					}else if(tempY > windowSizeY){
						tempY = windowSizeY;
					}
					sum += temp[(windowSizeX * tempY) + tempX] * kernal[(order * x2) + y2];
				}
			}
			matrix[(windowSizeX * y) + x] = sum;
		}
	}
}


/////////////////
//Main Function//
/////////////////
int main(int argc, char **argv)
{
	char* firstLine, secondLine, thirdLine;
	int windowSizeX, windowSizeY;
	float sigma, order, *matrix;

	//Read in inputs, check if they are correct!
	if(arc != 4){
		fprintf(stderr, "Usage: ./gaussian_blur_serial <input_file> <output_file> <sigma>\n");
		exit(1);
	}
	FILE *fp;
	fp = fopen(argv[1], 'r');
	if(fp == NULL){
		fprintf(stderr, "Error: cannot open file %s\n", argv[1]);
		exit(1);
	}
	fgets(firstLine, 4, fp);
	if(strcmp(firstLine, "P5")){
		fprintf(stderr, "Error: invalid PGM information\n");
		exit(1);
	}
	fgets(secondLine, 10, fp);
	int n = sscanf(str, "%d %d", &windowSizeX, &windowSizeY);
	if(n != 1){
		fprintf(stderr, "Error: invalid PGM information\n");
	}

	fgets(thirdLine, 10, fp);
	if(strcmp(thirdLine, "255")){
		fprintf(stderr, "Error: invalid PGM information\n");
		exit(1);
	}
	sigma = atof(argv[3]);
	if(sigma == 0){
		fprintf(stderr, "Error: invalid sigma value\n");
		exit(1);
	}
	order = ceil(sigma * 6);
	if(order > windowSizeX || order > windowSizeY){
		fprintf(stderr, "Error: sigma value too big for image size\n");
		exit(1);
	}

	fread(matrix, sizeof(float),(windowSizeX * windowSizeY),fp);
	if(ferror(fp)){
		fprintf(stderr, "Error: invalid PGM pixels\n");
		exit(1);
	}

	float kernal[order*order];
	for(int y = 0; y < order; y++){
		for(int x = 0; x < order; x++){
			kernal[(order * y) + x] = (1/(2*M_PI*(pow(sigma,2)))) * (pow(M_E, -((pow(x,2) + pow(y,2))/(2*pow(sigma,2)))));
		}
	}

    struct timespec before, after;
    clock_gettime(CLOCK_MONOTONIC, &before);

	multiplyKernal(matrix, kernal, order, windowSizeX, windowSizeY);
    
	clock_gettime(CLOCK_MONOTONIC, &after);
    unsigned long elapsed_ns = (after.tv_sec - before.tv_sec)*(1E9) + after.tv_nsec - before.tv_nsec;
    double seconds = elapsed_ns / (1E9);

	printf("Running time: %f secs\n", seconds);


	char name[255];
	sprintf(name, "%s", argv[2]);
    
    FILE *fd;
    fd = fopen(name, "w+");
    fprintf(fd, "P5\n");
    fprintf(fd, "%d %d\n", windowSizeX, windowSizeY);
    fprintf(fd, "255\n",);
    int count = 0;

    for(int y = 0; y < windowSizeY; y++) {
        for(int x = 0; x < windowSizeX; x++) {
            fprintf(fp, "%d ", matrix[(windowSizeX * y) + x]);
        }
		fprintf(fp, "\n");
    }


	return 0;
}