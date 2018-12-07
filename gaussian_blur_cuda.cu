#include<stdio.h>
#include<stdlib.h>
#include<time.h>
#include<string.h>
#include<math.h>

#define cuda_check(ret) _cuda_check((ret), __FILE__, __LINE__)
inline void _cuda_check(cudaError_t ret, const char *file, int line){
    if(ret != cudaSuccess) {
        fprintf(stderr, "CudaError: %s %s %d\n", cudaGetErrorString(ret), file, line);
        exit(1);
  }
}

#define DIV_ROUND_UP(n, d) (((n) + (d) - 1) / (d))

// Kernal Multiply Function
__global__ void matrix_multiply_kernel(unsigned char *temp, unsigned char *matrix, float *kernal, int order, int middle, int windowSizeX, int windowSizeY){
	int y = blockIdx.y * blockDim.y + threadIdx.y;
	int x = blockIdx.x * blockDim.x + threadIdx.x;
	float sum = 0.0;

	if(y >= windowSizeY || x >= windowSizeX){
		return;
	}

    for(int y2 = 0; y2 < order; y2++){
		for(int x2 = 0; x2 < order; x2++){
			int tempX = x - middle + x2, tempY = y - middle + y2;
			if(tempX < 0){
				tempX = 0;
			}else if(tempX >= windowSizeX){
				tempX = windowSizeX;
			}
			if(tempY < 0){
				tempY = 0;
			}else if(tempY >= windowSizeY){
				tempY = windowSizeY;
			}
			sum += temp[(windowSizeX * tempY) + tempX] * kernal[(order * x2) + y2];
		}
	}

	if(sum < 0)
		sum = 0;
	else if(sum > 255)
		sum = 255;
		
	matrix[(windowSizeX * y) + x] = (unsigned char) sum;
        
}

///////////////////
//Multiply Kernal//
///////////////////
void multiplyKernal(unsigned char* matrix, float* kernal, int order, int windowSizeX, int windowSizeY){
	int middle = ceil(order/2);
    unsigned char *temp, *matrix_d;
    float *kernal_d;
    //Number of blocks we need
    int blocks = ceil(((float)windowSizeX*(float)windowSizeY)/1024);
    int kernal_size = order*order*sizeof(float);
    int matrix_size = windowSizeX * windowSizeY * sizeof(char);
    //Initialize Kernal Data
    cuda_check(cudaMalloc(&temp, matrix_size));
    cuda_check(cudaMalloc(&matrix_d, matrix_size));
    cuda_check(cudaMalloc(&kernal_d, kernal_size));
    // Copy Data to Kernal
    cuda_check(cudaMemcpy(temp, matrix, matrix_size, cudaMemcpyHostToDevice));
    cuda_check(cudaMemcpy(matrix_d, matrix, matrix_size, cudaMemcpyHostToDevice));
    cuda_check(cudaMemcpy(kernal_d, kernal, kernal_size, cudaMemcpyHostToDevice));

    //Kernal Functions
    dim3 block_dim(32, 32);
    dim3 grid_dim(DIV_ROUND_UP(windowSizeX, block_dim.x), DIV_ROUND_UP(windowSizeY, block_dim.y));
    matrix_multiply_kernel<<<grid_dim, block_dim>>>(temp, matrix_d, kernal_d, order, middle, windowSizeX, windowSizeY);
    cuda_check(cudaPeekAtLastError());
    cuda_check(cudaDeviceSynchronize());

    //Copy back to Host
    cuda_check(cudaMemcpy(matrix, matrix_d, matrix_size, cudaMemcpyDeviceToHost));
    //Free data
	cuda_check(cudaFree(temp));
    cuda_check(cudaFree(matrix_d));
    cuda_check(cudaFree(kernal_d));
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

	// unsigned char* matrix = malloc(sizeof(unsigned char) * windowSizeX * windowSizeY);
	unsigned char matrix[windowSizeX * windowSizeY];

	if(fread(matrix, sizeof(unsigned char), windowSizeX*windowSizeY,fp) != (unsigned)(windowSizeX*windowSizeY)){
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
	
	int middle = ceil(order/2);
	// float* kernal = malloc(sizeof(float) * order * order);
	float kernal [order*order];
	for(int y = 0; y < order; y++){
		for(int x = 0; x < order; x++){
			int x2 = x - middle, y2 = y - middle;
			kernal[(order * y) + x] = (1/(2*M_PI*(pow(sigma,2)))) * (pow(M_E, -((pow(x2,2) + pow(y2,2))/(2*pow(sigma,2)))));
		}
	}

    struct timespec before, after;
    clock_gettime(CLOCK_MONOTONIC, &before);
    //Get TIme!
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
    fprintf(fd, "255\n");

    for(int y = 0; y < windowSizeY; y++) {
        for(int x = 0; x < windowSizeX; x++) {
            fprintf(fd, "%c", matrix[(windowSizeX * y) + x]);
        }
    }

	fclose(fp);
	fclose(fd);
	// free(kernal);
	// free(matrix);

	return 0;
}