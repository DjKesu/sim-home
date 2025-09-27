# mesh utils
import trimesh
import trimesh.remesh
import numpy as np
import tetgen
import pyvista as pv
import argparse

class MeshUtils:
    def __init__(self):
        pass

    def load_mesh(self, file_path):
        # Load mesh and handle GLB files that return Scene objects
        loaded = trimesh.load(file_path)
        if hasattr(loaded, 'geometry'):
            # It's a Scene, get the first geometry
            return list(loaded.geometry.values())[0]
        else:
            # It's already a mesh
            return loaded

    def save_mesh(self, mesh, file_path):
        mesh.export(file_path)
        
    def get_mesh_vertices(self, mesh):
        return mesh.vertices

    def get_mesh_faces(self, mesh):
        return mesh.faces

    def get_mesh_edges(self, mesh):
        return mesh.edges
    
    def get_mesh_normals(self, mesh):
        return mesh.vertex_normals

    def get_mesh_uvs(self, mesh):
        return mesh.vertex_uvs

    def get_mesh_colors(self, mesh):
        return mesh.vertex_colors
    
    def get_mesh_extent(self, file_path):
        # Load the mesh first, then get bounds
        mesh = self.load_mesh(file_path)
        return mesh.bounds
    
    def repair_mesh(self, mesh):
        print(f"Repairing mesh: {len(mesh.vertices)} vertices, {len(mesh.faces)} faces")

        try:
            new_vertices, new_faces = trimesh.remesh.subdivide(
                mesh.vertices, mesh.faces,
                face_index=None,  # subdivide all faces to maintain watertightness
                return_index=False
            )
            mesh = trimesh.Trimesh(vertices=new_vertices, faces=new_faces)
            print(f"After subdivision: {len(mesh.vertices)} vertices, {len(mesh.faces)} faces")
        except Exception as e:
            print(f"Subdivision failed: {e}, continuing with original mesh")

        # Fill holes to make watertight
        mesh.fill_holes()
        print(f"After filling holes: {len(mesh.faces)} faces")

        # Fix normals
        mesh.fix_normals()

        # Remove degenerate and duplicate faces
        mesh.update_faces(mesh.nondegenerate_faces())
        mesh.update_faces(mesh.unique_faces())

        # Simplify if still too complex (tetgen typically handles up to ~50k faces well)
        if len(mesh.faces) > 30000:
            target_faces = 15000
            # Calculate reduction ratio (faces to remove / total faces)
            faces_to_remove = len(mesh.faces) - target_faces
            reduction_ratio = faces_to_remove / len(mesh.faces)
            reduction_ratio = min(reduction_ratio, 0.9)  # Don't reduce more than 90%

            try:
                mesh = mesh.simplify_quadric_decimation(reduction_ratio)
                print(f"After simplification: {len(mesh.vertices)} vertices, {len(mesh.faces)} faces")
            except Exception as e:
                print(f"Simplification failed: {e}, continuing with current mesh")

        print(f"Final mesh: {len(mesh.vertices)} vertices, {len(mesh.faces)} faces, watertight: {mesh.is_watertight}")
        return mesh
    
    def tetrahedralize_mesh(self, mesh):
        repaired_mesh = self.repair_mesh(mesh)

        print(f"After repair: {len(repaired_mesh.vertices)} vertices, {len(repaired_mesh.faces)} faces")
        print(f"Is watertight: {repaired_mesh.is_watertight}")

        # Check if mesh is suitable for tetrahedralization
        if not repaired_mesh.is_watertight:
            print("WARNING: Mesh is not watertight. Tetrahedralization may fail.")
            return None

        try:
            # Create TetGen instance with mesh vertices and faces
            tgen = tetgen.TetGen(repaired_mesh.vertices, repaired_mesh.faces)

            # Try with very permissive parameters
            tgen.tetrahedralize(order=1, mindihedral=1, minratio=0.1, quality=0.01)
            print("Tetrahedralization successful!")
            return tgen.grid

        except Exception as e:
            print(f"Tetrahedralization failed: {e}")
            print("The mesh may need manual repair or simplification.")
            return None
    
    def visualize_mesh(self, mesh):
        return pv.PolyData(mesh.vertices, mesh.faces)
    
    def main(self, args):
        print(args)
        if args.mesh_path is None:
            raise ValueError("Mesh path is required")
        if args.output_path is None:
            raise ValueError("Output path is required")

        mesh = self.load_mesh(args.mesh_path)
        tetrahedralized_mesh = self.tetrahedralize_mesh(mesh)

        if tetrahedralized_mesh is None:
            print("Tetrahedralization failed. Cannot proceed with saving.")
            return

        # Visualize and save
        try:
            vis = self.visualize_mesh(tetrahedralized_mesh)
            print(f"Visualization created: {type(vis)}")
        except Exception as e:
            print(f"Visualization failed: {e}")

        try:
            self.save_mesh(tetrahedralized_mesh, args.output_path)
            print(f"Tetrahedralized mesh saved to {args.output_path}")
        except Exception as e:
            print(f"Saving failed: {e}")

if __name__ == "__main__":
    mesh_utils = MeshUtils()
    parser = argparse.ArgumentParser()
    parser.add_argument("--mesh_path", type=str, required=True)
    parser.add_argument("--output_path", type=str, required=True)
    args = parser.parse_args()
    mesh_utils.main(args)