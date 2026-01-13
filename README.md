![Dialog](readme/dialog.png)

This is a small script I made to launch the webcam settings dialog directly from Windows (the same dialog as StreamLabs). In my case, the Logitech G HUB application doesn't have all the same settings as this dialog window, that's why it is useful. If you want to adjust more precisely your webcam when you use it for Zoom, Facebook or anything else, this is the script you need.

This is nowhere near perfect, I made this in 15 minutes. If you can make it better, please do! The files are heavy because of the ffmpeg executable needed for this to work.

# How to use

## 1. Download
Download the files and place them in a folder somewhere on your computer. Ensure `ffmpeg.exe` is in the same folder.

## 2. Open Settings
Simply double-click **WebcamSettings.bat**.

* **One Camera:** The script will automatically detect your camera and open the settings dialog immediately.
* **Multiple Cameras:** If you have more than one device (e.g., OBS Virtual Camera + Logitech), the script will list them. Type the number of the camera you want to configure and press Enter.

*Note: You no longer need to manually edit files or look up your camera name; the script handles it for you.*

## 3. Place a shortcut on your desktop (optional)
You can create a shortcut to `WebcamSettings.bat` on your desktop for quick access.

Voila! Hope it works for you.
