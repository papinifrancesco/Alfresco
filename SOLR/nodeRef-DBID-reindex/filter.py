import json
import re

# Load the JSON file
with open('response.json', 'r') as f:
    data = json.load(f)

# RegEx for GUID (UUID)
guid_pattern = re.compile(r'[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}')

# Scan through the JSON
def extract_guids(obj):
    guids = []
    if isinstance(obj, dict):
        for key, value in obj.items():
            guids.extend(extract_guids(value))
    elif isinstance(obj, list):
        for item in obj:
            guids.extend(extract_guids(item))
    elif isinstance(obj, str):
        if guid_pattern.match(obj):
            guids.append(obj)
    return guids

# Extract GUIDs
guids = extract_guids(data)

# Print GUIDs
for guid in guids:
    print(guid)
    
