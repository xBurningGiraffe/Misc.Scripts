import json
import os
import sys
import shutil
from pathlib import Path


def parse_json(json_data):
    parsed_data = {}

    # Extract relevant information from JSON
    cve_metadata = json_data.get('cveMetadata', {})
    containers = json_data.get('containers', {})
    cna = containers.get('cna', {})

    # Extract data for PwnDoc fields
    parsed_data['cvssv3'] = cna.get('metrics', [{}])[0].get(
        'cvssV3_1', {}).get('vectorString', '')
    parsed_data['category'] = ''  # Update this field as per your requirement

    # Create a details list
    parsed_data['details'] = []
    detail = {}

    # Extract references
    references = cna.get('references', [])
    detail['references'] = [ref.get('url', '') for ref in references]

    # Always include the 'locale' and 'title' fields
    detail['locale'] = cna.get('descriptions', [{}])[
        0].get('lang', '') or 'N/A'
    detail['title'] = cve_metadata.get('cveId', '') or 'N/A'

    detail['vulnType'] = cna.get('problemTypes', [{}])[0].get(
        'descriptions', [{}])[0].get('description', '')
    detail['description'] = cna.get('descriptions', [{}])[0].get('value', '')
    detail['observation'] = ''  # Update this field as per your requirement
    detail['remediation'] = cna.get('solutions', [{}])[0].get('value', '')

    # Append the detail dictionary to the details list
    parsed_data['details'].append(detail)

    return parsed_data


# Use pathlib.Path for source_directory and target_directory
source_directory = Path(sys.argv[1])
target_directory = Path(sys.argv[2])

# Recreate the target directory if it already exists
if target_directory.exists():
    shutil.rmtree(target_directory)
target_directory.mkdir(parents=True)

# Iterate over the files and folders in the source directory
for json_file in source_directory.glob('**/*.json'):
    # Skip files named "recent_activities.json"
    if json_file.name == "recent_activities.json":
        continue

    # Construct the output file path in the target directory with the same file name

    relative_path = json_file.relative_to(source_directory)
    output_file_path = target_directory / relative_path

    # Ensure the output subdirectory exists
    output_file_path.parent.mkdir(parents=True, exist_ok=True)

    # Load JSON data from file
    with json_file.open('r', encoding='utf-8') as file:
        try:
            json_data = json.load(file)
        except json.JSONDecodeError:
            print(f'Failed to parse {json_file}, skipping...')
            continue

    # Parse the JSON object
    parsed_data = parse_json(json_data)

    # Write the parsed data to the output file
    with output_file_path.with_suffix('.json').open('w', encoding='utf-8') as file:
        json.dump(parsed_data, file)

    print(f'Processed {json_file} and saved the output to {output_file_path}')
