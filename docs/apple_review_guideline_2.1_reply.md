# Apple App Review — Reply to Guideline 2.1 (Information Needed)

Post this text (or a close paraphrase) both as a reply in the App Store Connect
Resolution Center thread AND in App Store Connect → App Review Information →
Notes field, per Apple's instructions. It's in English since that's what the
review team wrote in and reads fastest.

Before submitting, fill in the one bracketed placeholder ([SCREEN RECORDING
LINK]) once the recording is ready — see the recording checklist below.

---

## Text to submit

Thank you for the detailed request. Please find the requested information below.

**1. App description and purpose**

Kairos is a shared calendar app for small, trusted personal circles — couples,
families, and close friend groups — to coordinate schedules, tasks, and
anniversaries together. A user creates or joins a private group using a
one-time invite code shared out of band (e.g., in person or via messaging
outside the app); group membership is never public or discoverable inside the
app. Core features: shared calendar with per-schedule participants, shared
to-do lists, anniversary/birthday tracking, weather display, and an
optional group text chat for coordinating with the members of one's own
group. Target audience is general consumers of all ages; there is no
age-gated or mature content.

**2. Setup and access instructions, including demo account**

The app requires an account (email/password or Google Sign-In) to use any
feature — there is no guest mode, since all data is tied to a user's
calendar/groups.

Demo account for review:
- Email: kairos.screenshot@kairos-3d873.firebaseapp.com
- Password: (see secrets/screenshot_account_password.txt — deliberately not
  written in this git-tracked file; when copying this text to submit to
  Apple, replace this whole line with "Password: <the actual value>")

This account is pre-populated with sample schedules, tasks, an anniversary,
and a sample group, so the reviewer can see populated screens immediately
after logging in without needing to create data first. No special
configuration, region, or device setting is required.

**3. Screen recording**

https://drive.google.com/file/d/1_vS4uLQENuFynG6eysBQHNFtgfBtSNGn/view?usp=drivesdk

The recording shows, on a physical device, the complete flow requested:
account registration, login, the core calendar/task/group features, the
group chat (our only user-generated-content surface), and account deletion.

**4. External services / third-party tools used**

- Firebase Authentication (email/password sign-in and Google Sign-In)
- Cloud Firestore (all app data storage)
- Firebase Analytics (aggregate usage analytics, no ad tracking)
- Firebase Crashlytics (crash reporting)
- Firebase App Check (abuse prevention / bot traffic filtering)
- Open-Meteo (free, keyless public weather API — powers the in-app weather
  display)
- Google Gemini API (powers an optional in-app FAQ/support chat assistant in
  Settings; it only answers questions about how to use the app and does not
  access or transmit any user calendar data)

**5. Regional differences**

The app behaves identically worldwide with two exceptions: (a) it is
localized into Japanese, English, Korean, and Chinese, selected
automatically from the device's system language; (b) the weather display
uses region-appropriate location defaults for users in Japan/Korea/China/US,
but the feature itself is available everywhere. There are no other
functional, feature, or content differences by region, and no
region-specific account or age requirements.

**6. Regulated industries / protected materials**

Not applicable. Kairos is a general-purpose personal calendar/productivity
app. It does not involve health, financial, gambling, alcohol/tobacco, adult,
or other regulated content, and does not use any copyrighted/protected
third-party material.

Please let us know if any further detail is needed.

---

## Screen-recording checklist (for the user to actually capture)

Record on a real iPhone (Apple asked specifically for a physical device, not
the simulator), one continuous take if possible, showing in order:

1. **Sign up** — fresh email/password registration (use a throwaway address
   you control), through to landing on the calendar.
2. **Log out, then log back in** with that same account (or the demo
   account) to show the login flow works independently of signup.
3. **Core features**: open the calendar tab, create a schedule; open Tasks,
   create/complete a task; open the Anniversaries tab.
4. **Groups + chat (the UGC surface)**: create a group, show the invite
   code, send a couple of messages in the group chat, show a reaction on a
   message.
5. **Account deletion**: Settings → scroll to the red "Delete Account" item →
   tap it → show the confirmation dialog → confirm → show landing back on
   the login screen.

Keep it under ~3–5 minutes, upload it (YouTube unlisted, Google Drive with
link sharing on, or Apple's own attachment option in the Resolution Center).
The recording link is already filled in under item 3 above (confirm sharing
is set to "anyone with the link" before submitting).
