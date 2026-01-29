# Video to YouTube Title + Summary Pipeline

Automated workflow for macOS. Start with the setup script, then run `process_videos.zsh` to summarize recent videos from your downloads folder.

## Features

- Processes recent .mp4 files in a directory (default: ~/Downloads)
- Optional filters: max size and max age (hours)
- Transcript-only mode (skip summary generation)
- AI-generated YouTube titles + summaries optimized for health/fitness/tai chi/flexibility content
- Moves processed files to ~/Downloads/processed with date suffixes

## Setup (scripted)

```
./setup/setup.zsh
```

Prefer to do the steps manually? Follow [Manual Setup](MANUAL_SETUP.md).

## Usage

- Process recent videos + generate title/summary:
  ```
  ./process_videos.zsh
  ```

- Transcript-only (skip summary):
  ```
  ./process_videos.zsh --transcript-only
  ```

- Limit by max file size (optional):
  ```
  ./process_videos.zsh --size 300M
  ```

- Limit by max age in hours (default 4 hours):
  ```
  ./process_videos.zsh --age 4
  ```

- Process a different directory:
  ```
  ./process_videos.zsh --dir ~/Videos
  ```

Alias suggestion (add to ~/.zshrc):
```
alias vids='~/projects/AutomateVideos/process_videos.zsh'
```

## Workflow

```
~/Downloads/*.mp4 -> ffmpeg -> WAV -> whisper-cli -> transcript -> Perplexity API -> Title + Summary
                                                              -> ~/Downloads/processed/*.mp4 (date suffixed)
```

## Example Output (TestVideo.mp4)

```
#########################################################################
~/Downloads/TestVideo.mp4

this is going to stimulate the nerve endings in your neck and release a lot of tension
and this is going to help you relax

Neck Mobility Routine for Desk Workers - 12 Minutes

This 12-minute neck mobility routine targets the common tension patterns from prolonged computer work, using gentle tai chi-inspired movements and progressive stretching. You'll move through shaking releases, neck circles, and deep flexibility holds that release somatic holding patterns without strain. Perfect for programmers, writers, and anyone with forward head posture.

- Shaking releases fascial tension accumulated from static postures
- Tai chi neck circles improve cervical range of motion
- Progressive PNF holds build lasting flexibility
```

## Customization

Script options (process_videos.zsh):
- --dir PATH - Source video directory
- --size SIZE - Max size (e.g., 300M)
- --age HOURS - Max age in hours
- --transcript-only - Skip summary generation

AI prompt (youtube_title_summary.sh):
- Tuned for health/fitness/tai chi/flexibility content
- Outputs: Title + 3-sentence summary + Bulleted Highlights
- Uses sonar-pro model

## Troubleshooting

| Issue | Solution |
|-------|----------|
| PERPLEXITY_API_KEY is not set | Add to ~/.zshrc and source ~/.zshrc |
| whisper-cli: command not found | Check PATH includes ~/projects/whisper.cpp/build/bin |
| No such file: models/ggml-base.en.bin | Run ./models/download-ggml-model.sh base.en |
| Large files skipped | Use ./process_videos.zsh --size to set a new limit |
| Files skipped due to age | Use ./process_videos.zsh --age to change the window |

## Scripts

- process_videos.zsh - Main orchestrator
- youtube_title_summary.sh - Perplexity API call
- test/*.zsh - Smoke and option tests
