import SwiftUI
import CoreLocation
import UIKit

struct NameScreenView: View {
    let vm: OnboardingViewModel
    @FocusState private var isFocused: Bool
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(NafsTheme.gold)

                Text(NafsStrings.nameTitle.localized)
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(NafsTheme.text)

                Text(NafsStrings.nameSubtitle.localized)
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
            }
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 40)

            TextField(NafsStrings.nameField.localized, text: Bindable(vm).userName)
                .font(.system(.title3, weight: .medium))
                .foregroundStyle(NafsTheme.text)
                .multilineTextAlignment(.center)
                .padding(.vertical, 18)
                .padding(.horizontal, 24)
                .background(NafsTheme.card)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isFocused ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: isFocused ? 2 : 1)
                )
                .focused($isFocused)
                .textContentType(.givenName)
                .submitLabel(.done)
                .onSubmit {
                    if vm.canProceed { vm.goNext() }
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)

            Spacer()

            NafsButton(title: NafsStrings.continueBtn.localized, isEnabled: vm.canProceed) {
                isFocused = false
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

struct LocationScreenView: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false
    @State private var locationService = LocationService()
    @State private var hapticTrigger: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    CrescentStarMark(size: 70, color: NafsTheme.gold)
                        .opacity(appeared ? 1 : 0)

                    VStack(spacing: 12) {
                        Text(NafsStrings.locationTitle.localized)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.85)

                        Text(NafsStrings.locationBody.localized)
                            .font(.system(size: 14))
                            .foregroundStyle(NafsTheme.subtleText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 28)

                    if vm.locationGranted {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(.title3))
                                .foregroundStyle(NafsTheme.gold)
                            Text(NafsStrings.locationGranted.localized)
                                .font(.system(.body, weight: .semibold))
                                .foregroundStyle(NafsTheme.text)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(NafsTheme.gold.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(NafsTheme.gold.opacity(0.3), lineWidth: 1.5)
                        )
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            VStack(spacing: 16) {
                if vm.locationGranted {
                    NafsButton(title: NafsStrings.continueBtn.localized) {
                        vm.goNext()
                    }
                } else {
                    NafsButton(title: NafsStrings.allowLocation.localized) {
                        hapticTrigger += 1
                        let status = locationService.authorizationStatus
                        switch status {
                        case .notDetermined:
                            locationService.requestPermission()
                        case .denied, .restricted:
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        case .authorizedWhenInUse, .authorizedAlways:
                            vm.locationGranted = true
                            locationService.requestLocation()
                        @unknown default:
                            locationService.requestPermission()
                        }
                    }

                    Button {
                        vm.locationSkipped = true
                        vm.userLatitude = 21.4225
                        vm.userLongitude = 39.8262
                        UserDefaults.standard.set(true, forKey: "nafs_locationSkipped")
                        vm.goNext()
                    } label: {
                        Text(NafsStrings.skipForNow.localized)
                            .font(.system(.footnote, weight: .medium))
                            .foregroundStyle(NafsTheme.gold)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .sensoryFeedback(.success, trigger: hapticTrigger)
        .onChange(of: locationService.authorizationStatus) { _, status in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                withAnimation(.spring(response: 0.4)) {
                    vm.locationGranted = true
                }
            }
        }
        .onChange(of: locationService.lastLatitude) { _, lat in
            if let lat, let lng = locationService.lastLongitude {
                vm.userLatitude = lat
                vm.userLongitude = lng
                UserDefaults.standard.set(lat, forKey: "nafs_latitude")
                UserDefaults.standard.set(lng, forKey: "nafs_longitude")
                UserDefaults.standard.set(false, forKey: "nafs_locationSkipped")
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
            let status = locationService.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                vm.locationGranted = true
                locationService.requestLocation()
            }
        }
    }
}
