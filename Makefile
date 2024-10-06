# Makefile for 3D Boids Flocking Simulation with ImGui

# Compiler and linker
NVCC = nvcc
CXX = g++
CXXFLAGS = -std=c++11 -O3
INCLUDES = -I/usr/local/cuda/include -I/usr/include/GL -I./imgui
LIBS = -lglut -lGL -lGLU -lGLEW

# Target executable
TARGET = boids_simulation

# Source and object files
CUDA_SRCS = boids_simulation.cu
CUDA_OBJS = $(CUDA_SRCS:.cu=.o)
IMGUI_SRCS = imgui/imgui.cpp imgui/imgui_draw.cpp imgui/imgui_widgets.cpp imgui/imgui_tables.cpp imgui/imgui_impl_glut.cpp imgui/imgui_impl_opengl2.cpp
IMGUI_OBJS = $(IMGUI_SRCS:.cpp=.o)

# Default target
all: $(TARGET)

# Compile CUDA source file
%.o: %.cu
	$(NVCC) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# Compile ImGui source file
%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# Link object files to create the executable
$(TARGET): $(CUDA_OBJS) $(IMGUI_OBJS)
	$(NVCC) $(CXXFLAGS) $(CUDA_OBJS) $(IMGUI_OBJS) -o $@ $(LIBS)

# Clean up
clean:
	rm -f $(CUDA_OBJS) $(IMGUI_OBJS) $(TARGET)

.PHONY: all clean
