import re
import argparse
import logging

def clean_and_merge_paragraphs(input_file, output_file, max_blank_lines=1, encoding='utf-8'):
    logging.info(f"Processing file: {input_file}")

    with open(input_file, 'r', encoding=encoding, errors='replace') as f, open(output_file, 'w', encoding=encoding) as out_f:
        paragraph = []
        blank_count = 0

        for line in f:
            stripped_line = line.strip()

            # Track paragraphs based on blank lines
            if stripped_line == '':
                blank_count += 1
                if paragraph:
                    # Merge paragraph into a single line
                    merged_paragraph = ' '.join(paragraph)
                    out_f.write(merged_paragraph + '\n\n')  # Preserve paragraph spacing
                    paragraph = []
            else:
                blank_count = 0  # Reset blank line count when text is found
                corrected_line = re.sub(r'\s+', ' ', stripped_line)  # Normalize spaces
                paragraph.append(corrected_line)

        # Write the last paragraph if any content remains
        if paragraph:
            merged_paragraph = ' '.join(paragraph)
            out_f.write(merged_paragraph + '\n\n')

    logging.info(f"Processed file saved as: {output_file}")
    print(f"Processed {input_file} -> {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Merge paragraphs into single lines while preserving spacing.")
    parser.add_argument("input_file", help="Path to input text file")
    parser.add_argument("output_file", help="Path to save the cleaned text")
    parser.add_argument("--encoding", type=str, default="utf-8", help="Specify file encoding (e.g., utf-8, latin-1)")
    parser.add_argument("--log_file", type=str, default="cleanup.log", help="Path to log file")

    args = parser.parse_args()

    logging.basicConfig(filename=args.log_file, level=logging.INFO, format="%(asctime)s - %(message)s")
    clean_and_merge_paragraphs(args.input_file, args.output_file, encoding=args.encoding)