import sys
import xml.etree.ElementTree as ET
import xml.dom.minidom as minidom

# Check if the correct number of command-line arguments is provided
if len(sys.argv) != 3:
    print("Usage: python script.py input.txt output.xml")
    sys.exit(1)

input_file = sys.argv[1]  # Get the input file name from command-line argument
output_file = sys.argv[2]  # Get the output file name from command-line argument

# Define the root element of the XML
root = ET.Element("data")

# Read the contents of the text file
with open(input_file, "r") as file:
    lines = file.readlines()

# Process each line and create XML elements
for line in lines:
    # Split the line into relevant data fields
    fields = line.strip().split("\t")

    # Create XML elements based on the fields
    item = ET.SubElement(root, "item")
    item.text = fields[0]

    # Repeat the above process for other fields and elements as needed

# Create the XML tree
tree = ET.ElementTree(root)

# Create a string representation of the XML
xml_str = ET.tostring(root, encoding="utf-8")

# Create a pretty-printed version of the XML string
xml_pretty_str = minidom.parseString(xml_str).toprettyxml(indent="  ")

# Write the pretty-printed XML to the output file
with open(output_file, "w") as file:
    file.write(xml_pretty_str)

print("XML file has been generated and pretty-printed successfully.")
