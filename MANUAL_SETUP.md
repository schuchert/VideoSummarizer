## Manual Setup (macOS)

These steps mirror the setup script. Use these if you prefer manual control.

1. Install Homebrew (if not already installed):
   ```
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Install required tools:
   ```
   brew install ffmpeg jq git
   ```

3. Clone and build whisper.cpp:
   ```
   cd ~/projects
   git clone https://github.com/ggerganov/whisper.cpp.git
   cd whisper.cpp
   mkdir -p build
   cd build
   cmake ..
   make -j
   ```

4. Download the model (matching the script):
   ```
   cd ~/projects/whisper.cpp
   ./models/download-ggml-model.sh base.en
   ```

5. Get a Perplexity API key:
   - Sign up/log in at Perplexity.ai
   - Go to API settings (https://www.perplexity.ai/settings/api)
   - Generate/copy your API key

6. Configure the API key (add to `~/.zshrc`):
   ```
   export PERPLEXITY_API_KEY="pplx-your_actual_key_here"
   source ~/.zshrc
   ```

7. Test the key:
   ```
   curl -sS https://api.perplexity.ai/chat/completions \
     -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model": "sonar-small-chat", "messages": [{"role": "user", "content": "Say hello"}]}' \
     | jq -r '.choices[0].message.content'
   ```
