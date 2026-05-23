Nafs earned screen time navigation cleanup

This package contains only changed/new project files, preserving their repo paths.
Upload these files over the matching paths in the GitHub/Rork project.

Implemented:
- Bottom tabs focused to Home, Earn, Lock, Progress, More.
- Earn tab centered on worship actions that grant screen time minutes and XP.
- Lock tab repositioned as Nafs Lock with earned screen time status and Lock In controls.
- Progress tab focused on discipline score, XP, streak, rank, and local activity.
- More tab organized into Worship Tools, Settings, Account, and Support.
- Garden of Deeds, Send Dua, Qibla Finder, squads, and challenge screens are removed from active navigation.
- Production circle/challenge demo data was cleared from the discipline circle service.

Known gaps:
- A real backend is still needed for live circles/challenges.
- DeviceActivity extension integration still needs final earned-credit enforcement for automatic unlocks.
- Local Windows environment does not include xcodebuild/swift, so compile verification must be run on macOS/Xcode or by Rork.
