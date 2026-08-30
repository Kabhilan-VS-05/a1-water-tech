import os
import zipfile

def create_amplify_zip():
    zip_name = 'amplify-deploy-latest.zip'
    dist_dir = 'dist'
    
    if os.path.exists(zip_name):
        try:
            os.remove(zip_name)
        except Exception:
            pass

    print(f"Packaging {dist_dir} into {zip_name}...")
    
    with zipfile.ZipFile(zip_name, 'w', zipfile.ZIP_DEFLATED) as z:
        for root, dirs, files in os.walk(dist_dir):
            for file in files:
                full_path = os.path.join(root, file)
                # Compute relative path inside dist directory
                rel_path = os.path.relpath(full_path, dist_dir)
                # Convert backslashes to forward slashes for Linux
                arcname = rel_path.replace('\\', '/')
                print(f"  Adding: {arcname}")
                z.write(full_path, arcname)

    print(f"\nSuccessfully generated {zip_name}!")

if __name__ == '__main__':
    create_amplify_zip()
