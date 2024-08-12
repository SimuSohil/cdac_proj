from flask import Flask, request, jsonify
from flask_cors import CORS
from pydub import AudioSegment
import whisper
import json
import os

app = Flask(__name__)
CORS(app)

def convert_mp3_to_wav(src, dst):
    sound = AudioSegment.from_mp3(src)
    sound.export(dst, format="wav")

def speech_to_text(audio_path):
    model = whisper.load_model("base")
    result = model.transcribe(audio_path)
    return result['text']

def load_phishing_words():
    json_path = os.path.join(os.path.dirname(__file__), 'phishing_words.json')
    with open(json_path, 'r') as file:
        phishing_words = json.load(file)
    return phishing_words

def check_for_phishing_words(text, phishing_words):
    phishing_count = 0
    sentences = text.split('.')
    total_sentences = len(sentences)
    
    for sentence in sentences:
        for word in phishing_words:
            if word.lower() in sentence.lower():
                phishing_count += 1
                break

    phishing_percentage = (phishing_count / total_sentences) * 100 if total_sentences > 0 else 0
    return phishing_count, total_sentences, phishing_percentage

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    try:
        # Save the uploaded file
        file_path = f"{file.filename}"
        file.save(file_path)

        # Convert MP3 to WAV
        wav_filename = file_path.rsplit('.', 1)[0] + '.wav'
        convert_mp3_to_wav(file_path, wav_filename)

        # Transcribe the WAV file
        transcript_text = speech_to_text(wav_filename)

        if transcript_text:
            # Load phishing words
            phishing_words = load_phishing_words()
            phishing_count, total_sentences, phishing_percentage = check_for_phishing_words(transcript_text, phishing_words)

            # Clean up files
            os.remove(file_path)
            os.remove(wav_filename)

            return jsonify({
                "transcript": transcript_text,
                "phishing_count": phishing_count,
                "total_sentences": total_sentences,
                "phishing_percentage": phishing_percentage
            })

        return jsonify({"error": "Transcription failed"}), 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug = True)