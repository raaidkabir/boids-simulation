# 3D Boids Flocking Simulation with CUDA and OpenGL

## Overview
This project simulates 3D Boids flocking behavior using CUDA for parallel processing and OpenGL for real-time visualization. ImGui provides a user interface for tweaking simulation parameters such as visual range, cohesion, separation, and alignment.

## Features
- **CUDA-powered computation**: Boid movement is calculated in parallel using GPU acceleration.
- **OpenGL rendering**: The simulation visualizes boids as 3D pyramids.
- **ImGui Interface**: A real-time user interface to adjust flocking parameters interactively.

## Prerequisites

You will need the following dependencies:
- **CUDA Toolkit**: For compiling and running CUDA code.
- **OpenGL and GLUT**: For rendering 3D graphics.
- **GLEW**: For OpenGL extension loading.
- **ImGui**: For the graphical interface.

### System Requirements
- A **CUDA-capable GPU**.
- **OpenGL 2.0 or higher**.

## Building and Running

### Step 1: Install Dependencies

Make sure you have the necessary libraries installed. For Ubuntu, you can install them using:

```bash
sudo apt-get install freeglut3-dev libglew-dev
```

You will also need the CUDA toolkit, which can be installed from [NVIDIA's CUDA Toolkit page](https://developer.nvidia.com/cuda-toolkit).

### Step 2: Compile and Run the Simulation

This project uses a **Makefile** for compiling the code. To build and run the simulation, follow these steps:

1. **Build the Project**:
   Run the following command to compile the CUDA and OpenGL files:

   ```bash
   make
   ```

2. **Run the Simulation**:
   After building, execute the simulation:

   ```bash
   ./boids_simulation
   ```

### Step 3: Adjust Parameters
- Use the ImGui interface, which appears on the right of the simulation window, to adjust:
  - **Visual Range**: Adjust the range at which boids perceive their neighbors.
  - **Cohesion**: Adjust the attraction of boids towards each other.
  - **Separation**: Adjust how strongly boids avoid each other.
  - **Alignment**: Adjust how much boids align with the average velocity of their neighbors.

### Step 4: Clean Up
To clean the build directory (remove object files and the executable), run:

```bash
make clean
```

## Code Structure

- **CUDA Code**: The core of the boid behavior simulation is implemented in `boids_simulation.cu` using CUDA to handle the parallel computation of boid positions and velocities.
- **OpenGL and GLUT**: Rendering is handled using OpenGL and GLUT. The boids are visualized as 3D pyramids.
- **ImGui**: The graphical user interface is created using the ImGui library to provide real-time control over the boid parameters.

## License
This project is licensed under the MIT License.