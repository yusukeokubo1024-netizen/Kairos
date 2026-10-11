"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.placesAutocomplete = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const logger = __importStar(require("firebase-functions/logger"));
/** Server-only Google Places API key (Secret Manager), restricted to the
 * Places API — never shipped inside the app. */
const placesApiKey = (0, params_1.defineSecret)("PLACES_API_KEY");
const LANGUAGES = new Set(["ja", "en", "ko", "zh"]);
/** Place suggestions for the schedule form's location field, via Google
 * Places Autocomplete (New). Signed-in users only. Optionally biased toward
 * the user's area (their saved weather location). */
exports.placesAutocomplete = (0, https_1.onCall)({ region: "asia-northeast1", secrets: [placesApiKey] }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Sign in required");
    const data = (request.data ?? {});
    const input = String(data.input ?? "").trim().slice(0, 100);
    if (input.length === 0)
        return { suggestions: [] };
    const language = LANGUAGES.has(String(data.language)) ? String(data.language) : "ja";
    const sessionToken = typeof data.sessionToken === "string" ? data.sessionToken.slice(0, 64) : undefined;
    const lat = typeof data.lat === "number" ? data.lat : undefined;
    const lng = typeof data.lng === "number" ? data.lng : undefined;
    const body = { input, languageCode: language };
    if (sessionToken)
        body.sessionToken = sessionToken;
    if (lat !== undefined && lng !== undefined) {
        body.locationBias = { circle: { center: { latitude: lat, longitude: lng }, radius: 50000 } };
    }
    const response = await fetch("https://places.googleapis.com/v1/places:autocomplete", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Goog-Api-Key": placesApiKey.value() },
        body: JSON.stringify(body),
    });
    if (!response.ok) {
        logger.warn(`placesAutocomplete: Places API ${response.status}`, await response.text());
        throw new https_1.HttpsError("unavailable", "Place search is unavailable");
    }
    const json = (await response.json());
    const suggestions = (json.suggestions ?? [])
        .map((s) => s.placePrediction)
        .filter((p) => p?.structuredFormat?.mainText?.text)
        .slice(0, 8)
        .map((p) => ({
        placeId: p.placeId ?? "",
        main: p.structuredFormat.mainText.text,
        secondary: p.structuredFormat?.secondaryText?.text ?? "",
    }));
    return { suggestions };
});
//# sourceMappingURL=placesAutocomplete.js.map