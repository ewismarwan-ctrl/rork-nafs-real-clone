Nafs build fix update

Extract this ZIP and replace the files at the exact same repo paths.
Do not upload the ZIP itself as a repo file.

Included fixes:
- ios/Nafs/Views/Launch/NafsOpeningSplashView.swift
  - Exactly one private GoldParticle struct remains.
  - GoldParticle is declared before NafsOpeningSplashView uses GoldParticle.seed.

- ios/Nafs/Views/Onboarding/PaywallScreenView.swift
  - Added import Combine for Timer.publish(...).autoconnect().
