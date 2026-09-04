export declare function validateEmail(email: string): boolean;
export declare function validateString(value: unknown, fieldName: string, minLength?: number, maxLength?: number): string;
export declare function validateNumber(value: unknown, fieldName: string, min?: number, max?: number): number;
export declare function validateObject(value: unknown, fieldName: string): Record<string, unknown>;
export declare function validateArray(value: unknown, fieldName: string): unknown[];
export declare function validateEnum(value: unknown, fieldName: string, allowedValues: string[]): string;
export declare function validateTimestamp(value: unknown, fieldName: string): FirebaseFirestore.Timestamp;
//# sourceMappingURL=validation.d.ts.map