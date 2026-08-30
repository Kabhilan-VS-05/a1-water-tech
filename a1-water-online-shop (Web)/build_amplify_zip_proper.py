import os
import zipfile

def main():
    dist_dir = 'dist'
    output_zip = 'amplify-deploy.zip'
    
    if os.path.exists(output_zip):
        os.remove(output_zip)

    print(f"Creating proper AWS Amplify deployment ZIP from '{dist_dir}'...")

    with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as z:
        for root, dirs, files in os.walk(dist_dir):
            for file in files:
                abs_file = os.path.join(root, file)
                rel_file = os.path.relpath(abs_file, dist_dir)
                posix_file = rel_file.replace('\\', '/')
                print(f"  Writing: {posix_file}")
                z.write(abs_file, posix_file)

    print(f"\nSUCCESS: Generated '{output_zip}' with all root files AND assets subfolder!")

if __name__ == '__main__':
    main()
