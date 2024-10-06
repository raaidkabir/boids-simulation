#include <GL/glut.h>
#include <cuda_runtime.h>
#include <iostream>
#include <vector>
#include <cmath>
#include "imgui.h"
#include "imgui_impl_glut.h"
#include "imgui_impl_opengl2.h"

const float maxSpeed = 2.0f;
const float maxForce = 0.5f;
const int numBoids = 500;

// Global variables for ImGui
float visualRange = 50.0f;
float cohesion = 0.0f;
float separation = 0.0f;
float alignment = 0.0f;

struct Boid {
    float x, y, z;
    float vx, vy, vz;
};

Boid* d_boids;
std::vector<Boid> boids;

__device__ void limitVector(float& x, float& y, float& z, float max) {
    float mag = sqrt(x * x + y * y + z * z);
    if (mag > max) {
        x = (x / mag) * max;
        y = (y / mag) * max;
        z = (z / mag) * max;
    }
}

__device__ void applyBoundary(Boid& boid, float minX, float maxX, float minY, float maxY, float minZ, float maxZ, float margin) {
    if (boid.x < minX + margin) boid.vx += maxForce;
    else if (boid.x > maxX - margin) boid.vx -= maxForce;

    if (boid.y < minY + margin) boid.vy += maxForce;
    else if (boid.y > maxY - margin) boid.vy -= maxForce;

    if (boid.z < minZ + margin) boid.vz += maxForce;
    else if (boid.z > maxZ - margin) boid.vz -= maxForce;
}

__global__ void applyRulesKernel(Boid* d_boids, int numBoids, float visualRange, float cohesion, float separation, float alignment) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= numBoids) return;

    Boid boid = d_boids[i];
    float sepX = 0.0f, sepY = 0.0f, sepZ = 0.0f;
    float alignX = 0.0f, alignY = 0.0f, alignZ = 0.0f;
    float cohX = 0.0f, cohY = 0.0f, cohZ = 0.0f;
    int count = 0;

    for (int j = 0; j < numBoids; ++j) {
        if (i == j) continue;
        Boid other = d_boids[j];
        float dx = other.x - boid.x;
        float dy = other.y - boid.y;
        float dz = other.z - boid.z;
        float distance = sqrt(dx * dx + dy * dy + dz * dz);

        if (distance > 0 && distance < visualRange) {
            sepX -= dx / distance; // Separation
            sepY -= dy / distance;
            sepZ -= dz / distance;
            alignX += other.vx;    // Alignment
            alignY += other.vy;
            alignZ += other.vz;
            cohX += other.x;       // Cohesion
            cohY += other.y;
            cohZ += other.z;
            count++;
        }
    }

    if (count > 0) {
        alignX /= count;
        alignY /= count;
        alignZ /= count;
        cohX /= count;
        cohY /= count;
        cohZ /= count;

        alignX = (alignX - boid.vx) * alignment;
        alignY = (alignY - boid.vy) * alignment;
        alignZ = (alignZ - boid.vz) * alignment;
        cohX = (cohX - boid.x) * cohesion;
        cohY = (cohY - boid.y) * cohesion;
        cohZ = (cohZ - boid.z) * cohesion;

        sepX *= separation;
        sepY *= separation;
        sepZ *= separation;

        limitVector(alignX, alignY, alignZ, maxForce);
        limitVector(cohX, cohY, cohZ, maxForce);
        limitVector(sepX, sepY, sepZ, maxForce);

        boid.vx += alignX + cohX + sepX;
        boid.vy += alignY + cohY + sepY;
        boid.vz += alignZ + cohZ + sepZ;
    }

    limitVector(boid.vx, boid.vy, boid.vz, maxSpeed);
    applyBoundary(boid, 0, 800, 0, 600, 0, 600, 50); // Apply soft boundaries
    boid.x += boid.vx;
    boid.y += boid.vy;
    boid.z += boid.vz;

    __syncthreads();

    d_boids[i] = boid;
}

void initializeBoids(int numBoids) {
    boids.clear();
    for (int i = 0; i < numBoids; ++i) {
        Boid boid = {
            static_cast<float>(rand() % 800), // x position
            static_cast<float>(rand() % 600), // y position
            static_cast<float>(rand() % 600), // z position
            (static_cast<float>(rand()) / RAND_MAX) * 2 - 1, // x velocity
            (static_cast<float>(rand()) / RAND_MAX) * 2 - 1, // y velocity
            (static_cast<float>(rand()) / RAND_MAX) * 2 - 1  // z velocity
        };
        boids.push_back(boid);
    }
    cudaMalloc(&d_boids, numBoids * sizeof(Boid));
    cudaMemcpy(d_boids, boids.data(), numBoids * sizeof(Boid), cudaMemcpyHostToDevice);
}

