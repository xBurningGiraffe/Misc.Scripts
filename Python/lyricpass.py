import requests
import argparse
import random

# Base URL for Lyrics.ovh API
LYRICS_OVH_API = "https://api.lyrics.ovh/v1"

# Fetch lyrics using the Lyrics.ovh API
def fetch_lyrics(artist, song):
    response = requests.get(f"{LYRICS_OVH_API}/{artist}/{song}")
    if response.status_code == 200:
        data = response.json()
        lyrics = data.get("lyrics", "")
        if lyrics:
            return lyrics.split("\n")  # Split into lines
        else:
            print(f"No lyrics found for '{song}' by '{artist}'.")
            return []
    else:
        print(f"Error: Unable to fetch lyrics for '{song}' by '{artist}'. HTTP Status: {response.status_code}")
        return []

# Generate passwords
def generate_passwords(lyrics, count=5):
    passwords = []
    # Filter out empty lines
    verses = [line.strip() for line in lyrics if line.strip()]
    if len(verses) < 2:
        print("Error: Not enough verses in lyrics to generate passwords.")
        return []

    for _ in range(count):
        # Select two consecutive verses
        idx = random.randint(0, len(verses) - 2)
        verse1 = verses[idx].replace(",", "")
        verse2 = verses[idx + 1].replace(",", "")

        # Combine verses, remove spaces, and capitalize some words
        words = (verse1 + " " + verse2).split()
        password = "".join([word.capitalize() for word in words])

        # Add at least three random numbers and a special character
        numbers = "".join([str(random.randint(0, 9)) for _ in range(3)])
        special_char = random.choice("!@#$%^&*()-_=+[]{}|;:,.<>?/`~")
        password += numbers + special_char

        passwords.append(password)
    return passwords

# Main function
def main():
    parser = argparse.ArgumentParser(description="Generate passwords using Lyrics.ovh song lyrics")
    parser.add_argument("--artist", type=str, help="Artist name", required=True)
    parser.add_argument("--song", type=str, help="Song name", required=True)
    args = parser.parse_args()

    # Fetch and process lyrics
    lyrics = fetch_lyrics(args.artist, args.song)
    if not lyrics:
        return

    # Generate passwords
    passwords = generate_passwords(lyrics)

    # Output passwords
    print("\nGenerated Passwords:")
    for idx, password in enumerate(passwords, 1):
        print(f"{idx}: {password}")

if __name__ == "__main__":
    main()
