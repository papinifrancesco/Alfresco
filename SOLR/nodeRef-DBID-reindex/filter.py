import json
import re

# Chargement du fichier JSON
with open('report.json', 'r') as f:
    data = json.load(f)

# Expression régulière pour correspondre à un GUID (UUID)
guid_pattern = re.compile(r'[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}')

# Fonction pour parcourir récursivement le JSON
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

# Extraire les GUID
guids = extract_guids(data)

# Affichage des GUID extraits
for guid in guids:
    print(guid)
    
