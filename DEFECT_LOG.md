# Defect Log: Smart Spend

Defects found while reviewing and testing the app, with the steps to reproduce each one and
its status. Add any new defects found during testing on a physical phone to the end of the
table, then fix them or mark them as open.

| ID | Defect | Steps to reproduce | Status |
|---|---|---|---|
| D01 | The first prototype could not produce an APK because the `android/` platform folder was missing. | Run `flutter build apk --release` on the original prototype. The build fails with no Android project. | **Fixed:** project regenerated with the Android platform |
| D02 | The amount field accepted `NaN` as a valid amount. | Old form: type `NaN` in Amount, then Save. `double.tryParse('NaN')` succeeds, and NaN fails every `<= 0` / `>` check, so it was saved. | **Fixed:** `AmountInputFormatter` only allows digits and up to 2 decimals, and the validator rejects non-finite values (unit test) |
| D03 | A fast double tap opened the same screen twice, so Back had to be pressed twice. | Quickly double tap an expense row or the Add button. | **Fixed:** `SafeNavigation.pushScreen` ignores taps once a new screen is on top (widget test) |
| D04 | Colours were hard-coded (`Colors.black54`, `Color(0xFF3157D5)`, `Colors.white`), breaking the theme rule and making a dark theme unreadable. | Search the old `lib/` for `Color(` or `Colors.` | **Fixed:** every colour comes from the theme. One seed colour, and category colours are derived from it |
| D05 | If saving failed, the screen still showed the unsaved change, and the whole list was replaced by an error. | Make storage fail (test fake), then add an expense. | **Fixed:** `ExpenseProvider` rolls back to the previous list and the form shows a message (unit test) |
| D06 | After a failed load, adding an expense would overwrite every saved expense with just the new one. | Make the first read fail, then add an expense. Storage now holds one record. | **Fixed:** changes are blocked until data has loaded correctly (unit test) |
| D07 | `DropdownButtonFormField.value` is deprecated on current Flutter and produced analyzer warnings. | Run `flutter analyze` on the old form screen. | **Fixed:** replaced by a chip-based `CategorySelector` form field |
| D08 | The original widget test passed by accident: it used real SharedPreferences, loading failed silently, and the test only checked static text. | Run the old test and print the provider status. It is `error`. | **Fixed:** tests use mocked preferences and a fake storage, and check each state (29 tests) |
| D09 | The date picker could crash if a saved date was later than "today" (for example after the phone's clock was moved back). | Edit an expense whose date is after the current phone date, then tap Date. | **Fixed:** the picker's initial date is clamped to its allowed range |
| D10 | Pull-to-refresh replaced the whole list with a full-screen spinner. | On Expenses, pull down to refresh. | **Fixed:** refresh reloads quietly while the list stays visible |
| D11 | Launcher icon artwork appeared too small inside the adaptive icon mask. | Generate icons with the default settings and view them in a circular mask. | **Fixed:** foreground inset set to 0, with the artwork sized to the safe zone |
| D12 | Selected chips and the navigation indicator had poor text contrast with the "fidelity" colour variant. | Use `DynamicSchemeVariant.fidelity` and look at a selected chip. | **Fixed:** switched to the default tonal-spot scheme |
| D13 | The Insights period chips were clipped at the page edge ("All tim…"). | Open Insights on a 411 dp wide phone. | **Fixed:** the chip row scrolls edge to edge |
| D14 | Chart labels mixed formats ("₹80.00" next to "₹299"). | Home: last 7 days with a small amount on one day. | **Fixed:** amounts under ₹1,000 show as whole rupees |
| D15 | The amount hint "0" looked like a value that had already been entered. | Open Add expense. | **Fixed:** hint reads "e.g. 250" |

## Robustness checks (GP8)

| Check | Result |
|---|---|
| Empty input on every form field | Each field shows its own message; nothing is saved |
| Very long text | Title limited to 60 and note to 200 characters with a counter; long text wraps or ends with "…" in lists |
| No internet connection | The app never uses the network |
| Repeated fast taps | Navigation guard plus a disabled Save button while saving |
| Phone turned sideways | All screens scroll; widget test runs every tab and the form in landscape |
| Damaged saved data | Invalid records are skipped; unreadable data shows the error state with **Try again** |

## Still to verify on a physical phone

These checks need a real device and are recorded here until the team has done them:

- [ ] Install `app-release.apk`, open it and check the launcher icon and name
- [ ] Add, edit and delete expenses, then close the app and reopen it: the data is still there
- [ ] Rotate the phone on every screen
- [ ] Switch to dark mode in Settings and in the phone's system settings
