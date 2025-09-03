#!/bin/bash

# Function to embed a file into a PNG image
embed_file() {
    echo "Enter the path to the PNG cover file: "
    read cover_file
    echo "Enter the path to the file you want to hide: "
    read hidden_file
    echo "Enter the output PNG file name (e.g., sec.png): "
    read output_png

    if [ ! -f "$cover_file" ] || [ ! -f "$hidden_file" ]; then
        echo "Error: One or both files not found!"
        return
    fi

    echo "Enter a password to secure the hidden file: "
    read -s password

    # Encrypt and base64 encode the hidden file
    encrypted_file=$(mktemp)
    openssl enc -aes-256-cbc -in "$hidden_file" -base64 -salt -pass pass:"$password" -out "$encrypted_file" 2>/dev/null

    if [ $? -ne 0 ]; then
        echo "Error: Encryption failed."
        rm -f "$encrypted_file"
        return
    fi

    # Create the output file by copying the cover image
    cp "$cover_file" "$output_png"

    # Append the encrypted data to the output file with markers
    echo "---HIDDEN-DATA---" >> "$output_png"
    cat "$encrypted_file" >> "$output_png"
    echo "---END-HIDDEN-DATA---" >> "$output_png"

    echo "File successfully embedded into $output_png."
    echo "Note: The image content remains unchanged. Use this tool to extract the hidden file."

    # Clean up
    rm -f "$encrypted_file"
}

# Function to extract a hidden file from a PNG image
extract_file() {
    echo "Enter the path to the PNG stego file: "
    read stego_file
    echo "Enter the output path for the extracted file (e.g., extracted_file.png): "
    read output_file

    if [ ! -f "$stego_file" ]; then
        echo "Error: Stego file not found!"
        return
    fi

    echo "Enter the password to retrieve the hidden file: "
    read -s password

    # Extract the hidden data between markers
    encrypted_data=$(awk '/---HIDDEN-DATA---/{flag=1;next}/---END-HIDDEN-DATA---/{flag=0}flag' "$stego_file")

    if [ -z "$encrypted_data" ]; then
        echo "Error: No hidden data found in the file."
        return
    fi

    # Save the encrypted data to a temporary file
    encrypted_file=$(mktemp)
    echo "$encrypted_data" | base64 -d > "$encrypted_file" 2>/dev/null

    # Decrypt the hidden data
    openssl enc -aes-256-cbc -d -in "$encrypted_file" -out "$output_file" -pass pass:"$password" 2>/dev/null

    if [ $? -ne 0 ]; then
        echo "Error: Decryption failed. Check your password or file integrity."
        rm -f "$encrypted_file"
        return
    fi

    echo "Hidden file successfully extracted to $output_file."

    # Clean up
    rm -f "$encrypted_file"
}

# Main Menu
main_menu() {
    echo "============================"
    echo " File Steganography Tool"
    echo "============================"
    echo "1. Embed a file into a PNG"
    echo "2. Extract a file from a PNG"
    echo "3. Exit"
    echo "============================"
    echo "Enter your choice: "
    read choice

    case $choice in
        1) embed_file ;;
        2) extract_file ;;
        3) echo "Goodbye!" ; exit 0 ;;
        *) echo "Invalid choice. Try again." ;;
    esac
}

# Run the tool
while true; do
    main_menu
done
