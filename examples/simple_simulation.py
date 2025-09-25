#!/usr/bin/env python3
"""
Simple Isaac Sim simulation example
This script demonstrates basic Isaac Sim setup and a simple scene
"""

import sys
import os

# Add Isaac Sim Python packages to path
sys.path.append('/isaac-sim/python_packages')

from omni.isaac.kit import SimulationApp

# Configuration for the simulation
CONFIG = {
    "headless": True,  # Set to False for GUI
    "width": 1280,
    "height": 720,
}

def main():
    """Main simulation function"""
    
    # Initialize Isaac Sim
    print("Initializing Isaac Sim...")
    simulation_app = SimulationApp(CONFIG)
    
    # Import additional modules after SimulationApp initialization
    import omni.usd
    from omni.isaac.core import World
    from omni.isaac.core.objects import DynamicCuboid
    from omni.isaac.core.materials import PreviewSurface
    
    try:
        # Create a new world
        print("Creating simulation world...")
        world = World(stage_units_in_meters=1.0)
        
        # Add a ground plane
        world.scene.add_default_ground_plane()
        
        # Create a dynamic cube
        print("Adding dynamic objects...")
        cube_material = PreviewSurface(
            prim_path="/World/CubeMaterial",
            color=[0.2, 0.4, 0.8]  # Blue color
        )
        
        cube = world.scene.add(
            DynamicCuboid(
                name="dynamic_cube",
                prim_path="/World/DynamicCube",
                position=[0.0, 0.0, 2.0],  # Start 2 meters above ground
                size=0.5,  # 0.5m cube
                material=cube_material
            )
        )
        
        # Reset the world to initialize physics
        print("Resetting world...")
        world.reset()
        
        # Run simulation for a specified number of steps
        print("Running simulation...")
        for i in range(1000):  # Run for 1000 steps
            # Step the simulation
            world.step(render=not CONFIG["headless"])
            
            # Print cube position every 100 steps
            if i % 100 == 0:
                cube_position = cube.get_world_pose()[0]
                print(f"Step {i}: Cube position = {cube_position}")
        
        print("Simulation completed successfully!")
        
    except Exception as e:
        print(f"Error during simulation: {e}")
        return 1
    
    finally:
        # Clean up
        print("Cleaning up...")
        simulation_app.close()
    
    return 0

if __name__ == "__main__":
    sys.exit(main())