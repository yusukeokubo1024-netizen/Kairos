"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateEmail = validateEmail;
exports.validateString = validateString;
exports.validateNumber = validateNumber;
exports.validateObject = validateObject;
exports.validateArray = validateArray;
exports.validateEnum = validateEnum;
exports.validateTimestamp = validateTimestamp;
const errors_1 = require("./errors");
function validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}
function validateString(value, fieldName, minLength = 0, maxLength = 255) {
    if (typeof value !== "string") {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, 400, `${fieldName} must be a string`, { field: fieldName, value });
    }
    if (value.length < minLength) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, 400, `${fieldName} must be at least ${minLength} characters`, { field: fieldName, minLength });
    }
    if (value.length > maxLength) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, 400, `${fieldName} must not exceed ${maxLength} characters`, { field: fieldName, maxLength });
    }
    return value;
}
function validateNumber(value, fieldName, min, max) {
    if (typeof value !== "number") {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, 400, `${fieldName} must be a number`, { field: fieldName, value });
    }
    if (min !== undefined && value < min) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, 400, `${fieldName} must be at least ${min}`, { field: fieldName, min });
    }
    if (max !== undefined && value > max) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, 400, `${fieldName} must not exceed ${max}`, { field: fieldName, max });
    }
    return value;
}
function validateObject(value, fieldName) {
    if (typeof value !== "object" || value === null || Array.isArray(value)) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, 400, `${fieldName} must be an object`, { field: fieldName, value });
    }
    return value;
}
function validateArray(value, fieldName) {
    if (!Array.isArray(value)) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, 400, `${fieldName} must be an array`, { field: fieldName, value });
    }
    return value;
}
function validateEnum(value, fieldName, allowedValues) {
    const stringValue = validateString(value, fieldName);
    if (!allowedValues.includes(stringValue)) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, 400, `${fieldName} must be one of: ${allowedValues.join(", ")}`, { field: fieldName, allowedValues, value: stringValue });
    }
    return stringValue;
}
function validateTimestamp(value, fieldName) {
    if (!(value instanceof FirebaseFirestore.Timestamp)) {
        throw new errors_1.AppError(errors_1.ErrorCode.VALIDATION_ERROR, 400, `${fieldName} must be a valid timestamp`, { field: fieldName, value });
    }
    return value;
}
//# sourceMappingURL=validation.js.map