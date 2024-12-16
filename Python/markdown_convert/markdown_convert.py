import argparse
from markitdown import MarkItDown

def convert_to_markdown(input_file, output_file):
    try:
        # Initialize MarkItDown
        converter = MarkItDown()

        # Convert the file to Markdown
        result = converter.convert(input_file)

        # Write the text content to the output file
        with open(output_file, 'w', encoding='utf-8') as outfile:
            outfile.write(result.text_content)

        print(f"Conversion successful! Output saved to {output_file}")
    except Exception as e:
        print(f"An error occurred: {e}")

def main():
    # Define the list of supported file types
    supported_file_types = (
        "PDF (.pdf), PowerPoint (.pptx), Word (.docx), Excel (.xlsx), "
        "HTML (.html), Images (.png, .jpg, .jpeg), Audio (.mp3, .wav), "
        "CSV (.csv), JSON (.json), XML (.xml)"
    )

    parser = argparse.ArgumentParser(
        description="Convert files to Markdown using MarkItDown.",
        epilog=f"Supported file types: {supported_file_types}"
    )
    parser.add_argument(
        "-f",
        help="File to convert to Markdown"
    )
    parser.add_argument(
        "-o ",
        help="Markdown file to output."
    )

    args = parser.parse_args()
    convert_to_markdown(args.input_file, args.output_file)

if __name__ == "__main__":
    main()
