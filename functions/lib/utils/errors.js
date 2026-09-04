"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppError = exports.ErrorCode = void 0;
exports.createError = createError;
exports.handleError = handleError;
var ErrorCode;
(function (ErrorCode) {
    ErrorCode["INVALID_INPUT"] = "INVALID_INPUT";
    ErrorCode["UNAUTHORIZED"] = "UNAUTHORIZED";
    ErrorCode["FORBIDDEN"] = "FORBIDDEN";
    ErrorCode["NOT_FOUND"] = "NOT_FOUND";
    ErrorCode["CONFLICT"] = "CONFLICT";
    ErrorCode["INTERNAL_ERROR"] = "INTERNAL_ERROR";
    ErrorCode["AUTHENTICATION_ERROR"] = "AUTHENTICATION_ERROR";
    ErrorCode["VALIDATION_ERROR"] = "VALIDATION_ERROR";
    ErrorCode["PERMISSION_DENIED"] = "PERMISSION_DENIED";
})(ErrorCode || (exports.ErrorCode = ErrorCode = {}));
class AppError extends Error {
    constructor(code, statusCode, message, details) {
        super(message);
        this.code = code;
        this.statusCode = statusCode;
        this.details = details;
        this.name = "AppError";
    }
    toJSON() {
        return {
            code: this.code,
            message: this.message,
            details: this.details,
        };
    }
}
exports.AppError = AppError;
function createError(code, message, statusCode = 500, details) {
    return new AppError(code, statusCode, message, details);
}
function handleError(error) {
    if (error instanceof AppError) {
        return error;
    }
    if (error instanceof Error) {
        return new AppError(ErrorCode.INTERNAL_ERROR, 500, error.message);
    }
    return new AppError(ErrorCode.INTERNAL_ERROR, 500, "Unknown error occurred");
}
//# sourceMappingURL=errors.js.map