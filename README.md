# Quillpad (macOS)

> **Note**: This is an unofficial native macOS port of the [Quillpad](https://github.com/quillpad/quillpad) Android application.

Quillpad is a native macOS note-taking application built with SwiftUI, designed for speed, privacy, and compatibility. It uses a file-based storage system (Markdown) making it fully compatible with other Markdown editors and the Quillpad Android app.

## Features

- **Markdown Native**: All notes are stored as plain text Markdown files (`.md`).
- **File System Sync**: Works directly with your local file system, allowing easy syncing via iCloud Drive, Syncthing, or other services.
- **Biometric Security**: Protect your notes with Touch ID, Face ID, or your system password.
- **Rich Media**: Support for audio recordings, sketches (PencilKit), and file attachments.
- **Organization**:
  - Notebooks (Folders)
  - Tags
  - Frontmatter metadata support (YAML)
  - Pin, Archive, and Trash management
- **Productivity**:
  - Global Search (integrated with Spotlight)
  - Reminders
  - Grid and List views
  - Custom Sorting options
- **Modern UI**: Clean, native macOS interface with Dark Mode support.

## Requirements

- macOS 14.0+

## Installation

1. Clone the repository.
2. Open `Quillpad.xcodeproj` in Xcode.
3. Build and Run.

## Usage

- **Creating Notes**: Press `Cmd+N` or click the "New Note" button.
- **Formatting**: Use standard Markdown syntax or the formatting toolbar.
- **Tags**: Add tags in the frontmatter or via the UI to organize notes.
- **Search**: Use the search bar to filter by title, content, or tags.
