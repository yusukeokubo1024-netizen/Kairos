/** Place suggestions for the schedule form's location field, via Google
 * Places Autocomplete (New). Signed-in users only. Optionally biased toward
 * the user's area (their saved weather location). */
export declare const placesAutocomplete: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    suggestions: {
        placeId: string;
        main: string;
        secondary: string;
    }[];
}>, unknown>;
//# sourceMappingURL=placesAutocomplete.d.ts.map