# KofCBellevue

An iOS app project for the Knights of Columbus Bellevue community, built with Swift and SwiftUI.

## Project status

This project is under active development. This README describes the navigation agreed upon during development and the source files shared for review. It is not a verification of every feature in the current repository.

Meeting-minutes workflows, banner management, production data connections, and delivery behavior should be checked against the latest implementation before being described as release-ready.

## Navigation

### Bottom tabs

- Home
- Messages
- Settings
- Profile

Settings and Profile are intentionally excluded from the hamburger menu. They remain accessible through the bottom tabs.

### Hamburger menu

```text
Home
Messages
Meeting Minutes
  Latest Minutes
  Minutes History
  Publish Minutes
Content Management
  Manage Banners
```

`SideMenuDestination` defines the drawer destinations, labels, SF Symbols, and menu groupings.

| Destination | Bottom-tab index |
| --- | --- |
| Home | 0 |
| Messages | 1 |
| Latest Minutes | None |
| Minutes History | None |
| Publish Minutes | None |
| Manage Banners | None |

Manage Banners is intended to open a management sheet rather than switch bottom tabs. The meeting-minutes destinations require their own navigation handling.

## Source overview

The following files have been shared during development. This is a logical overview, not an exact repository directory tree.

| Area | Relevant files |
| --- | --- |
| Application entry | `KofCBellevueApp.swift` |
| Root navigation | `ContentView.swift` |
| Drawer navigation | `SideMenuView.swift`, `SideMenuDestination.swift` |
| Main screens | `HomeScreen.swift`, `MessagesScreen.swift`, `SettingsScreen.swift`, `ProfileScreen.swift` |
| Message composition | `RecipientPickerScreen.swift`, `ComposeMessageScreen.swift`, `MessageReviewScreen.swift`, `MessageComposerViewModel.swift` |
| Message models | `MessageDraft.swift`, `DeliveryChannel.swift`, `KoCRecipient.swift` |
| Recipient access | `RecipientRepository.swift`, `PhoneContactsRepository.swift`, `DatabaseRecipientRepository.swift` |
| Delivery integration | `MessageDeliveryService.swift`, `SMSComposerView.swift`, `EmailComposerView.swift` |
| Notification preferences | `NotificationSettingsScreen.swift`, `NotificationPreferences.swift` |
| Shared UI | `EmptyPanel.swift` |

The project separates screens, message state, recipient access, and delivery integration into distinct source files. Verify the current implementation of each integration before relying on it in production.

## Getting started

1. Obtain the repository and open its Xcode project or workspace.
2. Select the KofCBellevue application scheme.
3. Check the app target's deployment target and use a compatible simulator or device.
4. For a physical device, configure your development team and signing settings.
5. Build and run the app.

The exact minimum iOS version, Xcode version, dependency requirements, and backend configuration have not been documented in the materials used for this README. Check the project settings and repository configuration for authoritative values.

## Permissions and configuration checklist

Before testing or distributing the app:

- Review contacts access and its privacy usage description if phone-contact selection is enabled.
- Review email and SMS composer availability checks and unavailable-service handling.
- Check notification authorization and delivery implementation separately from notification preference controls.
- Confirm whether the database recipient repository uses sample data or a configured production service.
- Keep credentials, signing material, private member data, and service secrets out of version control.

## Navigation maintenance

When changing `SideMenuDestination`, update every switch that handles it, including `title`, `systemImage`, `tabIndex`, and the selection handler in `ContentView`.

The `tabIndex` property should include all current destinations:

```swift
var tabIndex: Int? {
    switch self {
    case .home:
        return 0
    case .messages:
        return 1
    case .latestMinutes,
         .minutesHistory,
         .publishMinutes,
         .manageBanners:
        return nil
    }
}
```

A destination must also be rendered by `SideMenuView` to appear in the drawer. Defining an enum case alone does not add its row to the visible menu.

## Manual testing checklist

- Build without missing enum cases or references to removed destinations.
- Confirm all four bottom tabs are accessible.
- Confirm Settings and Profile do not appear in the hamburger menu.
- Confirm Home and Messages select their corresponding tabs.
- Confirm all three meeting-minutes entries appear and route as intended.
- Confirm Manage Banners appears under Content Management and opens its intended sheet.
- Test drawer dismissal and selection highlighting, including when Settings or Profile is active.
- Test message recipient selection, composition, review, cancellation, and unavailable delivery services.
- Test permission denial and empty recipient lists.
- Verify preference persistence and data persistence where implemented.

## Before release

Document the supported OS and Xcode versions, production data setup, implemented feature status, automated test commands, and distribution process. Confirm authorization rules for publishing minutes and managing banners if these actions are restricted to designated users.

## License

No license was supplied with the materials used to prepare this README. Add the project's chosen license and confirm permissions for included artwork and branding before public distribution.