void applyRules(int numBoids, float cohesion, float separation, float alignment) {
    int blockSize = 1024;
    int numBlocks = (numBoids + blockSize - 1) / blockSize;
    applyRulesKernel<<<numBlocks, blockSize>>>(d_boids, numBoids, visualRange, cohesion, separation, alignment);
    cudaMemcpy(boids.data(), d_boids, numBoids * sizeof(Boid), cudaMemcpyDeviceToHost);
}

void drawPyramid(Boid boid) {
    float size = 5.0f; // size of the pyramid

    // Calculate the normalized velocity vector
    float mag = sqrt(boid.vx * boid.vx + boid.vy * boid.vy + boid.vz * boid.vz);
    float nx = boid.vx / mag;
    float ny = boid.vy / mag;
    float nz = boid.vz / mag;

    // Base vertices of the pyramid
    float base1[3] = {boid.x - size, boid.y - size, boid.z - size};
    float base2[3] = {boid.x + size, boid.y - size, boid.z - size};
    float base3[3] = {boid.x, boid.y + size, boid.z - size};

    // Tip of the pyramid pointing in the direction of the velocity vector
    float tip[3] = {boid.x + nx * size * 2, boid.y + ny * size * 2, boid.z + nz * size * 2};

    glBegin(GL_TRIANGLES);

    // Base of the pyramid
    glColor3f(0.0f, 0.0f, 1.0f); 
    glVertex3fv(base1);
    glVertex3fv(base2);
    glVertex3fv(base3);

    // Sides of the pyramid
    glColor3f(0.0f, 0.0f, 1.0f); 
    glVertex3fv(base1);
    glVertex3fv(base2);
    glVertex3fv(tip);

    glColor3f(0.0f, 1.0f, 0.0f); 
    glVertex3fv(base2);
    glVertex3fv(base3);
    glVertex3fv(tip);

    glColor3f(1.0f, 0.0f, 0.0f);
    glVertex3fv(base3);
    glVertex3fv(base1);
    glVertex3fv(tip);

    glEnd();
}

void display() {
    // Start the ImGui frame
    ImGui_ImplOpenGL2_NewFrame();
    ImGui_ImplGLUT_NewFrame();
    ImGui::NewFrame();

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    gluLookAt(400, 300, 600, 400, 300, 0, 0, 1, 0); // Adjust camera position

    for (const auto& boid : boids) {
        drawPyramid(boid);
    }

    // Create ImGui window
    ImGui::Begin("Boids Parameters");
    ImGui::SliderFloat("Visual Range", &visualRange, 50, 500);
    ImGui::SliderFloat("Cohesion", &cohesion, -0.2f, 0.1f);
    ImGui::SliderFloat("Separation", &separation, -0.2f, 0.1f);
    ImGui::SliderFloat("Alignment", &alignment, -0.2f, 0.1f);
    ImGui::End();

    // Rendering ImGui
    ImGui::EndFrame();
    ImGui::Render();
    ImGui_ImplOpenGL2_RenderDrawData(ImGui::GetDrawData());

    glutSwapBuffers();
}

void update(int value) {
    applyRules(numBoids, cohesion, separation, alignment);
    glutPostRedisplay();
    glutTimerFunc(16, update, 0);
}

void init() {
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glEnable(GL_DEPTH_TEST);
    glMatrixMode(GL_PROJECTION);
    gluPerspective(45.0, 4.0 / 3.0, 1.0, 1000.0);
    glMatrixMode(GL_MODELVIEW);
}

int main(int argc, char** argv) {
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);
    glutInitWindowSize(800, 600);
    glutCreateWindow("3D Boids Flocking Simulation");

    // Initialize ImGui
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    ImGui::StyleColorsDark();
    ImGui_ImplGLUT_Init();
    ImGui_ImplGLUT_InstallFuncs();
    ImGui_ImplOpenGL2_Init();

    init();
    initializeBoids(numBoids);

    glutDisplayFunc(display);
    glutTimerFunc(16, update, 0);
    glutMainLoop();

    cudaFree(d_boids);

    // Cleanup ImGui
    ImGui_ImplOpenGL2_Shutdown();
    ImGui_ImplGLUT_Shutdown();
    ImGui::DestroyContext();

    return 0;
}
