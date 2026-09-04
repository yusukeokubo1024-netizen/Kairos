# Purchase Verification Setup

## Product configuration

| Store | Application ID | Premium product ID | Family product ID |
| --- | --- | --- | --- |
| Google Play | `com.example.kairos` | `kairos_premium_monthly` | `kairos_family_monthly` |
| App Store | `com.example.kairos` | `kairos_premium_monthly` | `kairos_family_monthly` |

## Required production secrets

Never commit these values to source control or provide them through chat.

### Google Play

Create a Google Cloud service account with Google Play Android Developer API access, then store its JSON credential as a Firebase secret:

```powershell
firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
```

### App Store

Create an App Store Connect API key with In-App Purchase access. Store the issuer ID, key ID, and the contents of the `.p8` private key as Firebase secrets:

```powershell
firebase functions:secrets:set APP_STORE_ISSUER_ID
firebase functions:secrets:set APP_STORE_KEY_ID
firebase functions:secrets:set APP_STORE_PRIVATE_KEY
```

## Security requirement

The Cloud Function must verify a purchase token with the relevant store before changing a subscription document. It must not accept a client-supplied plan ID as proof of payment.