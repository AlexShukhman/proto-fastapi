import os
import re

def fix_grpc_imports(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('_grpc.py'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r') as f:
                    content = f.read()

                # Replace absolute imports with relative imports
                # Pattern: import xyz_pb2 as xyz__pb2
                pattern = r'^import (\w+_pb2) as (\w+__pb2)$'
                replacement = r'from . import \1 as \2'

                fixed_content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

                if content != fixed_content:
                    with open(filepath, 'w') as f:
                        f.write(fixed_content)
                    print(f"Fixed imports in {filepath}")


if __name__ == "__main__":
    fix_grpc_imports("src/models/gen")