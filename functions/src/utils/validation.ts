import { AppError, ErrorCode } from "./errors";

export function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

export function validateString(
  value: unknown,
  fieldName: string,
  minLength: number = 0,
  maxLength: number = 255
): string {
  if (typeof value !== "string") {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      400,
      `${fieldName} must be a string`,
      { field: fieldName, value }
    );
  }

  if (value.length < minLength) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      400,
      `${fieldName} must be at least ${minLength} characters`,
      { field: fieldName, minLength }
    );
  }

  if (value.length > maxLength) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      400,
      `${fieldName} must not exceed ${maxLength} characters`,
      { field: fieldName, maxLength }
    );
  }

  return value;
}

export function validateNumber(
  value: unknown,
  fieldName: string,
  min?: number,
  max?: number
): number {
  if (typeof value !== "number") {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      400,
      `${fieldName} must be a number`,
      { field: fieldName, value }
    );
  }

  if (min !== undefined && value < min) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      400,
      `${fieldName} must be at least ${min}`,
      { field: fieldName, min }
    );
  }

  if (max !== undefined && value > max) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      400,
      `${fieldName} must not exceed ${max}`,
      { field: fieldName, max }
    );
  }

  return value;
}

export function validateObject(
  value: unknown,
  fieldName: string
): Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      400,
      `${fieldName} must be an object`,
      { field: fieldName, value }
    );
  }

  return value as Record<string, unknown>;
}

export function validateArray(
  value: unknown,
  fieldName: string
): unknown[] {
  if (!Array.isArray(value)) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      400,
      `${fieldName} must be an array`,
      { field: fieldName, value }
    );
  }

  return value;
}

export function validateEnum(
  value: unknown,
  fieldName: string,
  allowedValues: string[]
): string {
  const stringValue = validateString(value, fieldName);

  if (!allowedValues.includes(stringValue)) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      400,
      `${fieldName} must be one of: ${allowedValues.join(", ")}`,
      { field: fieldName, allowedValues, value: stringValue }
    );
  }

  return stringValue;
}

export function validateTimestamp(
  value: unknown,
  fieldName: string
): FirebaseFirestore.Timestamp {
  if (!(value instanceof FirebaseFirestore.Timestamp)) {
    throw new AppError(
      ErrorCode.VALIDATION_ERROR,
      400,
      `${fieldName} must be a valid timestamp`,
      { field: fieldName, value }
    );
  }

  return value;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type FirebaseFirestore = any;
