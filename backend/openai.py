import json
from pydub import AudioSegment
import whisper

def convert_mp3_to_wav(src, dst):
    """Convert MP3 file to WAV format."""
    sound = AudioSegment.from_mp3(src)
    sound.export(dst, format="wav")

def speech_to_text(audio_path, output_text_path):
    """Transcribe audio file to text using Whisper model."""
    # Load the Whisper model
    model = whisper.load_model("base")

    # Transcribe the WAV file
    result = model.transcribe(audio_path)

    # Save the transcription to a text file
    with open(output_text_path, 'w') as f:
        f.write(result['text'])
    
    return result['text']

def load_phishing_words():
    """Load phishing words from a JSON file."""
    with open('phishing_words.json', 'r') as file:
        phishing_words = json.load(file)
    return phishing_words

def check_for_phishing_words(text, phishing_words):
    """Check the text for phishing words and calculate statistics."""
    phishing_count = 0
    sentences = text.split('.')
    total_sentences = len(sentences)
    
    for sentence in sentences:
        for word in phishing_words:
            if word.lower() in sentence.lower():
                phishing_count += 1
                break  # Only count the sentence once, even if multiple phishing words are found

    phishing_percentage = (phishing_count / total_sentences) * 100 if total_sentences > 0 else 0
    return phishing_count, total_sentences, phishing_percentage

# the main code starts from here 

# File paths
#src = "WhatsApp Audio 2024-05-22 at 12.24.41 PM.mp3"
src = "Sankalp_Hindi_Vishing_03.mp3"
dst = "test.wav"
output_text_path = "transcript.txt"

# Convert MP3 to WAV
convert_mp3_to_wav(src, dst)

# Transcribe the WAV file
transcript_text = speech_to_text(dst, output_text_path)

if transcript_text:
    # Load phishing words
    phishing_words = load_phishing_words()
    phishing_count, total_sentences, phishing_percentage = check_for_phishing_words(transcript_text, phishing_words)

    print(f"Total sentences: {total_sentences}")
    print(f"Phishing sentences: {phishing_count}")
    print(f"Phishing percentage: {phishing_percentage:.2f}%")
