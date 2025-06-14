
# JellyJelly iOS Engineering Challenge

## Overview
This SwiftUI-based iOS app demonstrates creative implementation with three interactive tabs:

- **Feed Tab:** Engaging video feed.
- **Camera Tab:** Dual-camera (front & back) synchronized video recording.
- **Camera Roll Tab:** Easily view and playback recorded videos.

## Thought Process

### Feed Tab
Implemented using AVPlayer for smooth playback and intuitive UX, featuring muted autoplay and vertical scrolling.

### Camera Tab
Built using AVFoundation for dual-camera synchronization, providing clear controls and seamless user interactions.

### Camera Roll Tab
Adopted a clean, intuitive grid layout for easy browsing and inline/full-screen playback.

## Design Sketches
Focused on minimalist and intuitive UI:

- **Feed:** Autoplay videos, single-tap play-pause, double-tap mute/unmute functionality.
- **Camera:** Clear split-screen interface, large record button, and seamless transitions.
- **Camera Roll:** Simple thumbnail grid for quick navigation.

## Technical Decisions & Trade-offs

- **SwiftUI vs UIKit:** Chose SwiftUI for rapid prototyping, accepting minor limitations in complex camera functionalities.
- **Video Playback:** Utilized individual AVPlayer instances per video card for efficient resource management.
- **Local Storage vs Backend:** Opted for local storage for simplicity and speed. Future implementations would benefit from backend integration (e.g., Supabase or Firebase).


This approach effectively balances complexity, performance, and rapid delivery, emphasizing user experience.
