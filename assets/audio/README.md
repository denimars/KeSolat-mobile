# Adhan Audio Files

Place your adhan audio files in this directory with the following names:

## Required Files

1. `adhan_makkah.mp3` - Adhan from Makkah (Masjid al-Haram)
2. `adhan_madinah.mp3` - Adhan from Madinah (Masjid an-Nabawi)
3. `adhan_mishary.mp3` - Adhan by Mishary Rashid Alafasy

## Where to Get Adhan Audio

You can obtain adhan audio files from these legitimate sources:

1. **Islamway** - https://en.islamway.net/
2. **MP3Quran** - https://mp3quran.net/
3. **Assabile** - https://assabile.com/
4. **Archive.org** - Search for "adhan" or "azan"

## Audio Format Requirements

- Format: MP3 (recommended) or M4A
- Quality: 128kbps or higher
- Duration: Typically 2-4 minutes

## Adding Custom Adhan

To add your own adhan audio:

1. Name your file appropriately (e.g., `adhan_custom.mp3`)
2. Add it to this directory
3. Update `AppConstants.adhanOptions` in `lib/core/constants/app_constants.dart`
4. Update `_getAdhanDisplayName()` in `lib/presentation/views/settings/settings_screen.dart`

## Note

Make sure you have the rights to use any audio files you add to this project.
