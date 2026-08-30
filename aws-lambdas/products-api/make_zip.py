import os
import zipfile

def create_lambda_zip():
    zip_name = 'lambda-deploy-fixed.zip'
    if os.path.exists(zip_name):
        os.remove(zip_name)
        
    print(f"Creating {zip_name}...")
    
    files_to_include = ['index.mjs', 'admin.mjs', 'package.json']
    
    with zipfile.ZipFile(zip_name, 'w', zipfile.ZIP_DEFLATED) as z:
        # Add top level files
        for f in files_to_include:
            if os.path.exists(f):
                print(f"Adding {f}")
                z.write(f, f)
        
        # Add node_modules
        node_modules_dir = 'node_modules'
        if os.path.exists(node_modules_dir):
            for root, dirs, files in os.walk(node_modules_dir):
                for file in files:
                    full_path = os.path.join(root, file)
                    # Convert Windows backslashes to Linux forward slashes
                    arcname = full_path.replace('\\', '/')
                    z.write(full_path, arcname)
                    
    print(f"Successfully created {zip_name}!")

if __name__ == '__main__':
    create_lambda_zip()
