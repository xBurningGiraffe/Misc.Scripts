import tarfile
import os

def recover_data(input_file, output_archive='patient_data.tar.gz'):
    """
    Scans a binary file for Gzip magic bytes, carves the data, and extracts it.
    """
    
    # Gzip magic bytes are always 0x1f 0x8b. 
    # This is how we find the "hidden" start of our tarball within the JPEG.
    GZIP_MAGIC = b'\x1f\x8b'
    
    # Basic check to ensure the file exists before processing
    if not os.path.exists(input_file):
        print(f"[-] Error: {input_file} not found.")
        return

    # Open the received JPEG in 'rb' (Read Binary) mode
    with open(input_file, 'rb') as f:
        content = f.read()

    # Find the first occurrence of the Gzip signature.
    # Python's .find() returns the exact index (offset) of the match.
    offset = content.find(GZIP_MAGIC)

    if offset == -1:
        print("[-] Gzip signature not found. The image may not contain appended data.")
        return

    print(f"[+] Gzip signature located at byte offset: {offset}")

    # 1. Carving Phase:
    # We slice the binary data from the offset point until the end of the file.
    # We save this slice as a standard .tar.gz file.
    with open(output_archive, 'wb') as f_out:
        f_out.write(content[offset:])
    print(f"[+] Archive carved and saved to: {output_archive}")

    # 2. Extraction Phase:
    # We use the native tarfile library to decompress the carved data.
    print("[*] Attempting decompression and extraction...")
    try:
        # Open the carved file using 'r:gz' (Read with Gzip compression)
        with tarfile.open(output_archive, "r:gz") as tar:
            # Extract all files into the current working directory
            tar.extractall(path=".")
            print("[***] SUCCESS: Data extracted successfully [***]")
            
            # List the files retrieved for confirmation
            print("[*] Files recovered:")
            for member in tar.getmembers():
                print(f"  -> {member.name}")
                
    except Exception as e:
        # If the offset was wrong or the data was corrupted during transfer, this will catch it.
        print(f"[-] Extraction failed: {e}")
        print("[-] Check if the sender used 'cat' correctly to append the data.")

if __name__ == "__main__":
    # Point this to the file saved by your HTTPS receiver
    # In your case: msk_logo.jpeg
    recover_data('msk_logo.jpeg')