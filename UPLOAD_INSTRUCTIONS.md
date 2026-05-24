Nafs combined upload package

IMPORTANT: Do not upload this ZIP as a file to GitHub and expect Rork to read it.
Extract it first, then upload/replace each file at the matching repo path.

Includes both recent changes:
1. Premium opening splash animation
- ios/Nafs/Views/Launch/NafsOpeningSplashView.swift
- ContentView root overlay wiring

2. Salah Lock onboarding/paywall update
- New onboarding flow focused on stopping delayed Salah through Prayer Lock
- Hard paywall with yearly selected by default and weekly anchor
- One-time offer screen with discounted RevenueCat package fallback
- Local storage for onboarding answers, attribution, and cat companion data
- Bottom tabs simplified to Home, Focus, More

Files included:
- ios/Nafs/ContentView.swift
- ios/Nafs/Models/OnboardingModels.swift
- ios/Nafs/ViewModels/OnboardingViewModel.swift
- ios/Nafs/ViewModels/StoreViewModel.swift
- ios/Nafs/Views/Launch/NafsOpeningSplashView.swift
- ios/Nafs/Views/Onboarding/OnboardingContainerView.swift
- ios/Nafs/Views/Onboarding/InputScreenViews.swift
- ios/Nafs/Views/Onboarding/PaywallScreenView.swift
- ios/Nafs/Views/Onboarding/SalahLockOnboardingScreens.swift

Upload instructions:
Extract this ZIP. In GitHub, replace the files at the exact same paths. For new folders/files, create the missing folders/files with the same names.
