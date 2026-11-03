import os

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Replace non-const constructor with const-compatible constructor
    content = content.replace('BorderRadius.circular(16)', 'BorderRadius.all(Radius.circular(16))')
    
    with open(filepath, 'w') as f:
        f.write(content)

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

