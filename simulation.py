import genesis as gs
import numpy as np
import trimesh
import utils

class ClothSimulation:
    def __init__(self):
        self.scene = None
        self.camera = None
        self.cloth = None
        self.robot = None
        
    def initialize_genesis(self):
        """Initialize Genesis with Metal backend"""
        gs.init(backend=gs.metal)
        
    def create_scene(self):
        """Create the simulation scene with viewer and renderer"""
        self.scene = gs.Scene(
            sim_options=gs.options.SimOptions(
                dt=4e-3,  
                substeps=10,  
            ),
            viewer_options=gs.options.ViewerOptions(
                res=(1280, 960),
                camera_pos=(3.5, 0.0, 2.5),
                camera_lookat=(0.0, 0.0, 0.5),
                camera_fov=40,
                max_FPS=60,
            ),
            renderer=gs.renderers.Rasterizer(),
            show_viewer=True,
        )
        
    def add_ground_plane(self):
        """Add ground plane to the scene"""
        plane = self.scene.add_entity(
            morph=gs.morphs.Plane(),
        )
        return plane
        
    def add_cloth(self, mesh_file="assets/tshirt.glb", scale=0.3, position=(0, 0, 0.1)):
        """Add cloth entity to the scene"""
        self.cloth = self.scene.add_entity(
            material=gs.materials.PBD.Cloth(
                stretch_compliance=1e-6, 
                bending_compliance=1e-4, 
                air_resistance=0.01, 
            ),
            morph=gs.morphs.Mesh(
                file=mesh_file,
                scale=scale, 
                pos=position,
                euler=(0.0, 0, 0.0),
            ),
            surface=gs.surfaces.Default(
                vis_mode="visual",
            ),
        )
        return self.cloth
        
    def calculate_robot_position(self, cloth_mesh_file="assets/tshirt.glb", offset=(0.3, -0.2, 0.0)):
        """Calculate robot position based on cloth mesh bounds"""
        cloth_extent = utils.MeshUtils().get_mesh_extent(cloth_mesh_file)
        print(f"Cloth bounds: {cloth_extent}")
        
        # Use the center of the cloth bounds for robot positioning
        cloth_center = (cloth_extent[0] + cloth_extent[1]) / 2
        robot_pos = (
            float(cloth_center[0]) + offset[0], 
            float(cloth_center[1]) + offset[1], 
            offset[2]
        )
        print(f"Robot position: {robot_pos}")
        return robot_pos
        
    def add_robot(self, robot_file="assets/low_cost_robot_arm/low_cost_robot_arm.xml", position=None):
        """Add robot entity to the scene"""
        if position is None:
            position = self.calculate_robot_position()
            
        self.robot = self.scene.add_entity(
            morph=gs.morphs.MJCF(
                file=robot_file,
                pos=position,
                euler=(0.0, 0, 0.0),
            ),
            surface=gs.surfaces.Default(
                vis_mode="visual",
            ),
        )
        return self.robot
        
    def add_camera(self, resolution=(640, 480), position=(3.5, 0.0, 2.5), lookat=(0, 0, 0.5), fov=30):
        """Add camera for recording"""
        self.camera = self.scene.add_camera(
            res=resolution,
            pos=position,
            lookat=lookat,
            fov=fov,
            GUI=False,
        )
        return self.camera
        
    def build_scene(self):
        """Build the complete scene"""
        self.scene.build()
        
    def run_simulation(self, horizon=500, video_path="output/cloth_simulation.mp4", fps=60):
        """Run the simulation with camera recording"""
        if self.camera is None:
            raise ValueError("Camera must be added before running simulation")
            
        self.camera.start_recording()
        
        print("Starting simulation with video recording...")
        print(f"Video will be saved to: {video_path}")

        for i in range(horizon):
            self.scene.step()
            
            # Print progress every 100 steps
            if i % 100 == 0:
                print(f"Step {i}/{horizon}")
                
            # Move camera in circular motion around the cloth
            self.camera.set_pose(
                pos=(3.0 * np.sin(i / 60), 3.0 * np.cos(i / 60), 2.5),
                lookat=(0, 0, 0.5),
            )
            self.camera.render()

        self.camera.stop_recording(save_to_filename=video_path, fps=fps)
        print(f"Simulation complete! Video saved to {video_path}")

def main():
    """Main simulation function"""
    # Create simulation instance
    sim = ClothSimulation()
    
    # Initialize Genesis
    sim.initialize_genesis()
    
    # Create scene
    sim.create_scene()
    
    # Add entities
    sim.add_ground_plane()
    sim.add_cloth()
    sim.add_robot()
    sim.add_camera()
    
    # Build and run simulation
    sim.build_scene()
    sim.run_simulation()

if __name__ == "__main__":
    main()