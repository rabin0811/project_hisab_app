# Personal Money Tracker — App Specification

> Working name: *Daily Karobar* (undecided). "Hisab" = accounts; "karobar" = business/trade.
> Logo should include the initials **R** and **H**.

## 1. Concept

A personal money-tracking app that grew out of a monthly notes-app page ("Hisab october 2026"). It combines:

1. A **daily ledger** of income, expenses and profit.
2. **Per-person accounts** tracking money lent to and borrowed from each person.
3. A **dashboard** that gives a clear overall picture at a glance.

### Origin: the notes prototype

| Notes-app item | Meaning | App equivalent |
|---|---|---|
| Total starting money online | Opening balance in banks/wallets | Sum of bank + wallet accounts |
| Total money cash | Cash on hand | Cash account |
| Aauna baki paisa | Money others owe me | Total owed to me |
| Dina baki paisa | Money I owe others | Total owed by me |
| Hisab start (table) | Expense entries | Daily ledger |
| Total kharcha | Total spending | Day/week/month expense total |
| Total remaining | Online + cash − spending | Cash-in-hand |

---

## 2. Data Model

### Profiles
- **Personal** and **Business** (expandable later).
- Each profile holds its own accounts and ledger.

### Accounts (per profile)
| Type | Quantity | Examples |
|---|---|---|
| Bank accounts | Multiple | Several banks |
| Digital wallets | Multiple | eSewa, Khalti, etc. |
| Cash | One | Physical cash |

### People
- Each person has their own ledger.
- Transaction types: **lent to them**, **borrowed from them**, **repayment**.
- Running balance per person (positive = they owe me, negative = I owe them).

### Transactions
- Income, expense, profit entries.
- Fields: amount, category, note, account, profile, date (stored once, displayed in both BS and AD).

---

## 3. Global Requirements

- **Dual dates everywhere:** Bikram Sambat (BS) and AD shown side by side.
- **Language toggle:** Nepali / English (in Settings).
- **Light and dark mode.**
- **No hardcoded colors:** use theme-based color tokens; support custom colors or default system theme colors, adapting automatically to light/dark.
- **Bottom navigation:** Home · Daily Ledger · People Ledger · Settings.

---

## 4. Screens

### 4.1 Sign-in
- Email/password or Google sign-in.
- Enables cloud sync and backup across devices.
- Flow: Splash (logo) → Sign-in/Sign-up (if not signed in) → Home.

### 4.2 Home / Dashboard

```
┌─────────────────────────────────┐
│ October 2026 / Asoj 2083     ⚙  │
│ [ Personal ][ Business ][ Both ]│
├─────────────────────────────────┤
│ ┌───────────┐  ┌───────────┐    │
│ │ Cash in   │  │ Net worth │    │
│ │ hand      │  │           │    │
│ └───────────┘  └───────────┘    │
│ ┌───────────┐  ┌───────────┐    │
│ │ Owed TO   │  │ Owed BY   │    │
│ │ me        │  │ me        │    │
│ └───────────┘  └───────────┘    │
├─────────────────────────────────┤
│  ◄  [ Chart: bar/pie/line ]  ►  │
│            ● ○ ○                │
├─────────────────────────────────┤
│ [+ Expense] [+ Income] [+ Person]│
├─────────────────────────────────┤
│ Recently used features          │
├─────────────────────────────────┤
│ Recent activity                 │
│  • entry … amount … date        │
├─────────────────────────────────┤
│ Home | Ledger | People | Settings│
└─────────────────────────────────┘
```

**Header:** month in BS + AD; settings icon.

**Profile switch:** Personal / Business / Both. "Both" combines totals; selecting one filters the whole dashboard to that profile.

**Four summary cards**
| Card | Formula |
|---|---|
| Cash-in-hand | Bank + wallets + cash (no debts counted) |
| Net worth | Cash-in-hand + owed to me − owed by me |
| Owed TO me | Sum of balances others owe me |
| Owed BY me | Sum of balances I owe others |

The owed-to-me and owed-by-me totals are **kept separate**, never merged into one net figure.

**Chart carousel:** one section, one chart visible at a time. Swipe between bar, pie and line charts. Dot indicators show position. Keeps the screen compact.

**Quick actions:** Add Expense, Add Income, Add Person Entry.

**Recently used features:** fast access to what the user used last.

**Recent activity:** latest transactions with category/person, amount and date (BS + AD).

### 4.3 Daily Ledger
- Date selector (BS + AD) with Today / Week / Month filter.
- Day totals: income, expense, profit.
- Scrollable entry list: description, category, amount, color-coded income vs expense.
- Floating add button → quick entry form: amount, category, note, account, date (defaults to today, editable).

### 4.4 People / Lending Ledger
- Search bar to find a person.
- **Top summary:** total owed to me and total owed by me (same split as Home).
- People list: name, avatar/initials, balance (green = they owe me, red = I owe them; use theme tokens).
- **Person detail view:**
  - Large running balance.
  - Full transaction history (BS + AD dates; lent / borrowed / repaid).
  - Floating add button to log a new transaction with that person.
- Top-right button: add a new person.

### 4.5 Settings
- Language: Nepali / English.
- Theme: Light / Dark, plus custom color options.
- Profile and account management (banks, wallets, cash).
- Sign-out / account.

---

## 5. Suggested Tech Stack (suggestions, not fixed requirements)

| Layer | Suggestion | Why |
|---|---|---|
| Frontend | **Flutter (Dart)** | One codebase for Android + iOS; strong charting/animation; widget-based UI |
| Backend | **Firebase** (Auth + Firestore) | Login, database and sync with little setup |
| Alternative backend | Azure | More setup; useful as a later learning migration |

Notes:
- Need a BS↔AD date conversion library/table (BS calendar is not a simple offset).
- Use Flutter `ThemeData` (light + dark) and ARB/i18n files for Nepali/English.
- Use a charting package (e.g., fl_chart) inside a `PageView` for the swipeable carousel.

---

## 6. Suggested Build Order

1. Install Flutter SDK + VS Code Flutter extension; create Firebase project.
2. **Daily Ledger** first: add/list/save entries.
3. Accounts and profiles (bank, wallet, cash).
4. People Ledger with running balances.
5. Dashboard cards and chart carousel.
6. Settings: language, theme, BS/AD dates.
7. Sign-in and cloud sync polish.

---

## 7. Open Decisions

- Final app name (e.g., "Daily Karobar").
- Logo design with **R** and **H**.
- Whether to use Firebase or Azure for the backend.
