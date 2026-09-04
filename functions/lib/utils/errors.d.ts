export declare enum ErrorCode {
    INVALID_INPUT = "INVALID_INPUT",
    UNAUTHORIZED = "UNAUTHORIZED",
    FORBIDDEN = "FORBIDDEN",
    NOT_FOUND = "NOT_FOUND",
    CONFLICT = "CONFLICT",
    INTERNAL_ERROR = "INTERNAL_ERROR",
    AUTHENTICATION_ERROR = "AUTHENTICATION_ERROR",
    VALIDATION_ERROR = "VALIDATION_ERROR",
    PERMISSION_DENIED = "PERMISSION_DENIED"
}
export declare class AppError extends Error {
    code: ErrorCode;
    statusCode: number;
    details?: Record<string, unknown> | undefined;
    constructor(code: ErrorCode, statusCode: number, message: string, details?: Record<string, unknown> | undefined);
    toJSON(): {
        code: ErrorCode;
        message: string;
        details: Record<string, unknown> | undefined;
    };
}
export declare function createError(code: ErrorCode, message: string, statusCode?: number, details?: Record<string, unknown>): AppError;
export declare function handleError(error: unknown): AppError;
//# sourceMappingURL=errors.d.ts.map