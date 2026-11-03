# SpendWise: Demonstration and Code Guide

## Before the demo

1. Install `app-release.apk` on the phone and open it once.
2. Add 6–8 realistic expenses across at least 4 categories, spread over the last week, and set
   a monthly budget in Settings (e.g. ₹15,000).
3. Have GitHub open on the laptop at the repository's commit history, and keep the APK file ready.
4. Decide who speaks in each part. **Every member must speak.**

## Five-minute script (matches section 5.1 of the specification)

| Time | What to show | What to say |
|---|---|---|
| 0:00–0:30 | Home screen | "SpendWise is for students and young earners who lose track of small daily spending. It records every expense and shows where the money goes, offline." |
| 0:30–1:15 | Tap **Add expense**, tap **Save expense** with the form empty | "Every field is validated. Here is a clear message for each one." Then type `0` as the amount to show "Amount must be more than ₹0". |
| 1:15–1:45 | Fill the form correctly and save | Point out the "Expense saved" message and the new row on Home. |
| 1:45–2:15 | **Expenses** tab: search, tap a category chip, tap a row | Show the grouping by day, then the detail screen with the note, payment method and spending share. |
| 2:15–2:45 | Swipe a row left, tap **Undo**. Pick a category with no expenses | Shows the "No matching expenses" **empty state** on purpose. |
| 2:45–3:15 | **Insights** tab: switch periods, tap a category | "The summary screen shows totals per category from the same Provider store." |
| 3:15–3:30 | Close the app fully, reopen it, rotate the phone | Data is still there. The layout works sideways. |
| 3:30–4:30 | Technical problem (see below) | One member explains a real problem and its fix. |
| 4:30–5:00 | GitHub commit history and the APK file | Show commits from every member. |

To show the **error state** on purpose, use the widget test `shows an error with a retry button`
(`flutter test --plain-name "retry"`). The **empty state** can be shown live with a category filter or
after **Settings → Delete all expenses**.

### Technical problems you can talk about (pick one)

- **Saving that fails (D05/D06):** The provider updates the screen first, then saves. If saving
  throws, it restores the previous list, so the screen never shows data that is not stored.
  It also refuses to save after a failed load, so that one new expense cannot overwrite
  everything already saved.
- **Double taps opening two screens (D03):** `pushScreen` checks `ModalRoute.of(context).isCurrent`.
  After the first push the old screen is no longer on top, so a second quick tap is ignored.
- **`NaN` passing validation (D02):** `double.tryParse('NaN')` returns NaN, and any comparison with
  NaN is false, so `amount <= 0` did not catch it. The fix is an input formatter plus an `isFinite` check.

## How the code fits together

```
User taps ─► Screen (widgets) ─► ExpenseProvider (ChangeNotifier) ─► ExpenseStorage ─► SharedPreferences
                ▲                         │
                └── context.watch() ◄──── notifyListeners()
```

1. `main.dart` creates `SettingsProvider` and `ExpenseProvider` and puts them above the app with
   `MultiProvider`. `loadExpenses()` starts straight away.
2. Screens call `context.watch<ExpenseProvider>()`. When the provider calls `notifyListeners()`,
   every watching screen rebuilds with the new data. Home, Expenses, Detail, Insights and Settings all
   read the same store (requirement GP6).
3. `ExpenseProvider.loadState` is `loading`, `error` or `loaded`. Together with `isEmpty`, that gives the
   four screen states (GP3).
4. `ExpenseStorage` turns the list into JSON (`Expense.toJson`) and saves it under one key.
   `Expense.fromJson` reads it back and skips any damaged record.
5. `AppTheme` calls `ColorScheme.fromSeed` with one seed colour. `AppPalette` rotates that seed's hue to
   get one colour per category. No other file contains a colour value (GP7).

## Questions the examiner may ask

- **Why Provider and not setState?** Several screens need the same expenses. setState only updates one
  widget's own state, while a ChangeNotifier in Provider is shared and rebuilds every listener.
- **Difference between `context.watch` and `context.read`?** `watch` rebuilds the widget when data changes
  (use it in `build`). `read` gets the object once without listening (use it in button handlers).
- **Where is the data stored?** In SharedPreferences, as a JSON string. On Android this is an XML file
  in the app's private storage.
- **How does the form validation work?** Each `TextFormField` / `FormField` has a `validator` that returns an
  error message or null. `_formKey.currentState!.validate()` runs them all, and the form only saves when all return null.
- **What is `IndexedStack` for?** It keeps all four tabs alive, so switching tabs keeps scroll position and filters.
- **How did you test it?** `flutter test` runs 29 tests: widget tests for the screen states, form, navigation and
  landscape, plus unit tests for the provider totals, rollback and validators.
