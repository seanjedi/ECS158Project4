#include<stdio.h>
#include<stdlib.h>
#include<time.h>
#include<string.h>
#include<math.h>
#include<ctype.h>

///////////////////
//Multiply Kernal//
///////////////////
void multiplyKernal(unsigned char* matrix, float* kernal, int order, int windowSizeX, int windowSizeY){
	//Make a temp matrix
	unsigned char* temp = malloc(sizeof(char) * windowSizeX * windowSizeY);
	memcpy(temp, matrix, (windowSizeX*windowSizeY));
	int middle = order/2;

	for(int y = 0; y < windowSizeY; y++){
		for(int x = 0; x < windowSizeX; x++){
			float sum = 0;
			for(int y2 = 0; y2 < order; y2++){
				for(int x2 = 0; x2 < order; x2++){
					int tempX = x + x2 - middle, tempY = y + y2 - middle;
					//Check if tempX or temp Y is within bounds
					if(tempX < 0){
						tempX = 0;
					}else if(tempX >= windowSizeX){
						tempX = windowSizeX - 1;
						
					}
					if(tempY < 0){
						tempY = 0;
					}else if(tempY >= windowSizeY){
						tempY = windowSizeY - 1;
					}
					//Accumulate sum value
					sum += temp[(windowSizeX * tempY) + tempX] * kernal[(order * y2) + x2];
				}
			}
			// Clamp the sum value with range
			if(sum < 0){
				sum = 0;
			}else if(sum > 255){
				sum = 255;
			}

			matrix[(windowSizeX * y) + x] = (unsigned char) sum;
		}
	}
	free(temp);
}


/////////////////
//Main Function//
/////////////////
int main(int argc, char **argv)
{
	char firstLine[10];
	int windowSizeX = 0, windowSizeY = 0, temp, order;
	float sigma;

	//Read in inputs, check if they are correct!
	if(argc != 4){
		fprintf(stderr, "Usage: ./gaussian_blur_serial <input_file> <output_file> <sigma>\n");
		exit(1);
	}
	FILE *fp;
	if((fp = fopen(argv[1], "rb")) == NULL){
		fprintf(stderr, "Error: cannot open file %s\n", argv[1]);
		exit(1);
	}

	if(fgets(firstLine, 4, fp) == NULL){
		fprintf(stderr, "Error: cannot open file %s\n", argv[1]);
		exit(1);
	}

	if(strcmp(firstLine, "P5\n")){
		fprintf(stderr, "Error: invalid PGM information\n");
		exit(1);
	}
	
	if(!fscanf(fp,"%d", &windowSizeX) || !fscanf(fp,"%d", &windowSizeY)){
		fprintf(stderr, "Error: cannot open file %s\n", argv[1]);
		exit(1);
	}

	if(windowSizeX == 0 && windowSizeY == 0){
		fprintf(stderr, "Error: invalid PGM information\n");
		exit(1);
	}

	if(!fscanf(fp,"%d", &temp)){
		fprintf(stderr, "Error: cannot open file %s\n", argv[1]);
		exit(1);
	}

	if(temp != 255){
		fprintf(stderr, "Error: invalid PGM information\n");
		exit(1);
	}
	getc(fp);
	unsigned char* matrix = malloc(sizeof(unsigned char) * windowSizeX * windowSizeY);

	if(fread(matrix, sizeof(unsigned char), windowSizeX*windowSizeY,fp) != windowSizeX*windowSizeY){
		fprintf(stderr, "Error: invalid PGM pixels\n");
		exit(1);
	}

	sigma = atof(argv[3]);
	if(sigma == 0){
		fprintf(stderr, "Error: invalid sigma value\n");
		exit(1);
	}
	order = ceil(sigma * 6);
	if(order%2 == 0){
		order++;
	}
	if(order > windowSizeX || order > windowSizeY){
		fprintf(stderr, "Error: sigma value too big for image size\n");
		exit(1);
	}
	
	//Intialize the kernal
	int middle = ceil(order/2);
	float sum = 0;
	float* kernal = malloc(sizeof(float) * order * order);
	for(int y = 0; y < order; y++){
		for(int x = 0; x < order; x++){
			int x2 = x - middle, y2 = y - middle;
			kernal[(order * y) + x] = (1/(2*M_PI*((sigma * sigma)))) * (pow(M_E, -(((x2 * x2) + (y2 * y2))/(2*(sigma * sigma)))));
			sum += kernal[(order * y) + x];
		}
	}

	for(int y = 0; y < order; y++){
		for(int x = 0; x < order; x++){
			kernal[(order * y) + x] /= sum;
		}
	}


	//Get the function times!
    struct timespec before, after;
    clock_gettime(CLOCK_MONOTONIC, &before);
	multiplyKernal(matrix, kernal, order, windowSizeX, windowSizeY);
	clock_gettime(CLOCK_MONOTONIC, &after);
    unsigned long elapsed_ns = (after.tv_sec - before.tv_sec)*(1E9) + after.tv_nsec - before.tv_nsec;
    double seconds = elapsed_ns / (1E9);
	//Print the function time
	printf("Running time: %f secs\n", seconds);


	char name[255];
	sprintf(name, "%s", argv[2]);
    
	//Output to the file specified
    FILE *fd;
    fd = fopen(name, "w+");
    fprintf(fd, "P5\n");
    fprintf(fd, "%d %d\n", windowSizeX, windowSizeY);
    fprintf(fd, "255\n");
	fwrite(matrix, sizeof(unsigned char), windowSizeX * windowSizeY, fd);

	//Close files and free memory
	fclose(fp);
	fclose(fd);
	free(kernal);
	free(matrix);

	return 0;
}